#!/usr/bin/env python3
"""
Infrastructure Teardown Script for prod-e

This script provides a way to tear down the AWS infrastructure created for the prod-e project.
It uses boto3 to identify and delete resources in the correct order.

Usage:
    python teardown.py [--dry-run] [--region REGION] [--project-tag PROJECT_TAG]

Options:
    --dry-run       List resources that would be deleted but don't actually delete them
    --region        AWS region where resources are deployed (default: us-west-2)
    --project-tag   Value of the Project tag to identify resources (default: prod-e)
"""

import argparse
import boto3
import sys
import time
from botocore.exceptions import ClientError


def parse_args():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description='Tear down prod-e AWS infrastructure')
    parser.add_argument('--dry-run', action='store_true', help='List resources without deleting them')
    parser.add_argument('--region', default='us-west-2', help='AWS region (default: us-west-2)')
    parser.add_argument('--project-tag', default='prod-e', help='Project tag value (default: prod-e)')
    return parser.parse_args()


def confirm_deletion(dry_run):
    """Ask for user confirmation before proceeding with deletion."""
    if dry_run:
        return True

    response = input("\nAre you sure you want to delete these resources? This cannot be undone. (yes/no): ")
    return response.lower() == 'yes'


def delete_ecs_resources(session, region, project_tag, dry_run):
    """Delete ECS resources."""
    ecs_client = session.client('ecs', region_name=region)

    # Find ECS services with the project tag
    print("\nSearching for ECS services...")
    clusters = ecs_client.list_clusters()['clusterArns']

    for cluster_arn in clusters:
        try:
            # Get cluster tags
            cluster_tags = ecs_client.list_tags_for_resource(resourceArn=cluster_arn)['tags']

            is_project_resource = False
            for tag in cluster_tags:
                if tag['key'] == 'Project' and tag['value'] == project_tag:
                    is_project_resource = True
                    break

            if not is_project_resource:
                continue

            # Get cluster name from ARN
            cluster_name = cluster_arn.split('/')[-1]
            print(f"Found cluster: {cluster_name}")

            # List services in the cluster
            services = ecs_client.list_services(cluster=cluster_name)['serviceArns']

            # Delete each service
            for service_arn in services:
                service_name = service_arn.split('/')[-1]
                print(f"  Found service: {service_name}")

                if not dry_run:
                    print(f"  Scaling down service {service_name}...")
                    ecs_client.update_service(
                        cluster=cluster_name,
                        service=service_name,
                        desiredCount=0
                    )

                    print(f"  Deleting service {service_name}...")
                    ecs_client.delete_service(
                        cluster=cluster_name,
                        service=service_name,
                        force=True
                    )

            # Wait for services to be deleted
            if not dry_run and services:
                print(f"  Waiting for services to be deleted in cluster {cluster_name}...")
                time.sleep(30)  # Give some time for services to start deleting

            # Delete the cluster
            if not dry_run:
                print(f"Deleting cluster {cluster_name}...")
                ecs_client.delete_cluster(cluster=cluster_name)
        except ClientError as e:
            print(f"Error processing cluster {cluster_arn}: {e}")

    # Find task definitions
    print("\nSearching for ECS task definitions...")
    task_defs = ecs_client.list_task_definitions()['taskDefinitionArns']

    for task_def_arn in task_defs:
        # We can't easily filter task definitions by tag, so we'll check if the task family contains our project name
        family = task_def_arn.split('/')[-2]
        if project_tag.lower() in family.lower():
            print(f"Found task definition: {task_def_arn}")
            if not dry_run:
                print(f"Deregistering task definition {task_def_arn}...")
                ecs_client.deregister_task_definition(taskDefinition=task_def_arn)


