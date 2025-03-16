import { Construct } from 'constructs';
import { Lb as ApplicationLoadBalancer } from '../.gen/providers/aws/lb';
import { LbListener as AlbListener } from '../.gen/providers/aws/lb-listener';
import { LbListenerRule } from '../.gen/providers/aws/lb-listener-rule';
import { LbTargetGroup } from '../.gen/providers/aws/lb-target-group';
import { Networking } from './networking';

export class Alb extends Construct {
  public alb: ApplicationLoadBalancer;
  public listener: AlbListener;
  public ecsTargetGroup: LbTargetGroup;
  public grafanaTargetGroup: LbTargetGroup;
  public prometheusTargetGroup: LbTargetGroup;

  constructor(scope: Construct, id: string, networking: Networking) {
    super(scope, id);

    this.alb = new ApplicationLoadBalancer(this, 'alb', {
      name: 'prod-e-alb',
      internal: false,
      loadBalancerType: 'application',
      securityGroups: [networking.albSecurityGroup.id],
      subnets: networking.publicSubnets.map(s => s.id),
      tags: { Name: 'prod-e-alb' },
    });

    // Create target groups
    this.ecsTargetGroup = new LbTargetGroup(this, 'ecs-target-group', {
      name: 'ecs-target-group',
      port: 3000,
      protocol: 'HTTP',
      vpcId: networking.vpc.id,
      targetType: 'ip', // Using IP targets for Fargate
      healthCheck: {
        enabled: true,
        path: '/health',
        port: 'traffic-port',
        healthyThreshold: 3,
        unhealthyThreshold: 3,
        timeout: 5,
        interval: 30,
        matcher: '200-299', // Success codes
      },
      tags: {
        Name: 'ecs-tg',
      },
    });

    this.grafanaTargetGroup = new LbTargetGroup(this, 'grafana-target-group', {
      name: 'grafana-tg',
      port: 3000,
      protocol: 'HTTP',
      vpcId: networking.vpc.id,
      targetType: 'ip',
      healthCheck: {
        path: '/grafana/api/health',
        interval: 60,
        timeout: 30,
        healthyThreshold: 2,
        unhealthyThreshold: 5,
        matcher: '200,302,401,404', // Include 404 as valid during startup
      },
      tags: {
        Name: 'grafana-tg',
      },
    });

    this.prometheusTargetGroup = new LbTargetGroup(this, 'prometheus-target-group', {
      name: 'prometheus-tg',
      port: 9090,
      protocol: 'HTTP',
      vpcId: networking.vpc.id,
      targetType: 'ip',
      healthCheck: {
        path: '/metrics',
        interval: 30,
        timeout: 5,
        healthyThreshold: 3,
        unhealthyThreshold: 3,
        matcher: '200',
      },
      tags: {
        Name: 'prometheus-tg',
      },
    });

    this.listener = new AlbListener(this, 'listener', {
      loadBalancerArn: this.alb.arn,
      port: 80,
      protocol: 'HTTP',
      defaultAction: [
        {
          type: 'fixed-response',
          fixedResponse: {
            contentType: 'text/plain',
            messageBody: 'Healthy',
            statusCode: '200',
          },
        },
      ],
    });

    // Add listener rules for each target group
    new LbListenerRule(this, 'grafana-rule', {
      listenerArn: this.listener.arn,
      priority: 10,
      condition: [
        {
          pathPattern: {
            values: ['/grafana*'],
          },
        },
      ],
      action: [
        {
          type: 'forward',
          targetGroupArn: this.grafanaTargetGroup.arn,
        },
      ],
    });

    new LbListenerRule(this, 'prometheus-rule', {
      listenerArn: this.listener.arn,
      priority: 20,
      condition: [
        {
          pathPattern: {
            values: ['/metrics*'],
          },
        },
      ],
      action: [
        {
          type: 'forward',
          targetGroupArn: this.prometheusTargetGroup.arn,
        },
      ],
    });
  }
}
