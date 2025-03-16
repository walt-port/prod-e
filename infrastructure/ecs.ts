import { Construct } from 'constructs';
import { EcsCluster } from '../.gen/providers/aws/ecs-cluster';
import { EcsService } from '../.gen/providers/aws/ecs-service';
import { Alb } from './alb';
import { Networking } from './networking';

export class Ecs extends Construct {
  public cluster: EcsCluster;
  public service: EcsService;

  constructor(scope: Construct, id: string, networking: Networking, alb: Alb) {
    super(scope, id);

    this.cluster = new EcsCluster(this, 'cluster', {
      name: 'prod-e-cluster',
      tags: { Name: 'prod-e-cluster' },
    });

    this.service = new EcsService(this, 'grafana-service', {
      name: 'grafana-service',
      cluster: this.cluster.id,
      taskDefinition: 'arn:aws:ecs:us-west-2:123456789012:task-definition/grafana-task:10', // Update with real ARN
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
          containerName: 'grafana',
          containerPort: 3000,
        },
      ],
      forceNewDeployment: true,
    });
  }
}
