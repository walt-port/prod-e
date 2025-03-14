import { App, TerraformOutput, TerraformStack } from 'cdktf';
import { Construct } from 'constructs';
import { DbInstance } from './.gen/providers/aws/db-instance';
import { DbSubnetGroup } from './.gen/providers/aws/db-subnet-group';
import { EcsCluster } from './.gen/providers/aws/ecs-cluster';
import { EcsService } from './.gen/providers/aws/ecs-service';
import { EcsTaskDefinition } from './.gen/providers/aws/ecs-task-definition';
import { IamRole } from './.gen/providers/aws/iam-role';
import { IamRolePolicyAttachment } from './.gen/providers/aws/iam-role-policy-attachment';
import { InternetGateway } from './.gen/providers/aws/internet-gateway';
import { Lb } from './.gen/providers/aws/lb';
import { LbListener } from './.gen/providers/aws/lb-listener';
import { LbListenerRule } from './.gen/providers/aws/lb-listener-rule';
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
  publicSubnetCidrB: '10.0.3.0/24', // New public subnet in AZ b for ALB requirement
  privateSubnetCidr: '10.0.2.0/24',
  privateSubnetCidrB: '10.0.4.0/24', // New private subnet in AZ b for RDS requirement
  tags: {
    ManagedBy: 'CDKTF',
    Project: 'prod-e',
  },
  // Database configuration
  database: {
    instanceClass: 'db.t3.micro',
    engine: 'postgres',
    engineVersion: '14.17',
    dbName: 'appdb',
    username: 'dbadmin',
    password: 'ReallyStrongPass87$',
    port: 5432,
    allocatedStorage: 20,
    skipFinalSnapshot: true,
  },
  // ECS configuration
  ecs: {
    clusterName: 'prod-e-cluster',
    serviceName: 'prod-e-service',
    taskFamily: 'prod-e-task',
    containerName: 'dummy-container',
    containerPort: 80,
    cpu: '256', // 0.25 vCPU
    memory: '512', // 0.5 GB
    image: 'node:16', // Using Node.js 16 as the base image for our application
    desiredCount: 1,
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
        Name: 'public-subnet-a',
      },
    });

    // Create a public subnet in us-west-2b (for ALB requirement)
    const publicSubnetB = new Subnet(this, 'public-subnet-b', {
      vpcId: vpc.id,
      cidrBlock: config.publicSubnetCidrB,
      availabilityZone: `${config.region}b`, // Using us-west-2b as second AZ
      mapPublicIpOnLaunch: true, // Auto-assign public IP
      tags: {
        Name: 'public-subnet-b',
      },
    });

    // Create a private subnet in us-west-2a
    const privateSubnet = new Subnet(this, 'private-subnet', {
      vpcId: vpc.id,
      cidrBlock: config.privateSubnetCidr,
      availabilityZone: `${config.region}a`, // Using only us-west-2a
      mapPublicIpOnLaunch: false, // No public IP
      tags: {
        Name: 'private-subnet-a',
      },
    });

    // Create a private subnet in us-west-2b (for RDS requirement)
    const privateSubnetB = new Subnet(this, 'private-subnet-b', {
      vpcId: vpc.id,
      cidrBlock: config.privateSubnetCidrB,
      availabilityZone: `${config.region}b`, // Using us-west-2b as second AZ
      mapPublicIpOnLaunch: false, // No public IP
      tags: {
        Name: 'private-subnet-b',
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

    // Associate the public route table with the public subnet B
    new RouteTableAssociation(this, 'public-route-association-b', {
      subnetId: publicSubnetB.id,
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

    // Associate the private route table with the private subnet B
    new RouteTableAssociation(this, 'private-route-association-b', {
      subnetId: privateSubnetB.id,
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
    const ecsTargetGroup = new LbTargetGroup(this, 'ecs-target-group', {
      name: 'ecs-target-group',
      port: config.ecs.containerPort,
      protocol: 'HTTP',
      vpcId: vpc.id,
      targetType: 'ip', // Using IP targets for Fargate
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
        Name: 'ecs-tg',
      },
    });

    // Create the Application Load Balancer
    const alb = new Lb(this, 'application-load-balancer', {
      name: 'application-load-balancer',
      internal: false, // Internet-facing ALB
      loadBalancerType: 'application',
      securityGroups: [albSecurityGroup.id],
      subnets: [publicSubnet.id, publicSubnetB.id], // Using public subnets in two AZs for ALB requirement
      enableDeletionProtection: false, // For easy cleanup in development
      tags: {
        Name: 'app-lb',
      },
    });

    // Create a listener on port 80
    const httpListener = new LbListener(this, 'alb-http-listener', {
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
    // Including subnets in two AZs to meet AWS requirement
    const dbSubnetGroup = new DbSubnetGroup(this, 'db-subnet-group', {
      name: 'db-subnet-group',
      subnetIds: [privateSubnet.id, privateSubnetB.id], // Using private subnets in two AZs for RDS requirement
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

    // -------------------- ECS Fargate Section --------------------
    // This section sets up an ECS Fargate service that runs in the private subnet
    // and can be accessed through the Application Load Balancer in the public subnet.
    // The service runs a Node.js 16 container with minimal resources (0.25 vCPU, 0.5GB memory).

    // Create a security group for the ECS tasks
    // This controls the network traffic to and from our ECS Fargate tasks
    const ecsSecurityGroup = new SecurityGroup(this, 'ecs-security-group', {
      name: 'ecs-security-group',
      description: 'Security group for ECS Fargate tasks',
      vpcId: vpc.id,
      tags: {
        Name: 'ecs-sg',
      },
    });

    // Add inbound rule to allow HTTP traffic from the ALB only
    // This ensures that only the ALB can send traffic to our containers
    new SecurityGroupRule(this, 'ecs-http-inbound', {
      type: 'ingress',
      fromPort: config.ecs.containerPort,
      toPort: config.ecs.containerPort,
      protocol: 'tcp',
      sourceSecurityGroupId: albSecurityGroup.id, // Allow traffic only from ALB
      securityGroupId: ecsSecurityGroup.id,
      description: 'Allow HTTP traffic from ALB security group',
    });

    // Add outbound rule to allow all traffic
    // This lets our containers make outbound calls to the internet and other AWS services
    new SecurityGroupRule(this, 'ecs-all-outbound', {
      type: 'egress',
      fromPort: 0,
      toPort: 0,
      protocol: '-1', // All protocols
      cidrBlocks: ['0.0.0.0/0'], // Allow traffic to anywhere
      securityGroupId: ecsSecurityGroup.id,
      description: 'Allow all outbound traffic',
    });

    // Create an ECS cluster
    // This is a logical grouping of ECS tasks and services
    const ecsCluster = new EcsCluster(this, 'ecs-cluster', {
      name: config.ecs.clusterName,
      tags: {
        Name: 'ecs-cluster',
      },
    });

    // Create IAM execution role for ECS tasks
    // This role allows ECS to pull container images and publish logs to CloudWatch
    const ecsTaskExecutionRole = new IamRole(this, 'ecs-task-execution-role', {
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
    // This grants permissions for pulling images and writing logs
    new IamRolePolicyAttachment(this, 'ecs-task-execution-role-policy', {
      role: ecsTaskExecutionRole.name,
      policyArn: 'arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy',
    });

    // Create IAM task role for ECS tasks
    // This role defines what AWS services the application inside the container can access
    const ecsTaskRole = new IamRole(this, 'ecs-task-role', {
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

    // Create a task definition for the ECS service
    // This defines the container(s) to run and their resource requirements
    const ecsTaskDefinition = new EcsTaskDefinition(this, 'ecs-task-definition', {
      family: config.ecs.taskFamily,
      requiresCompatibilities: ['FARGATE'], // Use serverless Fargate launch type
      networkMode: 'awsvpc', // Required for Fargate
      cpu: config.ecs.cpu, // 0.25 vCPU (256 CPU units)
      memory: config.ecs.memory, // 0.5 GB (512 MB)
      executionRoleArn: ecsTaskExecutionRole.arn,
      taskRoleArn: ecsTaskRole.arn,
      containerDefinitions: JSON.stringify([
        {
          name: config.ecs.containerName,
          image: config.ecs.image, // Node.js 16 base image
          essential: true, // If this container fails, the entire task fails
          portMappings: [
            {
              containerPort: config.ecs.containerPort, // Port 80 inside the container
              hostPort: config.ecs.containerPort, // Same port on the host (required for Fargate)
              protocol: 'tcp',
            },
          ],
          logConfiguration: {
            logDriver: 'awslogs', // Send logs to CloudWatch
            options: {
              'awslogs-group': `/ecs/${config.ecs.taskFamily}`,
              'awslogs-region': config.region,
              'awslogs-stream-prefix': 'ecs',
              'awslogs-create-group': 'true',
            },
          },
        },
      ]),
      tags: {
        Name: 'ecs-task-def',
      },
    });

    // Create an ECS service
    // This manages the deployment and lifecycle of the ECS tasks
    const ecsService = new EcsService(this, 'ecs-service', {
      name: config.ecs.serviceName,
      cluster: ecsCluster.id,
      taskDefinition: ecsTaskDefinition.arn,
      desiredCount: config.ecs.desiredCount, // Run 1 instance of the task
      launchType: 'FARGATE', // Serverless, no EC2 instances to manage
      schedulingStrategy: 'REPLICA', // Maintain the desired count of tasks
      networkConfiguration: {
        subnets: [privateSubnet.id], // Place tasks in the private subnet in us-west-2a
        securityGroups: [ecsSecurityGroup.id], // Use the security group we created
        assignPublicIp: false, // No public IP, will be accessed through the ALB
      },
      loadBalancer: [
        {
          targetGroupArn: ecsTargetGroup.arn,
          containerName: config.ecs.containerName,
          containerPort: config.ecs.containerPort,
        },
      ],
      tags: {
        Name: 'ecs-service',
      },
    });

    // Create a listener rule to forward traffic to the ECS target group
    new LbListenerRule(this, 'alb-listener-rule', {
      listenerArn: httpListener.arn,
      priority: 100,
      action: [
        {
          type: 'forward',
          targetGroupArn: ecsTargetGroup.arn,
        },
      ],
      condition: [
        {
          pathPattern: {
            values: ['/*'],
          },
        },
      ],
      tags: {
        Name: 'ecs-listener-rule',
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

    // Output the ECS cluster name
    new TerraformOutput(this, 'ecs-cluster-name', {
      value: ecsCluster.name,
      description: 'The name of the ECS cluster',
    });

    // Output the ECS service name
    new TerraformOutput(this, 'ecs-service-name', {
      value: ecsService.name,
      description: 'The name of the ECS service',
    });

    // Output the ECS task definition ARN
    new TerraformOutput(this, 'ecs-task-definition-arn', {
      value: ecsTaskDefinition.arn,
      description: 'The ARN of the ECS task definition',
    });
  }
}

const app = new App();
new MyStack(app, 'prod-e');
app.synth();
