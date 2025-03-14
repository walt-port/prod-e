import { App, TerraformOutput, TerraformStack } from 'cdktf';
import { Construct } from 'constructs';
import { DbInstance } from './.gen/providers/aws/db-instance';
import { DbSubnetGroup } from './.gen/providers/aws/db-subnet-group';
import { InternetGateway } from './.gen/providers/aws/internet-gateway';
import { Lb } from './.gen/providers/aws/lb';
import { LbListener } from './.gen/providers/aws/lb-listener';
import { LbTargetGroup } from './.gen/providers/aws/lb-target-group';
import { AwsProvider } from './.gen/providers/aws/provider';
import { Route } from './.gen/providers/aws/route';
import { RouteTable } from './.gen/providers/aws/route-table';
import { RouteTableAssociation } from './.gen/providers/aws/route-table-association';
import { SecurityGroup } from './.gen/providers/aws/security-group';
import { SecurityGroupRule } from './.gen/providers/aws/security-group-rule';
import { Subnet } from './.gen/providers/aws/subnet';
import { Vpc } from './.gen/providers/aws/vpc';

// Configuration
const config = {
  region: 'us-west-2',
  vpcCidr: '10.0.0.0/16',
  publicSubnetCidr: '10.0.1.0/24',
  privateSubnetCidr: '10.0.2.0/24',
  tags: {
    ManagedBy: 'CDKTF',
    Project: 'prod-e',
  },
  // Database configuration
  database: {
    instanceClass: 'db.t3.micro',
    engine: 'postgres',
    engineVersion: '14.10',
    dbName: 'appdb',
    username: 'admin',
    password: 'ReallyStrongPass87$',
    port: 5432,
    allocatedStorage: 20,
    skipFinalSnapshot: true,
  },
};

