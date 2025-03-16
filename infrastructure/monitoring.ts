import { Construct } from 'constructs';
import { EcsService } from '../.gen/providers/aws/ecs-service';
import { Alb } from './alb';
import { Ecs } from './ecs';
import { Networking } from './networking';

export class Monitoring extends Construct {
  public prometheusService: EcsService;

  constructor(scope: Construct, id: string, networking: Networking, alb: Alb, ecs: Ecs) {
    super(scope, id);

    this.prometheusService = new EcsService(this, 'prometheus-service', {
      name: 'prometheus-service',
      cluster: ecs.cluster.id,
      taskDefinition: 'arn:aws:ecs:us-west-2:123456789012:task-definition/prometheus-task:1', // Update with real ARN
      desiredCount: 1,
      launchType: 'FARGATE',
      networkConfiguration: {
        subnets: networking.privateSubnets.map(s => s.id),
        securityGroups: [], // Add SG later
        assignPublicIp: false,
      },
      loadBalancer: [
        {
          targetGroupArn: alb.listener.arn, // Update with real TG ARN
          containerName: 'prometheus',
          containerPort: 9090,
        },
      ],
    });
    // Grafana already in ecs.ts - extend here if needed
  }
}
