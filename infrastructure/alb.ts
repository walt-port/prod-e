import { Construct } from 'constructs';
import { Lb as ApplicationLoadBalancer } from '../.gen/providers/aws/lb';
import { LbListener as AlbListener } from '../.gen/providers/aws/lb-listener';
import { LbListenerRule } from '../.gen/providers/aws/lb-listener-rule';
import { LbTargetGroup } from '../.gen/providers/aws/lb-target-group';
import { Networking } from './networking';

function assertEnvVar(name: string): string {
  const value = process.env[name];
  if (!value) throw new Error(`${name} must be set in .env`);
  return value;
}

export class Alb extends Construct {
  public alb: ApplicationLoadBalancer;
  public listener: AlbListener;
  public ecsTargetGroup: LbTargetGroup;
  public grafanaTargetGroup: LbTargetGroup;
  public prometheusTargetGroup: LbTargetGroup;

  constructor(scope: Construct, id: string, networking: Networking) {
    super(scope, id);

    const projectName = assertEnvVar('PROJECT_NAME');
    const albInternal = process.env.ALB_INTERNAL === 'true';
    const albPort = Number(assertEnvVar('ALB_PORT'));
    const backendPort = Number(assertEnvVar('BACKEND_PORT'));
    const backendHealthPath = assertEnvVar('BACKEND_HEALTH_PATH');
    const grafanaPort = Number(assertEnvVar('GRAFANA_PORT'));
    const grafanaHealthPath = assertEnvVar('GRAFANA_HEALTH_PATH');
    const grafanaPath = assertEnvVar('GRAFANA_PATH');
    const prometheusPort = Number(assertEnvVar('PROMETHEUS_PORT'));
    const prometheusHealthPath = assertEnvVar('PROMETHEUS_HEALTH_PATH');
    const prometheusPath = assertEnvVar('PROMETHEUS_PATH');

    this.alb = new ApplicationLoadBalancer(this, 'alb', {
      name: `${projectName}-alb`,
      internal: albInternal,
      loadBalancerType: 'application',
      securityGroups: [networking.albSecurityGroup.id],
      subnets: networking.publicSubnets.map(s => s.id),
      tags: { Name: `${projectName}-alb`, Project: projectName },
    });

    this.ecsTargetGroup = new LbTargetGroup(this, 'ecs-target-group', {
      name: `${projectName}-ecs-tg`,
      port: backendPort,
      protocol: 'HTTP',
      vpcId: networking.vpc.id,
      targetType: 'ip',
      healthCheck: {
        enabled: true,
        path: backendHealthPath,
        port: 'traffic-port',
        healthyThreshold: 3,
        unhealthyThreshold: 3,
        timeout: 5,
        interval: 30,
        matcher: '200-299',
      },
      tags: { Name: `${projectName}-ecs-tg`, Project: projectName },
    });

    this.grafanaTargetGroup = new LbTargetGroup(this, 'grafana-target-group', {
      name: `${projectName}-grafana-tg`,
      port: grafanaPort,
      protocol: 'HTTP',
      vpcId: networking.vpc.id,
      targetType: 'ip',
      healthCheck: {
        path: grafanaHealthPath,
        interval: 60,
        timeout: 30,
        healthyThreshold: 2,
        unhealthyThreshold: 5,
        matcher: '200,302,401,404',
      },
      tags: { Name: `${projectName}-grafana-tg`, Project: projectName },
    });

    this.prometheusTargetGroup = new LbTargetGroup(this, 'prometheus-target-group', {
      name: `${projectName}-prometheus-tg`,
      port: prometheusPort,
      protocol: 'HTTP',
      vpcId: networking.vpc.id,
      targetType: 'ip',
      healthCheck: {
        path: prometheusHealthPath,
        interval: 30,
        timeout: 5,
        healthyThreshold: 3,
        unhealthyThreshold: 3,
        matcher: '200',
      },
      tags: { Name: `${projectName}-prometheus-tg`, Project: projectName },
    });

    this.listener = new AlbListener(this, 'listener', {
      loadBalancerArn: this.alb.arn,
      port: albPort,
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

    new LbListenerRule(this, 'grafana-rule', {
      listenerArn: this.listener.arn,
      priority: 10,
      condition: [{ pathPattern: { values: [`${grafanaPath}*`] } }],
      action: [{ type: 'forward', targetGroupArn: this.grafanaTargetGroup.arn }],
    });

    new LbListenerRule(this, 'prometheus-rule', {
      listenerArn: this.listener.arn,
      priority: 20,
      condition: [{ pathPattern: { values: [`${prometheusPath}*`] } }],
      action: [{ type: 'forward', targetGroupArn: this.prometheusTargetGroup.arn }],
    });

    // Add default rule for the main backend ECS service
    new LbListenerRule(this, 'ecs-rule', {
      listenerArn: this.listener.arn,
      priority: 100, // Lower priority than specific rules
      action: [{ type: 'forward', targetGroupArn: this.ecsTargetGroup.arn }],
      // Default rule, matches all paths if no other condition matches
      condition: [{ pathPattern: { values: ['/*'] } }],
    });
  }
}
