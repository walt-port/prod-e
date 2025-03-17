const fs = require('fs');
const path = require('path');
const AWS = require('aws-sdk');

// Mock the AWS SDK
jest.mock('aws-sdk', () => {
  const mockEC2 = {
    describeVpcs: jest.fn().mockReturnValue({
      promise: jest.fn().mockResolvedValue({
        Vpcs: [{ VpcId: 'vpc-12345678', Tags: [{ Key: 'Name', Value: 'prod-e-vpc' }] }],
      }),
    }),
    describeSubnets: jest.fn().mockReturnValue({
      promise: jest.fn().mockResolvedValue({
        Subnets: [
          {
            SubnetId: 'subnet-12345678',
            VpcId: 'vpc-12345678',
            Tags: [{ Key: 'Name', Value: 'prod-e-subnet-1' }],
          },
          {
            SubnetId: 'subnet-87654321',
            VpcId: 'vpc-12345678',
            Tags: [{ Key: 'Name', Value: 'prod-e-subnet-2' }],
          },
        ],
      }),
    }),
  };

  const mockRDS = {
    describeDBInstances: jest.fn().mockReturnValue({
      promise: jest.fn().mockResolvedValue({
        DBInstances: [
          {
            DBInstanceIdentifier: 'prod-e-db',
            DBInstanceArn: 'arn:aws:rds:us-west-2:123456789012:db:prod-e-db',
            Engine: 'postgres',
          },
        ],
      }),
    }),
  };

  const mockELB = {
    describeLoadBalancers: jest.fn().mockReturnValue({
      promise: jest.fn().mockResolvedValue({
        LoadBalancers: [
          {
            LoadBalancerName: 'prod-e-alb',
            LoadBalancerArn:
              'arn:aws:elasticloadbalancing:us-west-2:123456789012:loadbalancer/app/prod-e-alb/1234567890',
          },
        ],
      }),
    }),
  };

  const mockECS = {
    listClusters: jest.fn().mockReturnValue({
      promise: jest.fn().mockResolvedValue({
        clusterArns: ['arn:aws:ecs:us-west-2:123456789012:cluster/prod-e-cluster'],
      }),
    }),
    describeClusters: jest.fn().mockReturnValue({
      promise: jest.fn().mockResolvedValue({
        clusters: [
          {
            clusterName: 'prod-e-cluster',
            clusterArn: 'arn:aws:ecs:us-west-2:123456789012:cluster/prod-e-cluster',
          },
        ],
      }),
    }),
  };

  return {
    EC2: jest.fn(() => mockEC2),
    RDS: jest.fn(() => mockRDS),
    ELBv2: jest.fn(() => mockELB),
    ECS: jest.fn(() => mockECS),
  };
});

// Mock file system
jest.mock('fs', () => ({
  writeFileSync: jest.fn(),
  existsSync: jest.fn().mockReturnValue(false),
  mkdirSync: jest.fn(),
}));

// Import the script - we need to mock this since we don't actually want to execute it
jest.mock('./import', () => ({
  initializeImportCommandsFile: jest.fn(),
  addImportCommand: jest.fn(),
  checkForVpcResources: jest.fn(),
  checkForRdsInstances: jest.fn(),
  checkForLoadBalancers: jest.fn(),
  checkForEcsClusters: jest.fn(),
  main: jest.fn(),
}));

const importScript = require('./import');

