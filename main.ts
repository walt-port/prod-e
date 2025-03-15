import { App, S3Backend, TerraformOutput, TerraformStack } from 'cdktf';
import { Construct } from 'constructs';
import { CloudwatchEventRule } from './.gen/providers/aws/cloudwatch-event-rule';
import { DbInstance } from './.gen/providers/aws/db-instance';
import { DbSubnetGroup } from './.gen/providers/aws/db-subnet-group';
import { EcsCluster } from './.gen/providers/aws/ecs-cluster';
import { EcsService } from './.gen/providers/aws/ecs-service';
import { EcsTaskDefinition } from './.gen/providers/aws/ecs-task-definition';
import { EfsAccessPoint } from './.gen/providers/aws/efs-access-point';
import { EfsFileSystem } from './.gen/providers/aws/efs-file-system';
import { EfsMountTarget } from './.gen/providers/aws/efs-mount-target';
import { Eip } from './.gen/providers/aws/eip';
import { IamRole } from './.gen/providers/aws/iam-role';
import { IamRolePolicy } from './.gen/providers/aws/iam-role-policy';
import { IamRolePolicyAttachment } from './.gen/providers/aws/iam-role-policy-attachment';
import { InternetGateway } from './.gen/providers/aws/internet-gateway';
import { LambdaFunction } from './.gen/providers/aws/lambda-function';
import { LambdaPermission } from './.gen/providers/aws/lambda-permission';
import { Lb } from './.gen/providers/aws/lb';
import { LbListener } from './.gen/providers/aws/lb-listener';
import { LbListenerRule } from './.gen/providers/aws/lb-listener-rule';
import { LbTargetGroup } from './.gen/providers/aws/lb-target-group';
import { NatGateway } from './.gen/providers/aws/nat-gateway';
import { AwsProvider } from './.gen/providers/aws/provider';
import { Route } from './.gen/providers/aws/route';
import { RouteTable } from './.gen/providers/aws/route-table';
import { RouteTableAssociation } from './.gen/providers/aws/route-table-association';
import { S3Bucket } from './.gen/providers/aws/s3-bucket';
import { SecretsmanagerSecret } from './.gen/providers/aws/secretsmanager-secret';
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
  // ECR configuration
  ecr: {
    repositoryName: 'prod-e-backend',
    imageScanningConfig: true,
    mutability: 'MUTABLE',
  },
  // ECS configuration
  ecs: {
    clusterName: 'prod-e-cluster',
    serviceName: 'prod-e-service',
    taskFamily: 'prod-e-task',
    containerName: 'prod-e-container',
    containerPort: 3000, // Updated to match our Express app port
    cpu: '256', // 0.25 vCPU
    memory: '512', // 0.5 GB
    image: 'node:16', // This will be updated with our ECR image
    desiredCount: 1,
  },
};

