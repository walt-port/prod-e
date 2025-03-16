import { App, TerraformStack } from 'cdktf';
import { Construct } from 'constructs';
import { DynamodbTable } from './.gen/providers/aws/dynamodb-table';
import { AwsProvider } from './.gen/providers/aws/provider';
import { S3Bucket } from './.gen/providers/aws/s3-bucket';

class StateSetup extends TerraformStack {
  constructor(scope: Construct, id: string) {
    super(scope, id);

    // Configure AWS provider
    new AwsProvider(this, 'aws', {
      region: 'us-west-2',
    });

    new S3Bucket(this, 'state-bucket', {
      bucket: 'prod-e-tfstate',
      versioning: { enabled: true },
      tags: { Name: 'prod-e-tfstate' },
    });

    new DynamodbTable(this, 'state-lock', {
      name: 'prod-e-tfstate-lock',
      billingMode: 'PAY_PER_REQUEST',
      hashKey: 'LockID',
      attribute: [{ name: 'LockID', type: 'S' }],
      tags: { Name: 'prod-e-tfstate-lock' },
    });
  }
}

const app = new App();
new StateSetup(app, 'state-setup');
app.synth();