class MyStack extends TerraformStack {
  constructor(scope: Construct, id: string) {
    super(scope, id);

    // Define AWS provider
    new AwsProvider(this, 'aws', {
      region: config.region,
      defaultTags: [
        {
          tags: config.tags,
        },
      ],
    });

    // Create a VPC
    const vpc = new Vpc(this, 'main-vpc', {
      cidrBlock: config.vpcCidr,
      enableDnsSupport: true,
      enableDnsHostnames: true,
      tags: {
        Name: 'main-vpc',
      },
    });

    // Create an Internet Gateway for the public subnet
    const internetGateway = new InternetGateway(this, 'internet-gateway', {
      vpcId: vpc.id,
      tags: {
        Name: 'igw',
      },
    });

    // Create a public subnet in us-west-2a
    const publicSubnet = new Subnet(this, 'public-subnet', {
      vpcId: vpc.id,
      cidrBlock: config.publicSubnetCidr,
      availabilityZone: `${config.region}a`, // Using only us-west-2a
      mapPublicIpOnLaunch: true, // Auto-assign public IP
      tags: {
        Name: 'public-subnet',
      },
    });

    // Create a private subnet in us-west-2a
    const privateSubnet = new Subnet(this, 'private-subnet', {
      vpcId: vpc.id,
      cidrBlock: config.privateSubnetCidr,
      availabilityZone: `${config.region}a`, // Using only us-west-2a
      mapPublicIpOnLaunch: false, // No public IP
      tags: {
        Name: 'private-subnet',
      },
    });

    // Create a route table for the public subnet
    const publicRouteTable = new RouteTable(this, 'public-route-table', {
      vpcId: vpc.id,
      tags: {
        Name: 'public-rt',
      },
    });

    // Create a route to the internet gateway
    new Route(this, 'public-route', {
      routeTableId: publicRouteTable.id,
      destinationCidrBlock: '0.0.0.0/0', // All traffic
      gatewayId: internetGateway.id,
    });

    // Associate the public route table with the public subnet
    new RouteTableAssociation(this, 'public-route-association', {
      subnetId: publicSubnet.id,
      routeTableId: publicRouteTable.id,
    });

    // Create a route table for the private subnet
    const privateRouteTable = new RouteTable(this, 'private-route-table', {
      vpcId: vpc.id,
      tags: {
        Name: 'private-rt',
      },
    });

    // Associate the private route table with the private subnet
    new RouteTableAssociation(this, 'private-route-association', {
      subnetId: privateSubnet.id,
      routeTableId: privateRouteTable.id,
    });

    // -------------------- Application Load Balancer Section --------------------

    // Create a security group for the ALB
    const albSecurityGroup = new SecurityGroup(this, 'alb-security-group', {
      name: 'alb-security-group',
      description: 'Security group for the Application Load Balancer',
      vpcId: vpc.id,
      tags: {
        Name: 'alb-sg',
      },
    });

    // Add inbound rule to allow HTTP traffic from anywhere
    new SecurityGroupRule(this, 'alb-http-inbound', {
      type: 'ingress',
      fromPort: 80,
      toPort: 80,
      protocol: 'tcp',
      cidrBlocks: ['0.0.0.0/0'], // Allow traffic from anywhere
      securityGroupId: albSecurityGroup.id,
      description: 'Allow HTTP traffic from anywhere',
    });

    // Add outbound rule to allow all traffic
    new SecurityGroupRule(this, 'alb-all-outbound', {
      type: 'egress',
      fromPort: 0,
      toPort: 0,
      protocol: '-1', // All protocols
      cidrBlocks: ['0.0.0.0/0'], // Allow traffic to anywhere
      securityGroupId: albSecurityGroup.id,
      description: 'Allow all outbound traffic',
    });

    // Create a target group for the ALB
    // This is required even if we're not adding targets yet
    const targetGroup = new LbTargetGroup(this, 'default-target-group', {
      name: 'default-target-group',
      port: 80,
      protocol: 'HTTP',
      vpcId: vpc.id,
      targetType: 'ip', // Using IP targets for future compatibility with Fargate
      healthCheck: {
        enabled: true,
        path: '/',
        port: 'traffic-port',
        healthyThreshold: 3,
        unhealthyThreshold: 3,
        timeout: 5,
        interval: 30,
        matcher: '200-299', // Success codes
      },
      tags: {
        Name: 'default-tg',
      },
    });

    // Create the Application Load Balancer
    const alb = new Lb(this, 'application-load-balancer', {
      name: 'application-load-balancer',
      internal: false, // Internet-facing ALB
      loadBalancerType: 'application',
      securityGroups: [albSecurityGroup.id],
      subnets: [publicSubnet.id], // Using only public subnet in us-west-2a
      enableDeletionProtection: false, // For easy cleanup in development
      tags: {
        Name: 'app-lb',
      },
    });

    // Create a listener on port 80 with a fixed 503 response
    new LbListener(this, 'alb-http-listener', {
      loadBalancerArn: alb.arn,
      port: 80,
      protocol: 'HTTP',
      defaultAction: [
        {
          type: 'fixed-response',
          fixedResponse: {
            contentType: 'text/plain',
            messageBody: 'Service Unavailable',
            statusCode: '503',
          },
        },
      ],
      tags: {
        Name: 'http-listener',
      },
    });

    // -------------------- RDS PostgreSQL Database Section --------------------

    // Create a security group for the RDS instance
    const dbSecurityGroup = new SecurityGroup(this, 'db-security-group', {
      name: 'db-security-group',
      description: 'Security group for the RDS PostgreSQL instance',
      vpcId: vpc.id,
      tags: {
        Name: 'db-sg',
      },
    });

    // Add inbound rule to allow PostgreSQL traffic (port 5432) from anywhere
    // Note: This is for development purposes only. In production, limit access to specific sources.
    new SecurityGroupRule(this, 'db-postgres-inbound', {
      type: 'ingress',
      fromPort: config.database.port,
      toPort: config.database.port,
      protocol: 'tcp',
      cidrBlocks: ['0.0.0.0/0'], // Allow traffic from anywhere (for dev only)
      securityGroupId: dbSecurityGroup.id,
      description: 'Allow PostgreSQL traffic from anywhere',
    });

    // Add outbound rule to allow all traffic from the RDS instance
    new SecurityGroupRule(this, 'db-all-outbound', {
      type: 'egress',
      fromPort: 0,
      toPort: 0,
      protocol: '-1', // All protocols
      cidrBlocks: ['0.0.0.0/0'], // Allow traffic to anywhere
      securityGroupId: dbSecurityGroup.id,
      description: 'Allow all outbound traffic',
    });

    // Create a DB subnet group (required for RDS instances)
    // For a single-AZ setup, we need to include at least two subnets but will only use one
    const dbSubnetGroup = new DbSubnetGroup(this, 'db-subnet-group', {
      name: 'db-subnet-group',
      subnetIds: [privateSubnet.id, publicSubnet.id], // Using both subnets to meet the minimum requirement
      description: 'Subnet group for RDS instance',
      tags: {
        Name: 'db-subnet-group',
      },
    });

    // Create the RDS PostgreSQL instance
    const rdsInstance = new DbInstance(this, 'postgres-instance', {
      identifier: 'postgres-instance',
      instanceClass: config.database.instanceClass,
      allocatedStorage: config.database.allocatedStorage,
      engine: config.database.engine,
      engineVersion: config.database.engineVersion,
      dbName: config.database.dbName,
      username: config.database.username,
      password: config.database.password,
      dbSubnetGroupName: dbSubnetGroup.name,
      vpcSecurityGroupIds: [dbSecurityGroup.id],
      skipFinalSnapshot: config.database.skipFinalSnapshot, // Skip final snapshot for easy cleanup
      publiclyAccessible: true, // Allow public access for development
      port: config.database.port,
      multiAz: false, // Single AZ deployment
      availabilityZone: `${config.region}a`, // Use same AZ as our private subnet
      tags: {
        Name: 'postgres-db',
      },
    });

    // Output the VPC ID
    new TerraformOutput(this, 'vpc-id', {
      value: vpc.id,
      description: 'The ID of the VPC',
    });

    // Output the public subnet ID
    new TerraformOutput(this, 'public-subnet-id', {
      value: publicSubnet.id,
      description: 'The ID of the public subnet',
    });

    // Output the private subnet ID
    new TerraformOutput(this, 'private-subnet-id', {
      value: privateSubnet.id,
      description: 'The ID of the private subnet',
    });

    // Output the ALB DNS name
    new TerraformOutput(this, 'alb-dns-name', {
      value: alb.dnsName,
      description: 'The DNS name of the Application Load Balancer',
    });

    // Output the ALB ARN
    new TerraformOutput(this, 'alb-arn', {
      value: alb.arn,
      description: 'The ARN of the Application Load Balancer',
    });

    // Output the RDS endpoint address
    new TerraformOutput(this, 'rds-endpoint', {
      value: rdsInstance.endpoint,
      description: 'The connection endpoint for the RDS instance',
    });

    // Output the RDS port
    new TerraformOutput(this, 'rds-port', {
      value: rdsInstance.port.toString(),
      description: 'The port for the RDS instance',
    });
  }
}

const app = new App();
new MyStack(app, 'prod-e');
app.synth();
