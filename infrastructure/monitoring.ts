import { Construct } from 'constructs';
import { EcsService } from '../.gen/providers/aws/ecs-service';
import { EcsTaskDefinition } from '../.gen/providers/aws/ecs-task-definition';
import { SecurityGroup } from '../.gen/providers/aws/security-group';
import { SecurityGroupRule } from '../.gen/providers/aws/security-group-rule';
import { Alb } from './alb';
import { Ecs } from './ecs';
import { Networking } from './networking';

export class Monitoring extends Construct {
  public prometheusService: EcsService;
  public promSecurityGroup: SecurityGroup;
  public prometheusTaskDefinition: EcsTaskDefinition;

  constructor(scope: Construct, id: string, networking: Networking, alb: Alb, ecs: Ecs) {
    super(scope, id);

    // Security group for Prometheus
    this.promSecurityGroup = new SecurityGroup(this, 'prom-security-group', {
      name: 'prom-security-group',
      vpcId: networking.vpc.id,
      tags: { Name: 'prom-sg' },
    });

    // Add inbound rule to allow traffic from ALB
    new SecurityGroupRule(this, 'prom-inbound', {
      type: 'ingress',
      fromPort: 9090,
      toPort: 9090,
      protocol: 'tcp',
      sourceSecurityGroupId: networking.albSecurityGroup.id, // Allow from ALB only
      securityGroupId: this.promSecurityGroup.id,
    });

    // Add outbound rule to allow all traffic
    new SecurityGroupRule(this, 'prom-outbound', {
      type: 'egress',
      fromPort: 0,
      toPort: 0,
      protocol: '-1', // All protocols
      cidrBlocks: ['0.0.0.0/0'], // Allow traffic to anywhere
      securityGroupId: this.promSecurityGroup.id,
    });

    // Task definition for Prometheus
    this.prometheusTaskDefinition = new EcsTaskDefinition(this, 'prom-task-definition', {
      family: 'prom-task',
      requiresCompatibilities: ['FARGATE'],
      networkMode: 'awsvpc',
      cpu: '256',
      memory: '512',
      executionRoleArn: ecs.taskExecutionRole.arn,
      taskRoleArn: ecs.taskRole.arn,
      containerDefinitions: JSON.stringify([
        {
          name: 'prometheus',
          image: '043309339649.dkr.ecr.us-west-2.amazonaws.com/prod-e-prometheus:latest',
          essential: true,
          portMappings: [
            {
              containerPort: 9090,
              hostPort: 9090,
              protocol: 'tcp',
            },
          ],
          logConfiguration: {
            logDriver: 'awslogs',
            options: {
              'awslogs-group': '/ecs/prom-task',
              'awslogs-region': 'us-west-2',
              'awslogs-stream-prefix': 'ecs',
              'awslogs-create-group': 'true',
            },
          },
        },
      ]),
      tags: { Name: 'prom-task-def' },
    });

    this.prometheusService = new EcsService(this, 'prometheus-service', {
      name: 'prometheus-service',
      cluster: ecs.cluster.id,
      taskDefinition: this.prometheusTaskDefinition.arn,
      desiredCount: 1,
      launchType: 'FARGATE',
      networkConfiguration: {
        subnets: networking.privateSubnets.map(s => s.id),
        securityGroups: [this.promSecurityGroup.id],
        assignPublicIp: false,
      },
      loadBalancer: [
        {
          targetGroupArn: alb.prometheusTargetGroup.arn,
          containerName: 'prometheus',
          containerPort: 9090,
        },
      ],
    });
    // Grafana already in ecs.ts - extend here if needed
  }
}
