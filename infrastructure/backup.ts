import { Construct } from 'constructs';
import { IamRole } from '../.gen/providers/aws/iam-role';
import { IamRolePolicy } from '../.gen/providers/aws/iam-role-policy';
import { IamRolePolicyAttachment } from '../.gen/providers/aws/iam-role-policy-attachment';
import { LambdaFunction } from '../.gen/providers/aws/lambda-function';
import { S3Bucket } from '../.gen/providers/aws/s3-bucket';

function assertEnvVar(name: string): string {
  const value = process.env[name];
  if (!value) throw new Error(`${name} must be set in .env`);
  return value;
}

export class Backup extends Construct {
  public bucket: S3Bucket;
  public lambda: LambdaFunction;
  public backupRole: IamRole;

  constructor(scope: Construct, id: string) {
    super(scope, id);

    const projectName = assertEnvVar('PROJECT_NAME');
    const lambdaRuntime = assertEnvVar('LAMBDA_RUNTIME');
    const lambdaHandler = assertEnvVar('LAMBDA_HANDLER');
    const lambdaTimeout = Number(assertEnvVar('LAMBDA_TIMEOUT'));
    const lambdaCodePath = assertEnvVar('LAMBDA_CODE_PATH');

    this.bucket = new S3Bucket(this, 'backup-bucket', {
      bucket: `${projectName}-backups`,
      tags: { Name: `${projectName}-backups`, Project: projectName },
    });

    this.backupRole = new IamRole(this, 'backup-role', {
      name: `${projectName}-backup-role`,
      assumeRolePolicy: JSON.stringify({
        Version: '2012-10-17',
        Statement: [{ Effect: 'Allow', Principal: { Service: 'lambda.amazonaws.com' }, Action: 'sts:AssumeRole' }],
      }),
      tags: { Name: `${projectName}-backup-role`, Project: projectName },
    });

    new IamRolePolicyAttachment(this, 'lambda-basic-execution', {
      role: this.backupRole.name,
      policyArn: 'arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole',
    });

    new IamRolePolicy(this, 'backup-policy', {
      role: this.backupRole.id,
      policy: JSON.stringify({
        Version: '2012-10-17',
        Statement: [
          { Effect: 'Allow', Action: ['s3:PutObject'], Resource: `${this.bucket.arn}/*` },
          { Effect: 'Allow', Action: ['elasticfilesystem:ClientMount', 'elasticfilesystem:ClientWrite'], Resource: '*' },
        ],
      }),
    });

    this.lambda = new LambdaFunction(this, 'backup-lambda', {
      functionName: `${projectName}-backup`,
      runtime: lambdaRuntime,
      handler: lambdaHandler,
      role: this.backupRole.arn,
      timeout: lambdaTimeout,
      filename: lambdaCodePath,
      tags: { Name: `${projectName}-backup-lambda`, Project: projectName },
    });
  }
}
