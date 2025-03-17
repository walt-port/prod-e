#!/usr/bin/env node

/**
 * Resource Import Script for AWS
 *
 * This script detects existing AWS resources and generates import commands
 * for Terraform/CDKTF to import them into the state.
 */

const { Command } = require('commander');
const AWS = require('aws-sdk');
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// Configure command line options
const program = new Command();
program
  .option('--ci', 'Run in CI mode (non-interactive)')
  .option('--auto-yes', 'Auto approve all prompts (same as --ci)')
  .option('--region <region>', 'AWS region to search for resources', 'us-west-2')
  .option('--stack <name>', 'Stack name prefix for resources')
  .option('--output <directory>', 'Directory to output import commands', './import-commands')
  .parse(process.argv);

const options = program.opts();
const CI_MODE = options.ci || options.autoYes;
const AWS_REGION = options.region;
const STACK_NAME = options.stack;
const OUTPUT_DIR = options.output;

// Ensure the output directory exists
if (!fs.existsSync(OUTPUT_DIR)) {
  fs.mkdirSync(OUTPUT_DIR, { recursive: true });
}

// Configure AWS
AWS.config.update({ region: AWS_REGION });

// Initialize AWS clients
const ec2 = new AWS.EC2();
const elbv2 = new AWS.ELBv2();
const ecs = new AWS.ECS();
const rds = new AWS.RDS();
const s3 = new AWS.S3();
const lambda = new AWS.Lambda();

// File to store import commands
const IMPORT_COMMANDS_FILE = path.join(OUTPUT_DIR, 'import-commands.sh');

/**
 * Initialize the import commands file
 * @param {string} outputDir - Directory to store the import commands
 * @returns {string} - Path to the created file
 */
function initializeImportCommandsFile(outputDir) {
  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
  }

  const filePath = path.join(outputDir, 'import-commands.sh');
  fs.writeFileSync(filePath, '#!/bin/bash\n# Generated import commands\n');

  // Make the file executable
  fs.chmodSync(filePath, '755');

  console.log(`Initialized import commands file at ${filePath}`);
  return filePath;
}

/**
 * Add an import command to the file
 * @param {string} filePath - Path to the import commands file
 * @param {string} resourceType - Terraform resource type and name
 * @param {string} resourceId - Resource ID to import
 */
function addImportCommand(filePath, resourceType, resourceId) {
  fs.writeFileSync(filePath, `terraform import ${resourceType} ${resourceId}\n`, { flag: 'a' });
  console.log(`Added import command for ${resourceType}: ${resourceId}`);
}

/**
 * Check for VPC resources and generate import commands
 * @param {AWS.EC2} ec2Client - EC2 client
 * @param {string} importFile - Path to the import commands file
 * @param {string} stackName - Stack name prefix
 * @returns {Promise<number>} - Number of resources found
 */
async function checkForVpcResources(ec2Client, importFile, stackName) {
  console.log(`Checking for VPC resources with prefix ${stackName}...`);
  try {
    // Check for VPCs
    const { Vpcs } = await ec2Client.describeVpcs().promise();
    const filteredVpcs = Vpcs.filter(vpc =>
      vpc.Tags && vpc.Tags.some(tag => tag.Key === 'Name' && tag.Value.includes(stackName))
    );

    console.log(`Found ${filteredVpcs.length} VPCs matching ${stackName}`);

    for (const vpc of filteredVpcs) {
      addImportCommand(importFile, `aws_vpc.${stackName}_vpc`, vpc.VpcId);

      // Check for subnets in this VPC
      const { Subnets } = await ec2Client.describeSubnets({
        Filters: [{ Name: 'vpc-id', Values: [vpc.VpcId] }]
      }).promise();

      console.log(`Found ${Subnets.length} subnets in VPC ${vpc.VpcId}`);

      for (const subnet of Subnets) {
        const subnetName = subnet.Tags?.find(tag => tag.Key === 'Name')?.Value || subnet.SubnetId;
        const resourceName = subnetName.replace(/-/g, '_').toLowerCase();
        addImportCommand(importFile, `aws_subnet.${resourceName}`, subnet.SubnetId);
      }
    }

    return filteredVpcs.length;
  } catch (error) {
    console.error(`Error checking for VPC resources: ${error.message}`);
    return 0;
  }
}

