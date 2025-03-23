import { Construct } from 'constructs';
import { Eip } from '../.gen/providers/aws/eip';
import { InternetGateway } from '../.gen/providers/aws/internet-gateway';
import { NatGateway } from '../.gen/providers/aws/nat-gateway';
import { RouteTable } from '../.gen/providers/aws/route-table';
import { RouteTableAssociation } from '../.gen/providers/aws/route-table-association';
import { SecurityGroup } from '../.gen/providers/aws/security-group';
import { SecurityGroupRule } from '../.gen/providers/aws/security-group-rule';
import { Subnet } from '../.gen/providers/aws/subnet';
import { Vpc } from '../.gen/providers/aws/vpc';

function assertEnvVar(name: string): string {
  const value = process.env[name];
  if (!value) throw new Error(`${name} must be set in .env`);
  return value;
}

export class Networking extends Construct {
  public vpc: Vpc;
  public publicSubnets: Subnet[];
  public privateSubnets: Subnet[];
  public internetGateway: InternetGateway;
  public natGateway: NatGateway;
  public albSecurityGroup: SecurityGroup;

  constructor(scope: Construct, id: string) {
    super(scope, id);

    const projectName = assertEnvVar('PROJECT_NAME');
    const vpcCidr = assertEnvVar('VPC_CIDR');
    const publicSubnetCidrs = assertEnvVar('PUBLIC_SUBNET_CIDRS').split(',');
    const privateSubnetCidrs = assertEnvVar('PRIVATE_SUBNET_CIDRS').split(',');
    const availabilityZones = assertEnvVar('AVAILABILITY_ZONES').split(',');
    const albPort = Number(assertEnvVar('ALB_PORT'));
    const albIngressCidr = assertEnvVar('ALB_INGRESS_CIDR');
    const albEgressCidr = assertEnvVar('ALB_EGRESS_CIDR');

    this.vpc = new Vpc(this, 'vpc', {
      cidrBlock: vpcCidr,
      enableDnsHostnames: true,
      enableDnsSupport: true,
      tags: { Name: `${projectName}-vpc`, Project: projectName },
    });

    this.publicSubnets = publicSubnetCidrs.map((cidr, i) => new Subnet(this, `public-subnet-${i}`, {
      vpcId: this.vpc.id,
      cidrBlock: cidr,
      availabilityZone: availabilityZones[i],
      mapPublicIpOnLaunch: true,
      tags: { Name: `${projectName}-public-${availabilityZones[i]}`, Project: projectName },
    }));

    this.privateSubnets = privateSubnetCidrs.map((cidr, i) => new Subnet(this, `private-subnet-${i}`, {
      vpcId: this.vpc.id,
      cidrBlock: cidr,
      availabilityZone: availabilityZones[i],
      tags: { Name: `${projectName}-private-${availabilityZones[i]}`, Project: projectName },
    }));

    this.internetGateway = new InternetGateway(this, 'igw', {
      vpcId: this.vpc.id,
      tags: { Name: `${projectName}-igw`, Project: projectName },
    });

    this.natGateway = new NatGateway(this, 'nat', {
      allocationId: new Eip(this, 'nat-eip', { vpc: true }).id,
      subnetId: this.publicSubnets[0].id,
      tags: { Name: `${projectName}-nat`, Project: projectName },
    });

    const publicRt = new RouteTable(this, 'public-rt', {
      vpcId: this.vpc.id,
      route: [{ cidrBlock: '0.0.0.0/0', gatewayId: this.internetGateway.id }],
      tags: { Name: `${projectName}-public-rt`, Project: projectName },
    });

    const privateRt = new RouteTable(this, 'private-rt', {
      vpcId: this.vpc.id,
      route: [{ cidrBlock: '0.0.0.0/0', natGatewayId: this.natGateway.id }],
      tags: { Name: `${projectName}-private-rt`, Project: projectName },
    });

    this.publicSubnets.forEach((subnet, i) => new RouteTableAssociation(this, `public-rta-${i}`, {
      subnetId: subnet.id,
      routeTableId: publicRt.id,
    }));

    this.privateSubnets.forEach((subnet, i) => new RouteTableAssociation(this, `private-rta-${i}`, {
      subnetId: subnet.id,
      routeTableId: privateRt.id,
    }));

    this.albSecurityGroup = new SecurityGroup(this, 'alb-security-group', {
      name: `${projectName}-alb-sg`,
      vpcId: this.vpc.id,
      tags: { Name: `${projectName}-alb-sg`, Project: projectName },
    });

    new SecurityGroupRule(this, 'alb-http-inbound', {
      type: 'ingress',
      fromPort: albPort,
      toPort: albPort,
      protocol: 'tcp',
      cidrBlocks: [albIngressCidr],
      securityGroupId: this.albSecurityGroup.id,
      description: 'Allow HTTP traffic',
    });

    new SecurityGroupRule(this, 'alb-all-outbound', {
      type: 'egress',
      fromPort: 0,
      toPort: 0,
      protocol: '-1',
      cidrBlocks: [albEgressCidr],
      securityGroupId: this.albSecurityGroup.id,
      description: 'Allow all outbound traffic',
    });
  }
}
