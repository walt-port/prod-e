import { Construct } from 'constructs';
import { IamRole } from '../.gen/providers/aws/iam-role';
import { IamRolePolicy } from '../.gen/providers/aws/iam-role-policy';
import { IamRolePolicyAttachment } from '../.gen/providers/aws/iam-role-policy-attachment';
import { LambdaFunction } from '../.gen/providers/aws/lambda-function';
import { S3Bucket } from '../.gen/providers/aws/s3-bucket';
import { ResourceExistenceOptions } from './main';

export class Backup extends Construct {
  public bucket: S3Bucket;
  public lambda: LambdaFunction;
  public backupRole: IamRole;
  private checkResourceExists: (serviceName: string, resourceName: string) => boolean;

  constructor(scope: Construct, id: string, options: ResourceExistenceOptions) {
    super(scope, id);

    this.checkResourceExists = options.checkResourceExists;

    // Create S3 bucket for backups if it doesn't exist
    const bucketExists = this.checkResourceExists('s3', 'prod-e-backups');

    if (!bucketExists) {
      this.bucket = new S3Bucket(this, 'backup-bucket', {
        bucket: 'prod-e-backups',
        tags: { Name: 'prod-e-backups', Project: 'prod-e' },
      });
    } else {
      // Reference existing bucket
      this.bucket = new S3Bucket(this, 'backup-bucket', {
        bucket: 'prod-e-backups',
        tags: { Name: 'prod-e-backups', Project: 'prod-e' },
      });
    }

    // Check if backup role exists
    const backupRoleExists = this.checkResourceExists('iam', 'grafana-backup-role');

    // Create Lambda execution role
    if (!backupRoleExists) {
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
        tags: { Name: 'grafana-backup-role', Project: 'prod-e' },
      });

      // Attach managed policies using IamRolePolicyAttachment
      new IamRolePolicyAttachment(this, 'lambda-basic-execution-policy', {
        role: this.backupRole.name,
        policyArn: 'arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole',
      });

      new IamRolePolicyAttachment(this, 'lambda-vpc-access-policy', {
        role: this.backupRole.name,
        policyArn: 'arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole',
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
    } else {
      // Reference existing role by ARN
      this.backupRole = new IamRole(this, 'grafana-backup-role', {
        name: 'grafana-backup-role',
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
      });
    }

    // Check if Lambda function exists
    const lambdaExists = this.checkResourceExists('lambda', 'prod-e-backup');

    // Using filename property instead of code object
    this.lambda = new LambdaFunction(this, 'backup-lambda', {
      functionName: 'prod-e-backup',
      runtime: 'nodejs18.x',
      handler: 'index.handler',
      role: this.backupRole.arn,
      timeout: 300,
      filename: 'dummy-backup.zip', // Changed from placeholder path to the actual file created in the workflow
      tags: { Name: 'prod-e-backup-lambda', Project: 'prod-e' },
    });
  }
}
