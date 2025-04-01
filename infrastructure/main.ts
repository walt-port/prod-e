import * as dotenv from 'dotenv';
dotenv.config();

import { App, RemoteBackend, TerraformOutput, TerraformStack } from 'cdktf';
import { Construct } from 'constructs';
import { DataAwsCallerIdentity } from '../.gen/providers/aws/data-aws-caller-identity';
import { EcsService } from '../.gen/providers/aws/ecs-service';
import { AwsProvider } from '../.gen/providers/aws/provider';
import { Alb } from './alb';
import { Ecs } from './ecs';
import { Monitoring } from './monitoring';
import { Networking } from './networking';
import { Rds } from './rds';

function assertEnvVar(name: string): string {
  const value = process.env[name];
  if (!value) throw new Error(`${name} must be set in .env`);
  return value;
}

export class ProdEStack extends TerraformStack {
  constructor(scope: Construct, id: string) {
    super(scope, id);

    new RemoteBackend(this, {
      hostname: 'app.terraform.io',
      organization: assertEnvVar('TF_ORG'),
      workspaces: { name: assertEnvVar('TF_WORKSPACE') },
      token: assertEnvVar('TF_TOKEN'),
    });

    const awsRegion = assertEnvVar('AWS_REGION');
    const projectName = assertEnvVar('PROJECT_NAME');
    const backendDesiredCount = Number(assertEnvVar('BACKEND_DESIRED_COUNT'));
    const backendContainerName = assertEnvVar('BACKEND_CONTAINER_NAME');
    const backendPort = Number(assertEnvVar('BACKEND_PORT'));

    const awsProvider = new AwsProvider(this, 'aws', { region: awsRegion });
    new DataAwsCallerIdentity(this, 'current', { provider: awsProvider });

    const networking = new Networking(this, 'networking');

    const alb = new Alb(this, 'alb', networking);

    const ecs = new Ecs(this, 'ecs', networking, alb);

    const rds = new Rds(this, 'rds', networking);

    const monitoring = new Monitoring(this, 'monitoring', networking, alb, ecs);

    const backendService = new EcsService(this, 'backend-service', {
      name: `${projectName}-backend-service`,
      cluster: ecs.cluster.id,
      taskDefinition: ecs.backendTaskDefinition.arn,
      desiredCount: backendDesiredCount,
      launchType: 'FARGATE',
      networkConfiguration: {
        subnets: networking.privateSubnets.map(s => s.id),
        securityGroups: [ecs.securityGroup.id],
        assignPublicIp: false,
      },
      loadBalancer: [
        {
          targetGroupArn: alb.ecsTargetGroup.arn,
          containerName: backendContainerName,
          containerPort: backendPort,
        },
      ],
      forceNewDeployment: true,
      tags: { Name: `${projectName}-backend-service`, Project: projectName },
      dependsOn: [alb.alb, alb.ecsTargetGroup, alb.listener],
    });

    new TerraformOutput(this, 'alb_endpoint', { value: alb.alb.dnsName });
  }
}

if (require.main === module) {
  try {
    const projectName = assertEnvVar('PROJECT_NAME');

    const app = new App();
    new ProdEStack(app, projectName);
    app.synth();
  } catch (error) {
    console.error('Synthesis failed:', error);
    process.exit(1);
  }
}

export { Alb, Ecs, Monitoring, Networking, Rds };
