import { Construct } from 'constructs';
import { DbInstance } from '../.gen/providers/aws/db-instance';
import { DbSubnetGroup } from '../.gen/providers/aws/db-subnet-group';
import { SecurityGroup } from '../.gen/providers/aws/security-group';
import { SecurityGroupRule } from '../.gen/providers/aws/security-group-rule';
import { Networking } from './networking';

export class Rds extends Construct {
  public dbSecurityGroup: SecurityGroup;
  public dbInstance: DbInstance;

  constructor(scope: Construct, id: string, networking: Networking) {
    super(scope, id);

    // Create security group for database
    this.dbSecurityGroup = new SecurityGroup(this, 'db-security-group', {
      name: 'db-security-group',
      description: 'Security group for the RDS PostgreSQL instance',
      vpcId: networking.vpc.id,
      tags: { Name: 'db-sg' },
    });

    // Add ingress rule for PostgreSQL
    new SecurityGroupRule(this, 'db-postgres-inbound', {
      type: 'ingress',
      fromPort: 5432,
      toPort: 5432,
      protocol: 'tcp',
      cidrBlocks: ['0.0.0.0/0'], // Note: In production, you'd restrict this
      securityGroupId: this.dbSecurityGroup.id,
      description: 'Allow PostgreSQL traffic',
    });

    // Add egress rule to allow all outbound traffic
    new SecurityGroupRule(this, 'db-all-outbound', {
      type: 'egress',
      fromPort: 0,
      toPort: 0,
      protocol: '-1', // All protocols
      cidrBlocks: ['0.0.0.0/0'],
      securityGroupId: this.dbSecurityGroup.id,
      description: 'Allow all outbound traffic',
    });

    // Create a new subnet group in our current VPC
    const newSubnetGroup = new DbSubnetGroup(this, 'new-subnet-group', {
      name: 'prod-e-rds-subnet-group-new',
      subnetIds: networking.privateSubnets.map(s => s.id),
      description: 'Subnet group for RDS in our new VPC',
      tags: { Name: 'prod-e-rds-subnet-group-new' },
    });

    // Use our newly created subnet group
    this.dbInstance = new DbInstance(this, 'prod-e-db', {
      identifier: 'prod-e-db',
      engine: 'postgres',
      engineVersion: '14.17',
      instanceClass: 'db.t3.micro', // Use a small instance for demo
      allocatedStorage: 20,
      dbName: 'prode',
      username: 'postgres',
      password: 'temporaryPassword123!', // In production, use SSM/Secrets Manager
      skipFinalSnapshot: true, // For demo purposes
      multiAz: false, // For demo, single AZ is enough
      vpcSecurityGroupIds: [this.dbSecurityGroup.id],
      dbSubnetGroupName: newSubnetGroup.name,
      tags: { Name: 'prod-e-db' },
    });
  }
}