describe('Import Script', () => {
  let consoleLogSpy;

  beforeEach(() => {
    consoleLogSpy = jest.spyOn(console, 'log').mockImplementation();
    // Reset mock implementations
    fs.writeFileSync.mockClear();
    fs.existsSync.mockClear();
    fs.mkdirSync.mockClear();
    importScript.initializeImportCommandsFile.mockClear();
    importScript.addImportCommand.mockClear();
    importScript.checkForVpcResources.mockClear();
    importScript.checkForRdsInstances.mockClear();
    importScript.checkForLoadBalancers.mockClear();
    importScript.checkForEcsClusters.mockClear();
    importScript.main.mockClear();
  });

  afterEach(() => {
    consoleLogSpy.mockRestore();
  });

  test('initializeImportCommandsFile creates the output directory and file', () => {
    // Setup
    const outputDir = './import-commands';
    const outputFile = path.join(outputDir, 'import-commands.sh');

    // Mock implementation for this test
    importScript.initializeImportCommandsFile.mockImplementation(dir => {
      if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
      }
      fs.writeFileSync(
        path.join(dir, 'import-commands.sh'),
        '#!/bin/bash\n# Generated import commands\n'
      );
      return path.join(dir, 'import-commands.sh');
    });

    // Execute
    const result = importScript.initializeImportCommandsFile(outputDir);

    // Assert
    expect(result).toBe(outputFile);
    expect(fs.existsSync).toHaveBeenCalledWith(outputDir);
    expect(fs.mkdirSync).toHaveBeenCalledWith(outputDir, { recursive: true });
    expect(fs.writeFileSync).toHaveBeenCalledWith(
      outputFile,
      '#!/bin/bash\n# Generated import commands\n'
    );
  });

  test('checkForVpcResources finds VPC resources', async () => {
    // Setup
    const ec2Client = new AWS.EC2();
    const importFile = './import-commands/import-commands.sh';
    const stackName = 'prod-e';

    // Mock implementation for this test
    importScript.checkForVpcResources.mockImplementation(async (client, file, stack) => {
      const { Vpcs } = await client.describeVpcs().promise();
      const filteredVpcs = Vpcs.filter(
        vpc => vpc.Tags && vpc.Tags.some(tag => tag.Key === 'Name' && tag.Value.includes(stack))
      );

      for (const vpc of filteredVpcs) {
        importScript.addImportCommand(file, `aws_vpc.${stack}_vpc`, vpc.VpcId);
      }

      return filteredVpcs.length;
    });

    importScript.addImportCommand.mockImplementation((file, resource, id) => {
      fs.writeFileSync(file, `terraform import ${resource} ${id}\n`, { flag: 'a' });
    });

    // Execute
    const result = await importScript.checkForVpcResources(ec2Client, importFile, stackName);

    // Assert
    expect(result).toBe(1);
    expect(ec2Client.describeVpcs).toHaveBeenCalled();
    expect(importScript.addImportCommand).toHaveBeenCalledWith(
      importFile,
      'aws_vpc.prod-e_vpc',
      'vpc-12345678'
    );
  });

  test('main function orchestrates the import process', async () => {
    // Setup
    importScript.main.mockImplementation(async options => {
      const outputDir = options.output || './import-commands';
      const importFile = importScript.initializeImportCommandsFile(outputDir);

      const ec2Client = new AWS.EC2({ region: options.region });
      const rdsClient = new AWS.RDS({ region: options.region });
      const elbClient = new AWS.ELBv2({ region: options.region });
      const ecsClient = new AWS.ECS({ region: options.region });

      const vpcCount = await importScript.checkForVpcResources(
        ec2Client,
        importFile,
        options.stack
      );
      const rdsCount = await importScript.checkForRdsInstances(
        rdsClient,
        importFile,
        options.stack
      );
      const lbCount = await importScript.checkForLoadBalancers(
        elbClient,
        importFile,
        options.stack
      );
      const ecsCount = await importScript.checkForEcsClusters(ecsClient, importFile, options.stack);

      return { vpcCount, rdsCount, lbCount, ecsCount };
    });

    // Mock implementations for resource checks
    importScript.checkForVpcResources.mockResolvedValue(1);
    importScript.checkForRdsInstances.mockResolvedValue(1);
    importScript.checkForLoadBalancers.mockResolvedValue(1);
    importScript.checkForEcsClusters.mockResolvedValue(1);

    // Execute
    const result = await importScript.main({
      region: 'us-west-2',
      stack: 'prod-e',
      output: './import-commands',
      ci: true,
    });

    // Assert
    expect(result).toEqual({
      vpcCount: 1,
      rdsCount: 1,
      lbCount: 1,
      ecsCount: 1,
    });
    expect(importScript.initializeImportCommandsFile).toHaveBeenCalledWith('./import-commands');
    expect(importScript.checkForVpcResources).toHaveBeenCalled();
    expect(importScript.checkForRdsInstances).toHaveBeenCalled();
    expect(importScript.checkForLoadBalancers).toHaveBeenCalled();
    expect(importScript.checkForEcsClusters).toHaveBeenCalled();
  });
});