def delete_alb_resources(session, region, project_tag, dry_run):
    """Delete ALB resources."""
    elb_client = session.client('elbv2', region_name=region)

    # Find load balancers with the project tag
    print("\nSearching for load balancers...")
    load_balancers = elb_client.describe_load_balancers()['LoadBalancers']

    for lb in load_balancers:
        lb_arn = lb['LoadBalancerArn']

        # Get load balancer tags
        lb_tags = elb_client.describe_tags(ResourceArns=[lb_arn])['TagDescriptions'][0]['Tags']

        is_project_resource = False
        for tag in lb_tags:
            if tag['Key'] == 'Project' and tag['Value'] == project_tag:
                is_project_resource = True
                break

        if not is_project_resource:
            continue

        print(f"Found load balancer: {lb['LoadBalancerName']} ({lb_arn})")

        # Find and delete listener rules
        listeners = elb_client.describe_listeners(LoadBalancerArn=lb_arn)['Listeners']
        for listener in listeners:
            listener_arn = listener['ListenerArn']
            print(f"  Found listener: {listener_arn}")

            try:
                rules = elb_client.describe_rules(ListenerArn=listener_arn)['Rules']

                # Delete non-default rules first
                for rule in rules:
                    if not rule['IsDefault']:
                        print(f"    Found rule: {rule['RuleArn']}")
                        if not dry_run:
                            print(f"    Deleting rule {rule['RuleArn']}...")
                            elb_client.delete_rule(RuleArn=rule['RuleArn'])
            except ClientError:
                print(f"    Error getting rules for listener {listener_arn}")

            # Delete the listener
            if not dry_run:
                print(f"  Deleting listener {listener_arn}...")
                elb_client.delete_listener(ListenerArn=listener_arn)

        # Find target groups
        target_groups = elb_client.describe_target_groups(LoadBalancerArn=lb_arn)['TargetGroups']

        # Delete the load balancer
        if not dry_run:
            print(f"Deleting load balancer {lb['LoadBalancerName']}...")
            elb_client.delete_load_balancer(LoadBalancerArn=lb_arn)
            print(f"Waiting for load balancer {lb['LoadBalancerName']} to be deleted...")
            waiter = elb_client.get_waiter('load_balancers_deleted')
            waiter.wait(LoadBalancerArns=[lb_arn])

        # Delete target groups after the load balancer is deleted
        for tg in target_groups:
            print(f"Found target group: {tg['TargetGroupName']} ({tg['TargetGroupArn']})")
            if not dry_run:
                print(f"Deleting target group {tg['TargetGroupName']}...")
                elb_client.delete_target_group(TargetGroupArn=tg['TargetGroupArn'])


def delete_rds_resources(session, region, project_tag, dry_run):
    """Delete RDS resources."""
    rds_client = session.client('rds', region_name=region)

    # Find RDS instances with the project tag
    print("\nSearching for RDS instances...")

    try:
        db_instances = rds_client.describe_db_instances()['DBInstances']

        for db in db_instances:
            db_instance_arn = db['DBInstanceArn']

            # Get DB instance tags
            try:
                db_tags = rds_client.list_tags_for_resource(ResourceName=db_instance_arn)['TagList']

                is_project_resource = False
                for tag in db_tags:
                    if tag['Key'] == 'Project' and tag['Value'] == project_tag:
                        is_project_resource = True
                        break

                if not is_project_resource:
                    continue

                print(f"Found DB instance: {db['DBInstanceIdentifier']}")
                if not dry_run:
                    print(f"Deleting DB instance {db['DBInstanceIdentifier']}...")
                    rds_client.delete_db_instance(
                        DBInstanceIdentifier=db['DBInstanceIdentifier'],
                        SkipFinalSnapshot=True,
                        DeleteAutomatedBackups=True
                    )
            except ClientError as e:
                print(f"Error getting tags for DB instance {db_instance_arn}: {e}")

        # Find and delete DB subnet groups
        db_subnet_groups = rds_client.describe_db_subnet_groups()['DBSubnetGroups']

        for subnet_group in db_subnet_groups:
            # Check if the subnet group name contains our project tag
            if project_tag.lower() in subnet_group['DBSubnetGroupName'].lower():
                print(f"Found DB subnet group: {subnet_group['DBSubnetGroupName']}")
                if not dry_run:
                    print(f"Deleting DB subnet group {subnet_group['DBSubnetGroupName']}...")
                    try:
                        rds_client.delete_db_subnet_group(
                            DBSubnetGroupName=subnet_group['DBSubnetGroupName']
                        )
                    except ClientError as e:
                        print(f"Error deleting DB subnet group {subnet_group['DBSubnetGroupName']}: {e}")
    except ClientError as e:
        print(f"Error accessing RDS resources: {e}")


