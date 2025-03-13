import { App, TerraformOutput, TerraformStack } from 'cdktf';
import { Construct } from 'constructs';
import { InternetGateway } from './.gen/providers/aws/internet-gateway';
import { AwsProvider } from './.gen/providers/aws/provider';
import { Route } from './.gen/providers/aws/route';
import { RouteTable } from './.gen/providers/aws/route-table';
import { RouteTableAssociation } from './.gen/providers/aws/route-table-association';
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
  }
}

const app = new App();
new MyStack(app, 'prod-e');
app.synth();
