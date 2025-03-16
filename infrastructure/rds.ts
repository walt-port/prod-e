import { Construct } from 'constructs';
import { DbInstance } from '../.gen/providers/aws/db-instance';
import { DbSubnetGroup } from '../.gen/providers/aws/db-subnet-group';
import { Networking } from './networking';

export class Rds extends Construct {
  public dbInstance: DbInstance;

  constructor(scope: Construct, id: string, networking: Networking) {
    super(scope, id);

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
      multiAz: true,
      skipFinalSnapshot: true,
      tags: { Name: 'prod-e-rds' },
    });
  }
}