def delete_vpc_resources(session, region, project_tag, dry_run):
    """Delete VPC resources."""
    ec2_client = session.client('ec2', region_name=region)

    # Find VPCs with the project tag
    print("\nSearching for VPCs...")

    response = ec2_client.describe_vpcs(
        Filters=[
            {
                'Name': f'tag:Project',
                'Values': [project_tag]
            }
        ]
    )

    vpcs = response.get('Vpcs', [])

    for vpc in vpcs:
        vpc_id = vpc['VpcId']
        print(f"Found VPC: {vpc_id}")

        # Find and delete security groups in the VPC
        print(f"Searching for security groups in VPC {vpc_id}...")
        sg_response = ec2_client.describe_security_groups(
            Filters=[
                {
                    'Name': 'vpc-id',
                    'Values': [vpc_id]
                }
            ]
        )

        # Delete all non-default security groups
        for sg in sg_response['SecurityGroups']:
            if sg['GroupName'] != 'default':
                print(f"Found security group: {sg['GroupId']} ({sg['GroupName']})")
                if not dry_run:
                    try:
                        # First, remove all ingress/egress rules
                        print(f"Removing rules from security group {sg['GroupId']}...")
                        ec2_client.revoke_security_group_ingress(
                            GroupId=sg['GroupId'],
                            IpPermissions=sg['IpPermissions']
                        ) if sg['IpPermissions'] else None

                        ec2_client.revoke_security_group_egress(
                            GroupId=sg['GroupId'],
                            IpPermissions=sg['IpPermissionsEgress']
                        ) if sg['IpPermissionsEgress'] else None

                        print(f"Deleting security group {sg['GroupId']}...")
                        ec2_client.delete_security_group(GroupId=sg['GroupId'])
                    except ClientError as e:
                        print(f"Error processing security group {sg['GroupId']}: {e}")

        # Find and delete all route tables
        print(f"Searching for route tables in VPC {vpc_id}...")
        rt_response = ec2_client.describe_route_tables(
            Filters=[
                {
                    'Name': 'vpc-id',
                    'Values': [vpc_id]
                }
            ]
        )

        for rt in rt_response['RouteTables']:
            # Skip the main route table, we'll delete it with the VPC
            if any(assoc.get('Main', False) for assoc in rt.get('Associations', [])):
                print(f"Skipping main route table: {rt['RouteTableId']}")
                continue

            print(f"Found route table: {rt['RouteTableId']}")

            # Delete route table associations first
            for assoc in rt.get('Associations', []):
                if not assoc.get('Main', False):
                    print(f"  Found route table association: {assoc['RouteTableAssociationId']}")
                    if not dry_run:
                        print(f"  Deleting route table association {assoc['RouteTableAssociationId']}...")
                        ec2_client.disassociate_route_table(
                            AssociationId=assoc['RouteTableAssociationId']
                        )

            # Delete the route table
            if not dry_run:
                print(f"Deleting route table {rt['RouteTableId']}...")
                ec2_client.delete_route_table(RouteTableId=rt['RouteTableId'])

        # Find and delete internet gateways
        print(f"Searching for internet gateways attached to VPC {vpc_id}...")
        igw_response = ec2_client.describe_internet_gateways(
            Filters=[
                {
                    'Name': 'attachment.vpc-id',
                    'Values': [vpc_id]
                }
            ]
        )

        for igw in igw_response['InternetGateways']:
            print(f"Found internet gateway: {igw['InternetGatewayId']}")
            if not dry_run:
                print(f"Detaching internet gateway {igw['InternetGatewayId']} from VPC {vpc_id}...")
                ec2_client.detach_internet_gateway(
                    InternetGatewayId=igw['InternetGatewayId'],
                    VpcId=vpc_id
                )

                print(f"Deleting internet gateway {igw['InternetGatewayId']}...")
                ec2_client.delete_internet_gateway(InternetGatewayId=igw['InternetGatewayId'])

        # Find and delete subnets
        print(f"Searching for subnets in VPC {vpc_id}...")
        subnet_response = ec2_client.describe_subnets(
            Filters=[
                {
                    'Name': 'vpc-id',
                    'Values': [vpc_id]
                }
            ]
        )

        for subnet in subnet_response['Subnets']:
            print(f"Found subnet: {subnet['SubnetId']}")
            if not dry_run:
                print(f"Deleting subnet {subnet['SubnetId']}...")
                ec2_client.delete_subnet(SubnetId=subnet['SubnetId'])

        # Delete the VPC
        if not dry_run:
            print(f"Deleting VPC {vpc_id}...")
            ec2_client.delete_vpc(VpcId=vpc_id)


