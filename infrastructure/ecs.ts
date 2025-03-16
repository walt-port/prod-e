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

export class Ecs extends Construct {
  public cluster: EcsCluster;
  public service: EcsService;
  public securityGroup: SecurityGroup;
  public taskExecutionRole: IamRole;
  public taskRole: IamRole;
  public taskDefinition: EcsTaskDefinition;

  constructor(scope: Construct, id: string, networking: Networking, alb: Alb) {
    super(scope, id);

    this.cluster = new EcsCluster(this, 'cluster', {
      name: 'prod-e-cluster',
      tags: {
        Name: 'ecs-cluster',
        ManagedBy: 'CDKTF',
        Project: 'prod-e',
      },
    });

    // Security group for ECS tasks
    this.securityGroup = new SecurityGroup(this, 'ecs-security-group', {
      name: 'ecs-security-group',
      description: 'Security group for ECS Fargate tasks',
      vpcId: networking.vpc.id,
      tags: { Name: 'ecs-sg' },
    });

    // Add inbound rule to allow traffic from ALB
    new SecurityGroupRule(this, 'ecs-http-inbound', {
      type: 'ingress',
      fromPort: 3000,
      toPort: 3000,
      protocol: 'tcp',
      sourceSecurityGroupId: networking.albSecurityGroup.id, // Allow traffic from ALB
      securityGroupId: this.securityGroup.id,
      description: 'Allow HTTP traffic from ALB',
    });

    // Add outbound rule to allow all traffic
    new SecurityGroupRule(this, 'ecs-all-outbound', {
      type: 'egress',
      fromPort: 0,
      toPort: 0,
      protocol: '-1', // All protocols
      cidrBlocks: ['0.0.0.0/0'], // Allow traffic to anywhere
      securityGroupId: this.securityGroup.id,
      description: 'Allow all outbound traffic',
    });

    // IAM execution role for ECS tasks
    this.taskExecutionRole = new IamRole(this, 'ecs-task-execution-role', {
      name: 'ecs-task-execution-role',
      assumeRolePolicy: JSON.stringify({
        Version: '2012-10-17',
        Statement: [
          {
            Effect: 'Allow',
            Principal: {
              Service: 'ecs-tasks.amazonaws.com',
            },
            Action: 'sts:AssumeRole',
          },
        ],
      }),
      tags: {
        Name: 'ecs-execution-role',
      },
    });

    // Attach the Amazon ECS Task Execution Role policy to the ECS execution role
    new IamRolePolicyAttachment(this, 'ecs-task-execution-role-policy', {
      role: this.taskExecutionRole.name,
      policyArn: 'arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy',
    });

    // Add CloudWatch Logs permissions
    new IamRolePolicyAttachment(this, 'ecs-task-execution-cloudwatch-logs-policy', {
      role: this.taskExecutionRole.name,
      policyArn: 'arn:aws:iam::aws:policy/CloudWatchLogsFullAccess',
    });

    // Add SecretsManager access policy
    new IamRolePolicyAttachment(this, 'ecs-task-execution-secretsmanager-policy', {
      role: this.taskExecutionRole.name,
      policyArn: 'arn:aws:iam::aws:policy/SecretsManagerReadWrite',
    });

    // Create IAM task role for ECS tasks
    this.taskRole = new IamRole(this, 'ecs-task-role', {
      name: 'ecs-task-role',
      assumeRolePolicy: JSON.stringify({
        Version: '2012-10-17',
        Statement: [
          {
            Effect: 'Allow',
            Principal: {
              Service: 'ecs-tasks.amazonaws.com',
            },
            Action: 'sts:AssumeRole',
          },
        ],
      }),
      tags: {
        Name: 'ecs-task-role',
      },
    });

    // Task definition for Grafana
    this.taskDefinition = new EcsTaskDefinition(this, 'grafana-task-definition', {
      family: 'grafana-task',
      requiresCompatibilities: ['FARGATE'],
      networkMode: 'awsvpc',
      cpu: '256',
      memory: '512',
      executionRoleArn: this.taskExecutionRole.arn,
      taskRoleArn: this.taskRole.arn,
      containerDefinitions: JSON.stringify([
        {
          name: 'grafana',
          image: '043309339649.dkr.ecr.us-west-2.amazonaws.com/prod-e-grafana:latest',
          essential: true,
          portMappings: [
            {
              containerPort: 3000,
              hostPort: 3000,
              protocol: 'tcp',
            },
          ],
          environment: [
            {
              name: 'GF_SERVER_ROOT_URL',
              value: 'http://application-load-balancer.us-west-2.elb.amazonaws.com/grafana',
            },
            { name: 'GF_SERVER_SERVE_FROM_SUB_PATH', value: 'true' },
            { name: 'GF_SECURITY_ADMIN_USER', value: 'admin' },
            { name: 'GF_USERS_ALLOW_SIGN_UP', value: 'false' },
          ],
          logConfiguration: {
            logDriver: 'awslogs',
            options: {
              'awslogs-group': '/ecs/grafana-task',
              'awslogs-region': 'us-west-2',
              'awslogs-stream-prefix': 'ecs',
              'awslogs-create-group': 'true',
            },
          },
        },
      ]),
      tags: { Name: 'grafana-task-def' },
    });

    this.service = new EcsService(this, 'grafana-service', {
      name: 'grafana-service',
      cluster: this.cluster.id,
      taskDefinition: this.taskDefinition.arn,
      desiredCount: 1,
      launchType: 'FARGATE',
      networkConfiguration: {
        subnets: networking.privateSubnets.map(s => s.id),
        securityGroups: [this.securityGroup.id],
        assignPublicIp: false,
      },
      loadBalancer: [
        {
          targetGroupArn: alb.grafanaTargetGroup.arn,
          containerName: 'grafana',
          containerPort: 3000,
        },
      ],
      forceNewDeployment: true,
    });
  }
}
