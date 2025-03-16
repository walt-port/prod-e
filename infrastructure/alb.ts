import { Construct } from 'constructs';
import { Lb as ApplicationLoadBalancer } from '../.gen/providers/aws/lb';
import { LbListener as AlbListener } from '../.gen/providers/aws/lb-listener';
import { Networking } from './networking';

export class Alb extends Construct {
  public alb: ApplicationLoadBalancer;
  public listener: AlbListener;

  constructor(scope: Construct, id: string, networking: Networking) {
    super(scope, id);

    this.alb = new ApplicationLoadBalancer(this, 'alb', {
      name: 'prod-e-alb',
      internal: false,
      loadBalancerType: 'application',
      securityGroups: [], // Add SG later
      subnets: networking.publicSubnets.map(s => s.id),
      tags: { Name: 'prod-e-alb' },
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
  }
}
