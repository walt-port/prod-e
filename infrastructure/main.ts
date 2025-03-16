import { App, S3Backend, TerraformOutput, TerraformStack } from 'cdktf';
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
    console.log('ProdEStack constructor started');

    // Configure remote state backend
    new S3Backend(this, {
      bucket: 'prod-e-tfstate',
      key: 'terraform.tfstate',
      region: 'us-west-2',
      dynamodbTable: 'prod-e-tfstate-lock',
    });
    console.log('S3Backend configured');

    // Configure AWS provider with an alias to avoid duplicate provider issues
    const awsProvider = new AwsProvider(this, 'aws', {
      region: 'us-west-2',
      alias: 'main', // Add alias to avoid duplicate provider errors
    });
    console.log('AWS provider configured');

    // Get AWS account ID for resource checks
    const callerIdentity = new DataAwsCallerIdentity(this, 'current', {
      provider: awsProvider,
    });
    console.log('Caller identity retrieved');

    // Check for existing resources by tags
    const taggedResources = new DataAwsResourcegroupstaggingapiResources(this, 'tagged-resources', {
      tagFilter: [
        {
          key: 'Project',
          values: ['prod-e'],
        },
      ],
      provider: awsProvider,
    });
    console.log('Tagged resources queried');

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
    console.log('Resource existence check function defined');

    // Create options object to pass to constructors
    const options: ResourceExistenceOptions = { checkResourceExists };
    console.log('Options object created');

    // Create infrastructure components with conditional creation
    console.log('Starting networking initialization');
    const networking = new Networking(this, 'networking');
    console.log('Networking initialized');

    console.log('Starting ALB initialization');
    const alb = new Alb(this, 'alb', networking);
    console.log('ALB initialized');

    console.log('Starting ECS initialization');
    const ecs = new Ecs(this, 'ecs', networking, alb);
    console.log('ECS initialized');

    console.log('Starting RDS initialization');
    const rds = new Rds(this, 'rds', networking);
    console.log('RDS initialized');

    console.log('Starting monitoring initialization');
    const monitoring = new Monitoring(this, 'monitoring', networking, alb, ecs);
    console.log('Monitoring initialized');

    console.log('Starting backup initialization');
    const backup = new Backup(this, 'backup', options);
    console.log('Backup initialized');

    // Outputs
    console.log('Creating output for ALB endpoint');
    new TerraformOutput(this, 'alb_endpoint', {
      value: alb.alb.dnsName,
    });
    console.log('ProdEStack constructor completed');
  }
}

// Export the stack and constructs
export { Alb, Backup, Ecs, Monitoring, Networking, Rds };

// Create and synthesize app when this file is run directly
if (require.main === module) {
  console.log('Running as a script - creating app and synth');
  const app = new App();
  new ProdEStack(app, 'prod-e');
  app.synth();
}