/**
 * Check for RDS instances and generate import commands
 * @param {AWS.RDS} rdsClient - RDS client
 * @param {string} importFile - Path to the import commands file
 * @param {string} stackName - Stack name prefix
 * @returns {Promise<number>} - Number of resources found
 */
async function checkForRdsInstances(rdsClient, importFile, stackName) {
  console.log(`Checking for RDS instances with prefix ${stackName}...`);
  try {
    const { DBInstances } = await rdsClient.describeDBInstances().promise();
    const filteredInstances = DBInstances.filter(db =>
      db.DBInstanceIdentifier.includes(stackName)
    );

    console.log(`Found ${filteredInstances.length} RDS instances matching ${stackName}`);

    for (const db of filteredInstances) {
      const resourceName = db.DBInstanceIdentifier.replace(/-/g, '_').toLowerCase();
      addImportCommand(importFile, `aws_db_instance.${resourceName}`, db.DBInstanceArn);
    }

    return filteredInstances.length;
  } catch (error) {
    console.error(`Error checking for RDS instances: ${error.message}`);
    return 0;
  }
}

/**
 * Check for load balancers and generate import commands
 * @param {AWS.ELBv2} elbClient - ELBv2 client
 * @param {string} importFile - Path to the import commands file
 * @param {string} stackName - Stack name prefix
 * @returns {Promise<number>} - Number of resources found
 */
async function checkForLoadBalancers(elbClient, importFile, stackName) {
  console.log(`Checking for load balancers with prefix ${stackName}...`);
  try {
    const { LoadBalancers } = await elbClient.describeLoadBalancers().promise();
    const filteredLBs = LoadBalancers.filter(lb =>
      lb.LoadBalancerName.includes(stackName)
    );

    console.log(`Found ${filteredLBs.length} load balancers matching ${stackName}`);

    for (const lb of filteredLBs) {
      const resourceName = lb.LoadBalancerName.replace(/-/g, '_').toLowerCase();
      addImportCommand(importFile, `aws_lb.${resourceName}`, lb.LoadBalancerArn);

      // Add target groups
      const { TargetGroups } = await elbClient.describeTargetGroups({
        LoadBalancerArn: lb.LoadBalancerArn
      }).promise();

      console.log(`Found ${TargetGroups.length} target groups for load balancer ${lb.LoadBalancerName}`);

      for (const tg of TargetGroups) {
        const tgResourceName = tg.TargetGroupName.replace(/-/g, '_').toLowerCase();
        addImportCommand(importFile, `aws_lb_target_group.${tgResourceName}`, tg.TargetGroupArn);
      }
    }

    return filteredLBs.length;
  } catch (error) {
    console.error(`Error checking for load balancers: ${error.message}`);
    return 0;
  }
}

/**
 * Check for ECS clusters and generate import commands
 * @param {AWS.ECS} ecsClient - ECS client
 * @param {string} importFile - Path to the import commands file
 * @param {string} stackName - Stack name prefix
 * @returns {Promise<number>} - Number of resources found
 */
