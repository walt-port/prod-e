import { Construct } from 'constructs';
import { EcsCluster } from '../.gen/providers/aws/ecs-cluster';
import { EcsService } from '../.gen/providers/aws/ecs-service';
import { EcsTaskDefinition } from '../.gen/providers/aws/ecs-task-definition';
import { IamRole } from '../.gen/providers/aws/iam-role';
import { IamRolePolicyAttachment } from '../.gen/providers/aws/iam-role-policy-attachment';
import { SecurityGroup } from '../.gen/providers/aws/security-group';
import { SecurityGroupRule } from '../.gen/providers/aws/security-group-rule';
import { Alb } from './alb';
import { Networking } from './networking';

function assertEnvVar(name: string): string {
  const value = process.env[name];
  if (!value) throw new Error(`${name} must be set in .env`);
  return value;
}

export class Ecs extends Construct {
  public cluster: EcsCluster;
  public service: EcsService;
  public securityGroup: SecurityGroup;
  public taskExecutionRole: IamRole;
  public taskRole: IamRole;
  public taskDefinition: EcsTaskDefinition;
  public backendTaskDefinition: EcsTaskDefinition;

  constructor(scope: Construct, id: string, networking: Networking, alb: Alb) {
    super(scope, id);

    const projectName = assertEnvVar('PROJECT_NAME');
    const backendPort = Number(assertEnvVar('BACKEND_PORT'));
    const grafanaCpu = assertEnvVar('GRAFANA_CPU');
    const grafanaMemory = assertEnvVar('GRAFANA_MEMORY');
    const grafanaContainerName = assertEnvVar('GRAFANA_CONTAINER_NAME');
    const grafanaTag = assertEnvVar('GRAFANA_TAG');
    const grafanaPort = Number(assertEnvVar('GRAFANA_PORT'));
    const grafanaRootUrl = assertEnvVar('GRAFANA_ROOT_URL');
    const grafanaAdminUser = assertEnvVar('GRAFANA_ADMIN_USER');
    const grafanaAllowSignup = assertEnvVar('GRAFANA_ALLOW_SIGNUP');
    const grafanaDesiredCount = Number(assertEnvVar('GRAFANA_DESIRED_COUNT'));
    const backendCpu = assertEnvVar('BACKEND_CPU');
    const backendMemory = assertEnvVar('BACKEND_MEMORY');
    const backendContainerName = assertEnvVar('BACKEND_CONTAINER_NAME');
    const backendTag = assertEnvVar('BACKEND_TAG');
    const nodeEnv = assertEnvVar('NODE_ENV');
    const dbSecretId = assertEnvVar('DB_SECRET_ID');
    const awsRegion = assertEnvVar('AWS_REGION');
    const awsAccountId = assertEnvVar('AWS_ACCOUNT_ID');
    const ecsEgressCidr = assertEnvVar('ECS_EGRESS_CIDR');

    this.cluster = new EcsCluster(this, 'cluster', {
      name: `${projectName}-cluster`,
      tags: { Name: `${projectName}-cluster`, Project: projectName },
    });

    this.securityGroup = new SecurityGroup(this, 'ecs-security-group', {
      name: `${projectName}-ecs-sg`,
      description: 'Security group for ECS tasks',
      vpcId: networking.vpc.id,
      tags: { Name: `${projectName}-ecs-sg`, Project: projectName },
    });

    new SecurityGroupRule(this, 'ecs-http-inbound', {
      type: 'ingress',
      fromPort: backendPort,
      toPort: backendPort,
      protocol: 'tcp',
      sourceSecurityGroupId: networking.albSecurityGroup.id,
      securityGroupId: this.securityGroup.id,
      description: 'Allow traffic from ALB',
    });

    new SecurityGroupRule(this, 'ecs-all-outbound', {
      type: 'egress',
      fromPort: 0,
      toPort: 0,
      protocol: '-1',
      cidrBlocks: [ecsEgressCidr],
      securityGroupId: this.securityGroup.id,
      description: 'Allow all outbound traffic',
    });

    this.taskExecutionRole = new IamRole(this, 'ecs-task-execution-role', {
      name: `${projectName}-ecs-task-execution-role`,
      assumeRolePolicy: JSON.stringify({
        Version: '2012-10-17',
        Statement: [
          {
            Effect: 'Allow',
            Principal: { Service: 'ecs-tasks.amazonaws.com' },
            Action: 'sts:AssumeRole',
          },
        ],
      }),
      tags: { Name: `${projectName}-ecs-task-execution-role`, Project: projectName },
    });

    new IamRolePolicyAttachment(this, 'ecs-task-execution-policy', {
      role: this.taskExecutionRole.name,
      policyArn: 'arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy',
    });

    new IamRolePolicyAttachment(this, 'ecs-task-logs-policy', {
      role: this.taskExecutionRole.name,
      policyArn: 'arn:aws:iam::aws:policy/CloudWatchLogsFullAccess',
    });

    new IamRolePolicyAttachment(this, 'ecs-task-secrets-policy', {
      role: this.taskExecutionRole.name,
      policyArn: 'arn:aws:iam::aws:policy/SecretsManagerReadWrite',
    });

    this.taskRole = new IamRole(this, 'ecs-task-role', {
      name: `${projectName}-ecs-task-role`,
      assumeRolePolicy: JSON.stringify({
        Version: '2012-10-17',
        Statement: [
          {
            Effect: 'Allow',
            Principal: { Service: 'ecs-tasks.amazonaws.com' },
            Action: 'sts:AssumeRole',
          },
        ],
      }),
      tags: { Name: `${projectName}-ecs-task-role`, Project: projectName },
    });

    new IamRolePolicyAttachment(this, 'ecs-task-role-secrets-policy', {
      // Renamed here
      role: this.taskRole.name,
      policyArn: 'arn:aws:iam::aws:policy/SecretsManagerReadWrite',
    });

    this.taskDefinition = new EcsTaskDefinition(this, 'grafana-task-definition', {
      family: `${projectName}-grafana-task`,
      requiresCompatibilities: ['FARGATE'],
      networkMode: 'awsvpc',
      cpu: grafanaCpu,
      memory: grafanaMemory,
      executionRoleArn: this.taskExecutionRole.arn,
      taskRoleArn: this.taskRole.arn,
      containerDefinitions: JSON.stringify([
        {
          name: grafanaContainerName,
          image: `${awsAccountId}.dkr.ecr.${awsRegion}.amazonaws.com/${projectName}-grafana:${grafanaTag}`,
          essential: true,
          portMappings: [
            {
              containerPort: grafanaPort,
              hostPort: grafanaPort,
              protocol: 'tcp',
            },
          ],
          environment: [
            { name: 'GF_SERVER_ROOT_URL', value: grafanaRootUrl },
            { name: 'GF_SERVER_SERVE_FROM_SUB_PATH', value: 'true' },
            { name: 'GF_SECURITY_ADMIN_USER', value: grafanaAdminUser },
            { name: 'GF_USERS_ALLOW_SIGN_UP', value: grafanaAllowSignup },
          ],
          logConfiguration: {
            logDriver: 'awslogs',
            options: {
              'awslogs-group': `/ecs/${projectName}-grafana-task`,
              'awslogs-region': awsRegion,
              'awslogs-stream-prefix': 'ecs',
              'awslogs-create-group': 'true',
            },
          },
        },
      ]),
      tags: { Name: `${projectName}-grafana-task-def`, Project: projectName },
    });

    this.backendTaskDefinition = new EcsTaskDefinition(this, 'backend-task-definition', {
      family: `${projectName}-task`,
      requiresCompatibilities: ['FARGATE'],
      networkMode: 'awsvpc',
      cpu: backendCpu,
      memory: backendMemory,
      executionRoleArn: this.taskExecutionRole.arn,
      taskRoleArn: this.taskRole.arn,
      containerDefinitions: JSON.stringify([
        {
          name: backendContainerName,
          image: `${awsAccountId}.dkr.ecr.${awsRegion}.amazonaws.com/${projectName}-backend:${backendTag}`,
          essential: true,
          portMappings: [
            {
              containerPort: backendPort,
              hostPort: backendPort,
              protocol: 'tcp',
            },
          ],
          environment: [
            { name: 'NODE_ENV', value: nodeEnv },
            { name: 'AWS_REGION', value: awsRegion },
            { name: 'DB_CREDENTIALS_SECRET_NAME', value: dbSecretId },
          ],
          secrets: [
            {
              name: 'DB_HOST',
              valueFrom: `arn:aws:secretsmanager:${awsRegion}:${awsAccountId}:secret:${dbSecretId}:host::`,
            },
            {
              name: 'DB_PORT',
              valueFrom: `arn:aws:secretsmanager:${awsRegion}:${awsAccountId}:secret:${dbSecretId}:port::`,
            },
            {
              name: 'DB_NAME',
              valueFrom: `arn:aws:secretsmanager:${awsRegion}:${awsAccountId}:secret:${dbSecretId}:dbname::`,
            },
            {
              name: 'DB_USER',
              valueFrom: `arn:aws:secretsmanager:${awsRegion}:${awsAccountId}:secret:${dbSecretId}:username::`,
            },
            {
              name: 'DB_PASSWORD',
              valueFrom: `arn:aws:secretsmanager:${awsRegion}:${awsAccountId}:secret:${dbSecretId}:password::`,
            },
          ],
          logConfiguration: {
            logDriver: 'awslogs',
            options: {
              'awslogs-group': `/ecs/${projectName}-task`,
              'awslogs-region': awsRegion,
              'awslogs-stream-prefix': 'ecs',
              'awslogs-create-group': 'true',
            },
          },
          healthCheck: {
            command: [
              'CMD-SHELL',
              `curl -f http://localhost:${backendPort}${assertEnvVar(
                'BACKEND_HEALTH_PATH'
              )} || exit 1`,
            ],
            interval: 30,
            timeout: 5,
            retries: 3,
            startPeriod: 60,
          },
        },
      ]),
      tags: { Name: `${projectName}-task-def`, Project: projectName },
    });

    this.service = new EcsService(this, 'grafana-service', {
      name: `${projectName}-grafana-service`,
      cluster: this.cluster.id,
      taskDefinition: this.taskDefinition.arn,
      desiredCount: grafanaDesiredCount,
      launchType: 'FARGATE',
      networkConfiguration: {
        subnets: networking.privateSubnets.map(s => s.id),
        securityGroups: [this.securityGroup.id],
        assignPublicIp: false,
      },
      loadBalancer: [
        {
          targetGroupArn: alb.grafanaTargetGroup.arn,
          containerName: grafanaContainerName,
          containerPort: grafanaPort,
        },
      ],
      forceNewDeployment: true,
      tags: { Name: `${projectName}-grafana-service`, Project: projectName },
    });
  }
}
