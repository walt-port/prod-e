import { Construct } from 'constructs';
import { DbInstance } from '../.gen/providers/aws/db-instance';
import { DbSubnetGroup } from '../.gen/providers/aws/db-subnet-group';
import { SecretsmanagerSecret } from '../.gen/providers/aws/secretsmanager-secret';
import { SecretsmanagerSecretVersion } from '../.gen/providers/aws/secretsmanager-secret-version';
import { SecurityGroup } from '../.gen/providers/aws/security-group';
import { SecurityGroupRule } from '../.gen/providers/aws/security-group-rule';
import { Networking } from './networking';

function assertEnvVar(name: string): string {
  const value = process.env[name];
  if (!value) throw new Error(`${name} must be set in .env`);
  return value;
}

export class Rds extends Construct {
  public dbSecurityGroup: SecurityGroup;
  public dbInstance: DbInstance;

  constructor(scope: Construct, id: string, networking: Networking) {
    super(scope, id);

    const projectName = assertEnvVar('PROJECT_NAME');
    const dbPort = Number(assertEnvVar('DB_PORT'));
    const dbAccessCidr = assertEnvVar('DB_ACCESS_CIDR');
    const dbEgressCidr = assertEnvVar('DB_EGRESS_CIDR');
    const dbSecretId = assertEnvVar('DB_SECRET_ID');
    const dbEngine = assertEnvVar('DB_ENGINE');
    const dbEngineVersion = assertEnvVar('DB_ENGINE_VERSION');
    const dbInstanceClass = assertEnvVar('DB_INSTANCE_CLASS');
    const dbStorage = Number(assertEnvVar('DB_STORAGE'));
    const dbName = assertEnvVar('DB_NAME');
    const dbUsername = assertEnvVar('DB_USERNAME');
    const dbPassword = assertEnvVar('DB_PASSWORD');
    const dbMultiAz = process.env.DB_MULTI_AZ === 'true';

    this.dbSecurityGroup = new SecurityGroup(this, 'db-security-group', {
      name: `${projectName}-db-sg`,
      description: 'Security group for RDS',
      vpcId: networking.vpc.id,
      tags: { Name: `${projectName}-db-sg`, Project: projectName },
    });

    new SecurityGroupRule(this, 'db-postgres-inbound', {
      type: 'ingress',
      fromPort: dbPort,
      toPort: dbPort,
      protocol: 'tcp',
      cidrBlocks: [dbAccessCidr],
      securityGroupId: this.dbSecurityGroup.id,
      description: 'Allow PostgreSQL traffic',
    });

    new SecurityGroupRule(this, 'db-all-outbound', {
      type: 'egress',
      fromPort: 0,
      toPort: 0,
      protocol: '-1',
      cidrBlocks: [dbEgressCidr],
      securityGroupId: this.dbSecurityGroup.id,
      description: 'Allow all outbound traffic',
    });

    const subnetGroup = new DbSubnetGroup(this, 'subnet-group', {
      name: `${projectName}-rds-subnet-group`,
      subnetIds: networking.privateSubnets.map(s => s.id),
      description: 'Subnet group for RDS',
      tags: { Name: `${projectName}-rds-subnet-group`, Project: projectName },
    });

    const dbSecret = new SecretsmanagerSecret(this, 'db-secret', {
      name: dbSecretId,
      tags: { Project: projectName },
    });

    this.dbInstance = new DbInstance(this, 'db', {
      identifier: `${projectName}-db`,
      engine: dbEngine,
      engineVersion: dbEngineVersion,
      instanceClass: dbInstanceClass,
      allocatedStorage: dbStorage,
      dbName: dbName,
      username: dbUsername,
      password: dbPassword,
      skipFinalSnapshot: true,
      multiAz: dbMultiAz,
      vpcSecurityGroupIds: [this.dbSecurityGroup.id],
      dbSubnetGroupName: subnetGroup.name,
      tags: { Name: `${projectName}-db`, Project: projectName },
    });

    const endpointString = this.dbInstance.endpoint;

    new SecretsmanagerSecretVersion(this, 'db-secret-version', {
      secretId: dbSecret.id,
      secretString: `{
        "username": "${dbUsername}",
        "password": "${dbPassword}",
        "host": "${endpointString.split(':')[0]}",
        "port": ${dbPort},
        "dbname": "${dbName}"
      }`,
      dependsOn: [this.dbInstance],
    });
  }
}