class MyStack extends TerraformStack {
  constructor(scope: Construct, id: string) {
    super(scope, id);

    // Configure S3 backend
    new S3Backend(this, {
      bucket: 'prod-e-terraform-state',
      key: 'terraform.tfstate',
      region: 'us-west-2',
      encrypt: true,
      dynamodbTable: 'prod-e-terraform-lock',
    });

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

    // Create an Internet Gateway to provide internet access
    const internetGateway = new InternetGateway(this, 'internet-gateway', {
      vpcId: vpc.id,
      tags: {
        Name: 'main-igw',
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

    // Create an Elastic IP for the NAT Gateway
    const natEip = new Eip(this, 'nat-eip', {
      domain: 'vpc',
      tags: {
        Name: 'nat-eip',
      },
    });

    // Create a NAT Gateway in the public subnet
    const natGateway = new NatGateway(this, 'nat-gateway', {
      allocationId: natEip.id,
      subnetId: publicSubnet.id,
      tags: {
        Name: 'main-nat-gateway',
      },
    });

    // Create a route table for public subnets
    const publicRouteTable = new RouteTable(this, 'public-route-table', {
      vpcId: vpc.id,
      tags: {
        Name: 'public-rt',
      },
    });

    // Create a route table for private subnets
    const privateRouteTable = new RouteTable(this, 'private-route-table', {
      vpcId: vpc.id,
      tags: {
        Name: 'private-rt',
      },
    });

    // Create a route to the internet through the Internet Gateway for public subnets
    new Route(this, 'public-route', {
      routeTableId: publicRouteTable.id,
      destinationCidrBlock: '0.0.0.0/0',
      gatewayId: internetGateway.id,
    });

    // Create a route to the internet through the NAT Gateway for private subnets
    new Route(this, 'private-route', {
      routeTableId: privateRouteTable.id,
      destinationCidrBlock: '0.0.0.0/0',
      natGatewayId: natGateway.id,
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
      name: 'ecs-target-group-v2',
      port: config.ecs.containerPort,
      protocol: 'HTTP',
      vpcId: vpc.id,
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

    // Create an HTTP listener for the ALB
    const albHttpListener = new LbListener(this, 'alb-http-listener', {
      loadBalancerArn: alb.arn,
      port: 80,
      protocol: 'HTTP', // Using HTTP for simplicity
      defaultAction: [
        {
          type: 'fixed-response',
          fixedResponse: {
            contentType: 'text/plain',
            statusCode: '404',
            messageBody: 'Not Found',
          },
        },
      ],
      tags: {
        Name: 'alb-http-listener',
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
    const dbInstance = new DbInstance(this, 'postgres-instance', {
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

    // Add inbound rule to allow HTTP traffic from ALB
    new SecurityGroupRule(this, 'ecs-http-inbound', {
      type: 'ingress',
      fromPort: config.ecs.containerPort,
      toPort: config.ecs.containerPort,
      protocol: 'tcp',
      sourceSecurityGroupId: albSecurityGroup.id, // Allow traffic from ALB
      securityGroupId: ecsSecurityGroup.id,
      description: 'Allow HTTP traffic from ALB',
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

    // -------------------- ECR Repository Section --------------------
    // Create an Elastic Container Registry repository to store our Docker images

    // Create ECS cluster
    const ecsCluster = new EcsCluster(this, 'ecs-cluster', {
      name: config.ecs.clusterName,
      tags: {
        Name: 'ecs-cluster',
      },
    });

    // Reference existing ECR repository
    const ecrRepositoryUrl = `043309339649.dkr.ecr.${config.region}.amazonaws.com/${config.ecr.repositoryName}`;

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

    // Add CloudWatch Logs permissions to create log groups
    new IamRolePolicyAttachment(this, 'ecs-task-execution-cloudwatch-logs-policy', {
      role: ecsTaskExecutionRole.name,
      policyArn: 'arn:aws:iam::aws:policy/CloudWatchLogsFullAccess',
    });

    // Add SecretsManager access policy to the ECS task execution role
    new IamRolePolicyAttachment(this, 'ecs-task-execution-secretsmanager-policy', {
      role: ecsTaskExecutionRole.name,
      policyArn: 'arn:aws:iam::aws:policy/SecretsManagerReadWrite',
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
          image: `${ecrRepositoryUrl}:latest`, // Use our ECR repository with latest tag
          essential: true, // If this container fails, the entire task fails
          portMappings: [
            {
              containerPort: config.ecs.containerPort, // Port 3000 inside the container (Express app)
              hostPort: config.ecs.containerPort, // Same port on the host (required for Fargate)
              protocol: 'tcp',
            },
          ],
          environment: [
            {
              name: 'DB_HOST',
              value: dbInstance.address,
            },
            {
              name: 'DB_PORT',
              value: dbInstance.port.toString(),
            },
            {
              name: 'DB_NAME',
              value: config.database.dbName,
            },
            {
              name: 'DB_USER',
              value: config.database.username,
            },
            {
              name: 'DB_PASSWORD',
              value: config.database.password,
            },
            {
              name: 'NODE_ENV',
              value: 'production',
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
          healthCheck: {
            command: ['CMD-SHELL', 'curl -f http://localhost:3000/health || exit 1'],
            interval: 30,
            timeout: 5,
            retries: 3,
            startPeriod: 60,
          },
        },
      ]),
      tags: {
        Name: 'ecs-task-def',
      },
    });

    // Create an ECS service
    // This defines how our task should run and be scaled
    const ecsService = new EcsService(this, 'ecs-service', {
      cluster: ecsCluster.id,
      desiredCount: config.ecs.desiredCount,
      launchType: 'FARGATE', // Use serverless Fargate
      taskDefinition: ecsTaskDefinition.arn,
      name: config.ecs.serviceName,
      networkConfiguration: {
        subnets: [privateSubnet.id, privateSubnetB.id],
        securityGroups: [ecsSecurityGroup.id],
        assignPublicIp: false, // No public IP needed in private subnet
      },
      loadBalancer: [
        {
          containerName: config.ecs.containerName,
          containerPort: config.ecs.containerPort,
          targetGroupArn: ecsTargetGroup.arn,
        },
      ],
      forceNewDeployment: true, // Force new deployment on changes
      deploymentCircuitBreaker: {
        enable: true,
        rollback: true,
      },
      deploymentController: {
        type: 'ECS', // Use ECS managed deployments
      },
      tags: {
        Name: 'ecs-service',
      },
    });

    // Create a listener rule to forward traffic to our ECS service
    new LbListenerRule(this, 'alb-listener-rule', {
      listenerArn: albHttpListener.arn,
      priority: 100, // Higher priority rules are evaluated first
      action: [
        {
          type: 'forward',
          targetGroupArn: ecsTargetGroup.arn,
        },
      ],
      condition: [
        {
          pathPattern: {
            values: ['/*'], // Forward all traffic
          },
        },
      ],
      tags: {
        Name: 'ecs-listener-rule',
      },
      lifecycle: {
        createBeforeDestroy: true,
      },
    });

    // Prometheus Setup
    const promSecurityGroup = new SecurityGroup(this, 'prom-security-group', {
      name: 'prom-security-group',
      vpcId: vpc.id,
      tags: { Name: 'prom-sg' },
    });
    new SecurityGroupRule(this, 'prom-inbound', {
      type: 'ingress',
      fromPort: 9090,
      toPort: 9090,
      protocol: 'tcp',
      sourceSecurityGroupId: albSecurityGroup.id, // Allow from ALB only
      securityGroupId: promSecurityGroup.id,
    });
    new SecurityGroupRule(this, 'prom-outbound', {
      type: 'egress',
      fromPort: 0,
      toPort: 0,
      protocol: '-1',
      cidrBlocks: ['0.0.0.0/0'],
      securityGroupId: promSecurityGroup.id,
    });
    const promTaskDefinition = new EcsTaskDefinition(this, 'prom-task-definition', {
      family: 'prom-task',
      requiresCompatibilities: ['FARGATE'],
      networkMode: 'awsvpc',
      cpu: '256',
      memory: '512',
      executionRoleArn: ecsTaskExecutionRole.arn,
      taskRoleArn: ecsTaskRole.arn,
      containerDefinitions: JSON.stringify([
        {
          name: 'prometheus',
          image: '043309339649.dkr.ecr.us-west-2.amazonaws.com/prod-e-prometheus:latest',
          essential: true,
          portMappings: [{ containerPort: 9090, hostPort: 9090, protocol: 'tcp' }],
          logConfiguration: {
            logDriver: 'awslogs',
            options: {
              'awslogs-group': '/ecs/prom-task',
              'awslogs-region': config.region,
              'awslogs-stream-prefix': 'ecs',
              'awslogs-create-group': 'true',
            },
          },
        },
      ]),
      tags: { Name: 'prom-task-def' },
    });
    const promService = new EcsService(this, 'prom-service', {
      name: 'prod-e-prom-service', // Changed to ensure uniqueness
      cluster: ecsCluster.id,
      taskDefinition: promTaskDefinition.arn,
      desiredCount: 1,
      launchType: 'FARGATE',
      networkConfiguration: {
        subnets: [privateSubnet.id, privateSubnetB.id],
        securityGroups: [promSecurityGroup.id],
        assignPublicIp: false,
      },
      tags: { Name: 'prom-service' },
    });
    new TerraformOutput(this, 'prom-service-name', { value: promService.name });

    // Setup Grafana

    // EFS File System for Grafana persistence
    const grafanaFileSystem = new EfsFileSystem(this, 'grafana-efs', {
      creationToken: 'grafana-efs',
      encrypted: true,
      lifecyclePolicy: [{ transitionToIa: 'AFTER_30_DAYS' }],
      performanceMode: 'generalPurpose',
      throughputMode: 'bursting',
      tags: { Name: 'grafana-efs' },
    });

    // EFS Access Point
    const grafanaAccessPoint = new EfsAccessPoint(this, 'grafana-ap', {
      fileSystemId: grafanaFileSystem.id,
      posixUser: { uid: 472, gid: 472 }, // Grafana container user
      rootDirectory: {
        path: '/grafana',
        creationInfo: {
          ownerGid: 472,
          ownerUid: 472,
          permissions: '755',
        },
      },
    });

    // EFS Mount Target
    const grafanaMountTarget = new EfsMountTarget(this, 'grafana-mt', {
      fileSystemId: grafanaFileSystem.id,
      subnetId: privateSubnet.id,
      securityGroups: [ecsSecurityGroup.id],
    });

    // Grafana security group
    const grafanaSecurityGroup = new SecurityGroup(this, 'grafana-security-group', {
      name: 'grafana-security-group',
      vpcId: vpc.id,
      tags: { Name: 'grafana-sg' },
    });

    // Security group rules for Grafana
    new SecurityGroupRule(this, 'grafana-inbound', {
      type: 'ingress',
      fromPort: 3000,
      toPort: 3000,
      protocol: 'tcp',
      sourceSecurityGroupId: albSecurityGroup.id, // Only allow access from ALB
      securityGroupId: grafanaSecurityGroup.id,
    });

    new SecurityGroupRule(this, 'grafana-outbound', {
      type: 'egress',
      fromPort: 0,
      toPort: 0,
      protocol: '-1',
      cidrBlocks: ['0.0.0.0/0'],
      securityGroupId: grafanaSecurityGroup.id,
    });

    // Specific security group rule for EFS access
    new SecurityGroupRule(this, 'grafana-efs-outbound', {
      type: 'egress',
      fromPort: 2049,
      toPort: 2049,
      protocol: 'tcp',
      cidrBlocks: [config.vpcCidr], // VPC CIDR
      securityGroupId: grafanaSecurityGroup.id,
    });

    // Specific security group rule for Prometheus access
    new SecurityGroupRule(this, 'grafana-prom-outbound', {
      type: 'egress',
      fromPort: 9090,
      toPort: 9090,
      protocol: 'tcp',
      sourceSecurityGroupId: promSecurityGroup.id,
      securityGroupId: grafanaSecurityGroup.id,
    });

    // Create a Secret for Grafana admin password
    const grafanaSecret = new SecretsmanagerSecret(this, 'grafana-admin-secret', {
      name: 'grafana-admin-credentials',
      recoveryWindowInDays: 7,
    });

    // Grafana Task Definition
    const grafanaTaskDefinition = new EcsTaskDefinition(this, 'grafana-task-definition', {
      family: 'grafana-task',
      requiresCompatibilities: ['FARGATE'],
      networkMode: 'awsvpc',
      cpu: '256',
      memory: '512',
      executionRoleArn: ecsTaskExecutionRole.arn,
      taskRoleArn: ecsTaskRole.arn,
      volume: [
        {
          name: 'grafana-storage',
          efsVolumeConfiguration: {
            fileSystemId: grafanaFileSystem.id,
            transitEncryption: 'ENABLED',
            authorizationConfig: {
              accessPointId: grafanaAccessPoint.id,
              iam: 'ENABLED',
            },
            rootDirectory: '/',
          },
        },
      ],
      containerDefinitions: JSON.stringify([
        {
          name: 'grafana',
          image: `043309339649.dkr.ecr.${config.region}.amazonaws.com/prod-e-grafana:latest`,
          essential: true,
          portMappings: [{ containerPort: 3000, hostPort: 3000, protocol: 'tcp' }],
          environment: [
            { name: 'GF_SERVER_ROOT_URL', value: `http://${alb.dnsName}/grafana` },
            { name: 'GF_SECURITY_ADMIN_USER', value: 'admin' },
            { name: 'GF_USERS_ALLOW_SIGN_UP', value: 'false' },
            { name: 'GF_INSTALL_PLUGINS', value: 'grafana-piechart-panel,grafana-clock-panel' },
            { name: 'GF_LOG_MODE', value: 'console' },
            { name: 'GF_PATHS_PROVISIONING', value: '/etc/grafana/provisioning' },
          ],
          secrets: [
            { name: 'GF_SECURITY_ADMIN_PASSWORD', valueFrom: `${grafanaSecret.arn}:password::` },
          ],
          mountPoints: [
            {
              sourceVolume: 'grafana-storage',
              containerPath: '/var/lib/grafana',
              readOnly: false,
            },
          ],
          healthCheck: {
            command: ['CMD-SHELL', 'wget -q --spider http://localhost:3000/api/health || exit 1'],
            interval: 30,
            timeout: 5,
            retries: 3,
            startPeriod: 60,
          },
          logConfiguration: {
            logDriver: 'awslogs',
            options: {
              'awslogs-group': '/ecs/grafana-task',
              'awslogs-region': config.region,
              'awslogs-stream-prefix': 'ecs',
              'awslogs-create-group': 'true',
            },
          },
        },
      ]),
      tags: { Name: 'grafana-task-def' },
    });

    // Grafana Target Group
    const grafanaTargetGroup = new LbTargetGroup(this, 'grafana-target-group', {
      name: 'grafana-tg',
      port: 3000,
      protocol: 'HTTP',
      vpcId: vpc.id,
      targetType: 'ip',
      healthCheck: {
        path: '/api/health',
        interval: 30,
        timeout: 5,
        healthyThreshold: 3,
        unhealthyThreshold: 3,
        matcher: '200',
      },
    });

    // Grafana Service
    const grafanaService = new EcsService(this, 'grafana-service', {
      name: 'grafana-service',
      cluster: ecsCluster.id,
      taskDefinition: grafanaTaskDefinition.arn,
      desiredCount: 1,
      launchType: 'FARGATE',
      networkConfiguration: {
        subnets: [privateSubnet.id], // Single-AZ for cost efficiency
        securityGroups: [grafanaSecurityGroup.id],
        assignPublicIp: false,
      },
      loadBalancer: [
        {
          targetGroupArn: grafanaTargetGroup.arn,
          containerName: 'grafana',
          containerPort: 3000,
        },
      ],
      dependsOn: [grafanaMountTarget],
      tags: { Name: 'grafana-service' },
    });

    // ALB Listener Rule for Grafana path
    new LbListenerRule(this, 'grafana-listener-rule', {
      listenerArn: albHttpListener.arn,
      priority: 40,
      action: [
        {
          type: 'forward',
          targetGroupArn: grafanaTargetGroup.arn,
        },
      ],
      condition: [
        {
          pathPattern: {
            values: ['/grafana', '/grafana/*'],
          },
        },
      ],
    });

    // Backup infrastructure
    const backupBucket = new S3Bucket(this, 'grafana-backup-bucket', {
      bucket: 'prod-e-grafana-backups',
      versioning: { enabled: true },
      tags: { Name: 'grafana-backup-bucket' },
    });

    const backupRole = new IamRole(this, 'grafana-backup-role', {
      assumeRolePolicy: JSON.stringify({
        Version: '2012-10-17',
        Statement: [
          {
            Effect: 'Allow',
            Principal: { Service: 'lambda.amazonaws.com' },
            Action: 'sts:AssumeRole',
          },
        ],
      }),
      managedPolicyArns: [
        'arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole',
        'arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole',
      ],
      tags: { Name: 'grafana-backup-role' },
    });

    new IamRolePolicy(this, 'grafana-backup-policy', {
      role: backupRole.id,
      policy: JSON.stringify({
        Version: '2012-10-17',
        Statement: [
          { Effect: 'Allow', Action: ['s3:PutObject'], Resource: `${backupBucket.arn}/*` },
          {
            Effect: 'Allow',
            Action: ['elasticfilesystem:ClientMount', 'elasticfilesystem:ClientWrite'],
            Resource: grafanaFileSystem.arn,
          },
        ],
      }),
    });

    // Lambda backup function - simplified for now, will use inline code
    const backupLambda = new LambdaFunction(this, 'grafana-backup-lambda', {
      functionName: 'grafana-backup',
      runtime: 'nodejs16.x',
      handler: 'index.handler',
      role: backupRole.arn,
      sourceCodeHash: 'lambda-backup-code-hash',
      filename: '/tmp/lambda-code.zip', // This is a placeholder, we'll need to create this file separately
      timeout: 300,
      fileSystemConfig: { arn: grafanaAccessPoint.arn, localMountPath: '/mnt/efs' },
      vpcConfig: {
        subnetIds: [privateSubnet.id],
        securityGroupIds: [grafanaSecurityGroup.id],
      },
      tags: { Name: 'grafana-backup-lambda' },
    });

    const backupSchedule = new CloudwatchEventRule(this, 'grafana-backup-schedule', {
      name: 'grafana-backup-schedule',
      scheduleExpression: 'rate(1 day)',
      tags: { Name: 'grafana-backup-schedule' },
    });

    new LambdaPermission(this, 'grafana-backup-permission', {
      action: 'lambda:InvokeFunction',
      functionName: backupLambda.functionName,
      principal: 'events.amazonaws.com',
      sourceArn: backupSchedule.arn,
    });

    // Outputs for Grafana
    new TerraformOutput(this, 'grafana-url', {
      value: `http://${alb.dnsName}/grafana`,
    });
    new TerraformOutput(this, 'grafana-service-name', {
      value: grafanaService.name,
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
      value: dbInstance.endpoint,
      description: 'The connection endpoint for the RDS instance',
    });

    // Output the RDS port
    new TerraformOutput(this, 'rds-port', {
      value: dbInstance.port.toString(),
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

    // Output the ECR repository URL
    new TerraformOutput(this, 'ecr-repository-url', {
      value: ecrRepositoryUrl,
      description: 'The URL of the ECR repository',
    });
  }
}

const app = new App();
new MyStack(app, 'prod-e');
app.synth();
