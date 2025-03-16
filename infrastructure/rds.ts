import { Construct } from 'constructs';
import { DbInstance } from '../.gen/providers/aws/db-instance';
import { DbSubnetGroup } from '../.gen/providers/aws/db-subnet-group';
import { SecurityGroup } from '../.gen/providers/aws/security-group';
import { SecurityGroupRule } from '../.gen/providers/aws/security-group-rule';
import { Networking } from './networking';

export class Rds extends Construct {
  public dbInstance: DbInstance;
  public dbSecurityGroup: SecurityGroup;

  constructor(scope: Construct, id: string, networking: Networking) {
    super(scope, id);

    // Create a security group for the RDS instance
    this.dbSecurityGroup = new SecurityGroup(this, 'db-security-group', {
      name: 'db-security-group',
      description: 'Security group for the RDS PostgreSQL instance',
      vpcId: networking.vpc.id,
      tags: {
        Name: 'db-sg',
      },
    });

    // Add inbound rule to allow PostgreSQL traffic (port 5432)
    new SecurityGroupRule(this, 'db-postgres-inbound', {
      type: 'ingress',
      fromPort: 5432,
      toPort: 5432,
      protocol: 'tcp',
      cidrBlocks: ['0.0.0.0/0'], // In production, restrict this to your VPC CIDR
      securityGroupId: this.dbSecurityGroup.id,
      description: 'Allow PostgreSQL traffic',
    });

    // Add outbound rule to allow all traffic
    new SecurityGroupRule(this, 'db-all-outbound', {
      type: 'egress',
      fromPort: 0,
      toPort: 0,
      protocol: '-1', // All protocols
      cidrBlocks: ['0.0.0.0/0'], // Allow traffic to anywhere
      securityGroupId: this.dbSecurityGroup.id,
      description: 'Allow all outbound traffic',
    });

    const subnetGroup = new DbSubnetGroup(this, 'subnet-group', {
      name: 'prod-e-rds-subnet-group',
      subnetIds: networking.privateSubnets.map(s => s.id),
      tags: { Name: 'prod-e-rds-subnet-group' },
    });

    this.dbInstance = new DbInstance(this, 'db', {
      identifier: 'prod-e-db',
      engine: 'postgres',
      engineVersion: '14.17',
      instanceClass: 'db.t3.micro',
      allocatedStorage: 20,
      username: 'prodadmin',
      password: 'supersecretpassword', // Replace with secrets management
      dbSubnetGroupName: subnetGroup.name,
      vpcSecurityGroupIds: [this.dbSecurityGroup.id],
      multiAz: true,
      skipFinalSnapshot: true,
      tags: { Name: 'prod-e-rds' },
    });
  }
}
