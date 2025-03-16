import { Construct } from 'constructs';
import { Eip } from '../.gen/providers/aws/eip';
import { InternetGateway } from '../.gen/providers/aws/internet-gateway';
import { NatGateway } from '../.gen/providers/aws/nat-gateway';
import { AwsProvider } from '../.gen/providers/aws/provider';
import { RouteTable } from '../.gen/providers/aws/route-table';
import { RouteTableAssociation } from '../.gen/providers/aws/route-table-association';
import { Subnet } from '../.gen/providers/aws/subnet';
import { Vpc } from '../.gen/providers/aws/vpc';

export class Networking extends Construct {
  public vpc: Vpc;
  public publicSubnets: Subnet[];
  public privateSubnets: Subnet[];
  public internetGateway: InternetGateway;
  public natGateway: NatGateway;

  constructor(scope: Construct, id: string) {
    super(scope, id);

    const provider = new AwsProvider(this, 'aws', { region: 'us-west-2' });

    // VPC
    this.vpc = new Vpc(this, 'vpc', {
      cidrBlock: '10.0.0.0/16',
      enableDnsHostnames: true,
      enableDnsSupport: true,
      tags: { Name: 'prod-e-vpc' },
    });

    // Public Subnets (multi-AZ)
    this.publicSubnets = ['us-west-2a', 'us-west-2b'].map(
      (az, i) =>
        new Subnet(this, `public-subnet-${i}`, {
          vpcId: this.vpc.id,
          cidrBlock: `10.0.${i + 1}.0/24`,
          availabilityZone: az,
          mapPublicIpOnLaunch: true,
          tags: { Name: `prod-e-public-${az}` },
        })
    );

    // Private Subnets (multi-AZ)
    this.privateSubnets = ['us-west-2a', 'us-west-2b'].map(
      (az, i) =>
        new Subnet(this, `private-subnet-${i}`, {
          vpcId: this.vpc.id,
          cidrBlock: `10.0.${i + 10}.0/24`,
          availabilityZone: az,
          tags: { Name: `prod-e-private-${az}` },
        })
    );

    // Internet Gateway
    this.internetGateway = new InternetGateway(this, 'igw', {
      vpcId: this.vpc.id,
      tags: { Name: 'prod-e-igw' },
    });

    // NAT Gateway (in first public subnet)
    this.natGateway = new NatGateway(this, 'nat', {
      allocationId: new Eip(this, 'nat-eip', { vpc: true }).id,
      subnetId: this.publicSubnets[0].id,
      tags: { Name: 'prod-e-nat' },
    });

    // Route Tables (simplified)
    const publicRt = new RouteTable(this, 'public-rt', {
      vpcId: this.vpc.id,
      route: [{ cidrBlock: '0.0.0.0/0', gatewayId: this.internetGateway.id }],
      tags: { Name: 'prod-e-public-rt' },
    });

    this.publicSubnets.forEach(
      (subnet, i) =>
        new RouteTableAssociation(this, `public-rta-${i}`, {
          subnetId: subnet.id,
          routeTableId: publicRt.id,
        })
    );
  }
}