async function checkForEcsClusters(ecsClient, importFile, stackName) {
  console.log(`Checking for ECS clusters with prefix ${stackName}...`);
  try {
    const { clusterArns } = await ecsClient.listClusters().promise();
    if (!clusterArns || clusterArns.length === 0) {
      console.log('No ECS clusters found');
      return 0;
    }

    const { clusters } = await ecsClient.describeClusters({ clusters: clusterArns }).promise();
    const filteredClusters = clusters.filter(cluster =>
      cluster.clusterName.includes(stackName)
    );

    console.log(`Found ${filteredClusters.length} ECS clusters matching ${stackName}`);

    for (const cluster of filteredClusters) {
      const resourceName = cluster.clusterName.replace(/-/g, '_').toLowerCase();
      addImportCommand(importFile, `aws_ecs_cluster.${resourceName}`, cluster.clusterArn);

      // Add services in this cluster
      const { serviceArns } = await ecsClient.listServices({
        cluster: cluster.clusterArn
      }).promise();

      if (serviceArns && serviceArns.length > 0) {
        const { services } = await ecsClient.describeServices({
          cluster: cluster.clusterArn,
          services: serviceArns
        }).promise();

        console.log(`Found ${services.length} services in cluster ${cluster.clusterName}`);

        for (const service of services) {
          const serviceResourceName = service.serviceName.replace(/-/g, '_').toLowerCase();
          addImportCommand(importFile, `aws_ecs_service.${serviceResourceName}`, service.serviceArn);
        }
      }
    }

    return filteredClusters.length;
  } catch (error) {
    console.error(`Error checking for ECS clusters: ${error.message}`);
    return 0;
  }
}

/**
 * Execute import commands
 */
async function executeImportCommands() {
  if (CI_MODE) {
    console.log('Running import commands in CI mode...');
    try {
      execSync(`bash ${IMPORT_COMMANDS_FILE}`, { stdio: 'inherit' });
      console.log('Import completed successfully');
    } catch (error) {
      console.error('Error executing import commands:', error);
      process.exit(1);
    }
  } else {
    console.log(`\nImport commands have been generated in: ${IMPORT_COMMANDS_FILE}`);
    console.log('Review the file and execute it manually if the commands look correct.');
    console.log('To execute the commands, run:');
    console.log(`bash ${IMPORT_COMMANDS_FILE}`);
  }
}

/**
 * Main function
 * @param {Object} opts - Command line options
 * @returns {Promise<Object>} - Summary of resources found
 */
async function main(opts) {
  const optsToUse = opts || options;

  if (!optsToUse.stack) {
    console.error('Error: Stack name is required. Use --stack <name>');
    process.exit(1);
  }

  console.log(`Starting import process for stack: ${optsToUse.stack}`);
  console.log(`AWS Region: ${optsToUse.region}`);
  console.log(`Output directory: ${optsToUse.output}`);
  console.log(`CI mode: ${optsToUse.ci ? 'enabled' : 'disabled'}`);

  // Initialize the import commands file
  const importFile = initializeImportCommandsFile(optsToUse.output);

  // Initialize AWS clients
  const ec2Client = new AWS.EC2({ region: optsToUse.region });
  const rdsClient = new AWS.RDS({ region: optsToUse.region });
  const elbClient = new AWS.ELBv2({ region: optsToUse.region });
  const ecsClient = new AWS.ECS({ region: optsToUse.region });

  // Check for resources
  const vpcCount = await checkForVpcResources(ec2Client, importFile, optsToUse.stack);
  const rdsCount = await checkForRdsInstances(rdsClient, importFile, optsToUse.stack);
  const lbCount = await checkForLoadBalancers(elbClient, importFile, optsToUse.stack);
  const ecsCount = await checkForEcsClusters(ecsClient, importFile, optsToUse.stack);

  console.log('\nImport process complete!');
  console.log('-------------------------');
  console.log(`Found ${vpcCount} VPC resources`);
  console.log(`Found ${rdsCount} RDS instances`);
  console.log(`Found ${lbCount} load balancers`);
  console.log(`Found ${ecsCount} ECS clusters`);
  console.log(`Import commands written to: ${importFile}`);
  console.log('\nTo import these resources, run:');
  console.log(`$ bash ${importFile}`);

  return { vpcCount, rdsCount, lbCount, ecsCount };
}

// Run the script if not being imported as a module
if (require.main === module) {
  main().catch(err => {
    console.error('Error:', err);
    process.exit(1);
  });
}

// Export functions for testing
module.exports = {
  initializeImportCommandsFile,
  addImportCommand,
  checkForVpcResources,
  checkForRdsInstances,
  checkForLoadBalancers,
  checkForEcsClusters,
  main
};
