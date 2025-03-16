import { TerraformOutput, TerraformStack } from 'cdktf';
import { Construct } from 'constructs';
import { DataAwsCallerIdentity } from '../.gen/providers/aws/data-aws-caller-identity';
import { DataAwsResourcegroupstaggingapiResources } from '../.gen/providers/aws/data-aws-resourcegroupstaggingapi-resources';
import { AwsProvider } from '../.gen/providers/aws/provider';
import { Alb } from './alb';
import { Backup } from './backup';
import { Ecs } from './ecs';
import { Monitoring } from './monitoring';
import { Networking } from './networking';
import { Rds } from './rds';

// Define an interface for resource existence checking
export interface ResourceExistenceOptions {
  checkResourceExists: (serviceName: string, resourceName: string) => boolean;
}

export class ProdEStack extends TerraformStack {
  public resourceExists: { [key: string]: boolean } = {};

  constructor(scope: Construct, id: string) {
    super(scope, id);

    // Configure AWS provider
    const awsProvider = new AwsProvider(this, 'aws', {
      region: 'us-west-2',
    });

    // Get AWS account ID for resource checks
    const callerIdentity = new DataAwsCallerIdentity(this, 'current', {});

    // Check for existing resources by tags
    const taggedResources = new DataAwsResourcegroupstaggingapiResources(this, 'tagged-resources', {
      tagFilter: [
        {
          key: 'Project',
          values: ['prod-e'],
        },
      ],
    });

    // Function to check if a resource exists
    const checkResourceExists = (serviceName: string, resourceName: string): boolean => {
      const key = `${serviceName}/${resourceName}`;
      // If we've already determined this, return the cached result
      if (this.resourceExists[key] !== undefined) {
        return this.resourceExists[key];
      }

      // Skip resource existence check if we're not in skip mode
      if (process.env.SKIP_EXISTING_RESOURCES !== 'true') {
        return false;
      }

      // In a real implementation, this would check AWS API
      // Here we're using a simplified approach based on known resources
      const knownResources = [
        'rds/prod-e-db',
        'ecs/prod-e-cluster',
        'iam/ecs-task-execution-role',
        'iam/ecs-task-role',
        'elasticloadbalancing/prod-e-alb',
        'elasticloadbalancing/grafana-tg',
        'elasticloadbalancing/prometheus-tg',
      ];

      // Cache result to avoid duplicate checks
      this.resourceExists[key] = knownResources.includes(key);
      return this.resourceExists[key];
    };

    // Create options object to pass to constructors
    const options: ResourceExistenceOptions = { checkResourceExists };

    // Create infrastructure components with conditional creation
    const networking = new Networking(this, 'networking', options);
    const alb = new Alb(this, 'alb', networking, options);
    const ecs = new Ecs(this, 'ecs', networking, alb, options);
    const rds = new Rds(this, 'rds', networking, options);
    const monitoring = new Monitoring(this, 'monitoring', networking, alb, ecs, options);
    const backup = new Backup(this, 'backup', options);

    // Outputs
    new TerraformOutput(this, 'alb_endpoint', {
      value: alb.alb.dnsName,
    });
  }
}

// Don't create the app here - we'll do that in the root main.ts
// Export the stack and constructs
export { Alb, Backup, Ecs, Monitoring, Networking, Rds };
