import { Construct } from 'constructs';
import { LambdaFunction } from '../.gen/providers/aws/lambda-function';
import { S3Bucket } from '../.gen/providers/aws/s3-bucket';

export class Backup extends Construct {
  public bucket: S3Bucket;
  public lambda: LambdaFunction;

  constructor(scope: Construct, id: string) {
    super(scope, id);

    this.bucket = new S3Bucket(this, 'backup-bucket', {
      bucket: 'prod-e-backups',
      tags: { Name: 'prod-e-backups' },
    });

    this.lambda = new LambdaFunction(this, 'backup-lambda', {
      functionName: 'prod-e-backup',
      runtime: 'nodejs14.x',
      handler: 'index.handler',
      s3Bucket: this.bucket.bucket,
      s3Key: 'backup.zip', // Placeholder - update with real zip
      role: 'arn:aws:iam::123456789012:role/lambda-exec-role', // Update with real ARN
      timeout: 300,
      tags: { Name: 'prod-e-backup-lambda' },
    });
  }
}