def delete_iam_resources(session, region, project_tag, dry_run):
    """Delete IAM resources."""
    iam_client = session.client('iam')

    # Find roles with the project tag
    print("\nSearching for IAM roles...")

    roles = iam_client.list_roles()['Roles']
    project_roles = []

    for role in roles:
        role_name = role['RoleName']

        # Check if the role name contains our project tag
        if project_tag.lower() in role_name.lower():
            try:
                role_arn = role['Arn']
                print(f"Found IAM role: {role_name} ({role_arn})")
                project_roles.append(role_name)
            except Exception as e:
                print(f"Error checking IAM role {role_name}: {e}")

    # Delete the roles
    for role_name in project_roles:
        if not dry_run:
            try:
                # First, list and detach all policies
                attached_policies = iam_client.list_attached_role_policies(
                    RoleName=role_name
                )['AttachedPolicies']

                for policy in attached_policies:
                    policy_arn = policy['PolicyArn']
                    print(f"  Detaching policy {policy_arn} from role {role_name}...")
                    iam_client.detach_role_policy(
                        RoleName=role_name,
                        PolicyArn=policy_arn
                    )

                # Delete the role
                print(f"Deleting IAM role {role_name}...")
                iam_client.delete_role(RoleName=role_name)
            except Exception as e:
                print(f"Error deleting IAM role {role_name}: {e}")


def main():
    """Main function."""
    args = parse_args()

    print(f"AWS Region: {args.region}")
    print(f"Project Tag: {args.project_tag}")
    print(f"Dry Run: {'Yes' if args.dry_run else 'No'}")

    if args.dry_run:
        print("\nDRY RUN MODE: Resources will be identified but not deleted")

    session = boto3.Session()

    try:
        # Identify resources in the correct order
        print("\n=== Identifying Resources ===")

        # Delete resources in the correct order (reverse dependency order)
        delete_ecs_resources(session, args.region, args.project_tag, True)
        delete_alb_resources(session, args.region, args.project_tag, True)
        delete_rds_resources(session, args.region, args.project_tag, True)
        delete_vpc_resources(session, args.region, args.project_tag, True)
        delete_iam_resources(session, args.region, args.project_tag, True)

        # Confirm before actual deletion
        if confirm_deletion(args.dry_run):
            print("\n=== Deleting Resources ===")

            # Delete resources in the correct order (reverse dependency order)
            delete_ecs_resources(session, args.region, args.project_tag, args.dry_run)
            delete_alb_resources(session, args.region, args.project_tag, args.dry_run)
            delete_rds_resources(session, args.region, args.project_tag, args.dry_run)
            delete_vpc_resources(session, args.region, args.project_tag, args.dry_run)
            delete_iam_resources(session, args.region, args.project_tag, args.dry_run)

            print("\nTeardown complete!")
        else:
            print("\nTeardown cancelled.")
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
