import { Construct } from 'constructs';
import { LambdaFunction } from '../.gen/providers/aws/lambda-function';
import { S3Bucket } from '../.gen/providers/aws/s3-bucket';
import { IamRole } from '../.gen/providers/aws/iam-role';
import { IamRolePolicy } from '../.gen/providers/aws/iam-role-policy';

export class Backup extends Construct {
  public bucket: S3Bucket;
  public lambda: LambdaFunction;
  public backupRole: IamRole;

  constructor(scope: Construct, id: string) {
    super(scope, id);

    this.bucket = new S3Bucket(this, 'backup-bucket', {
      bucket: 'prod-e-backups',
      tags: { Name: 'prod-e-backups' },
    });

    // Create Lambda execution role
    this.backupRole = new IamRole(this, 'grafana-backup-role', {
      assumeRolePolicy: JSON.stringify({
        Version: '2012-10-17',
        Statement: [
          {
            Effect: 'Allow',
            Principal: { Service: 'lambda.amazonaws.com' },
            Action: 'sts:AssumeRole',
          },
        ],
      }),
      managedPolicyArns: [
        'arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole',
        'arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole',
      ],
      tags: { Name: 'grafana-backup-role' },
    });

    // Create policy for S3 access
    new IamRolePolicy(this, 'grafana-backup-policy', {
      role: this.backupRole.id,
      policy: JSON.stringify({
        Version: '2012-10-17',
        Statement: [
          { Effect: 'Allow', Action: ['s3:PutObject'], Resource: `${this.bucket.arn}/*` },
          {
            Effect: 'Allow',
            Action: ['elasticfilesystem:ClientMount', 'elasticfilesystem:ClientWrite'],
            Resource: '*', // We should narrow this in production
          },
        ],
      }),
    });

    this.lambda = new LambdaFunction(this, 'backup-lambda', {
      functionName: 'prod-e-backup',
      runtime: 'nodejs14.x',
      handler: 'index.handler',
      s3Bucket: this.bucket.bucket,
      s3Key: 'backup.zip', // Placeholder - update with real zip
      role: this.backupRole.arn,
      timeout: 300,
      tags: { Name: 'prod-e-backup-lambda' },
    });
  }
}
