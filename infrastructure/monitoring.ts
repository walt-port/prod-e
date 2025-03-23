import { Construct } from 'constructs';
import { EcsService } from '../.gen/providers/aws/ecs-service';
import { EcsTaskDefinition } from '../.gen/providers/aws/ecs-task-definition';
import { SecurityGroup } from '../.gen/providers/aws/security-group';
import { SecurityGroupRule } from '../.gen/providers/aws/security-group-rule';
import { Alb } from './alb';
import { Ecs } from './ecs';
import { Networking } from './networking';

function assertEnvVar(name: string): string {
  const value = process.env[name];
  if (!value) throw new Error(`${name} must be set in .env`);
  return value;
}

export class Monitoring extends Construct {
  public prometheusService: EcsService;
  public promSecurityGroup: SecurityGroup;
  public prometheusTaskDefinition: EcsTaskDefinition;

  constructor(scope: Construct, id: string, networking: Networking, alb: Alb, ecs: Ecs) {
    super(scope, id);

    const projectName = assertEnvVar('PROJECT_NAME');
    const prometheusCpu = assertEnvVar('PROMETHEUS_CPU');
    const prometheusMemory = assertEnvVar('PROMETHEUS_MEMORY');
    const prometheusContainerName = assertEnvVar('PROMETHEUS_CONTAINER_NAME');
    const prometheusTag = assertEnvVar('PROMETHEUS_TAG');
    const prometheusPort = Number(assertEnvVar('PROMETHEUS_PORT'));
    const prometheusDesiredCount = Number(assertEnvVar('PROMETHEUS_DESIRED_COUNT'));
    const awsRegion = assertEnvVar('AWS_REGION');
    const awsAccountId = assertEnvVar('AWS_ACCOUNT_ID');
    const prometheusEgressCidr = assertEnvVar('PROMETHEUS_EGRESS_CIDR');

    this.promSecurityGroup = new SecurityGroup(this, 'prom-security-group', {
      name: `${projectName}-prom-sg`,
      vpcId: networking.vpc.id,
      tags: { Name: `${projectName}-prom-sg`, Project: projectName },
    });

    new SecurityGroupRule(this, 'prom-inbound', {
      type: 'ingress',
      fromPort: prometheusPort,
      toPort: prometheusPort,
      protocol: 'tcp',
      sourceSecurityGroupId: networking.albSecurityGroup.id,
      securityGroupId: this.promSecurityGroup.id,
      description: 'Allow traffic from ALB',
    });

    new SecurityGroupRule(this, 'prom-outbound', {
      type: 'egress',
      fromPort: 0,
      toPort: 0,
      protocol: '-1',
      cidrBlocks: [prometheusEgressCidr],
      securityGroupId: this.promSecurityGroup.id,
      description: 'Allow all outbound traffic',
    });

    this.prometheusTaskDefinition = new EcsTaskDefinition(this, 'prom-task-definition', {
      family: `${projectName}-prom-task`,
      requiresCompatibilities: ['FARGATE'],
      networkMode: 'awsvpc',
      cpu: prometheusCpu,
      memory: prometheusMemory,
      executionRoleArn: ecs.taskExecutionRole.arn,
      taskRoleArn: ecs.taskRole.arn,
      containerDefinitions: JSON.stringify([{
        name: prometheusContainerName,
        image: `${awsAccountId}.dkr.ecr.${awsRegion}.amazonaws.com/${projectName}-prometheus:${prometheusTag}`,
        essential: true,
        portMappings: [{ containerPort: prometheusPort, hostPort: prometheusPort, protocol: 'tcp' }],
        environment: [
          { name: 'BACKEND_ALB_HOST', value: assertEnvVar('BACKEND_ALB_HOST') },
        ],
        command: [
          '/bin/prometheus',
          '--config.file=/etc/prometheus/prometheus.yml',
          '--web.external-url=/metrics',
          '--web.route-prefix=/'
        ],
        logConfiguration: {
          logDriver: 'awslogs',
          options: {
            'awslogs-group': `/ecs/${projectName}-prom-task`,
            'awslogs-region': awsRegion,
            'awslogs-stream-prefix': 'ecs',
            'awslogs-create-group': 'true',
          },
        },
      }]),
      tags: { Name: `${projectName}-prom-task-def`, Project: projectName },
    });

    this.prometheusService = new EcsService(this, 'prometheus-service', {
      name: `${projectName}-prometheus-service`,
      cluster: ecs.cluster.id,
      taskDefinition: this.prometheusTaskDefinition.arn,
      desiredCount: prometheusDesiredCount,
      launchType: 'FARGATE',
      networkConfiguration: {
        subnets: networking.privateSubnets.map(s => s.id),
        securityGroups: [this.promSecurityGroup.id],
        assignPublicIp: false,
      },
      loadBalancer: [
        {
          targetGroupArn: alb.prometheusTargetGroup.arn,
          containerName: prometheusContainerName,
          containerPort: prometheusPort,
        },
      ],
      tags: { Name: `${projectName}-prometheus-service`, Project: projectName },
    });
  }
}
