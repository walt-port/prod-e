# Infrastructure Audit Template

## Audit Metadata

- **Date**: YYYY-MM-DD
- **Auditor**: Name of person conducting the audit
- **Environment**: prod/test/dev
- **Previous Audit**: [Link to previous audit]
- **AWS Region**: us-west-2

## Executive Summary

_Brief overview of the audit findings and key recommendations._

## Audit Scope

_Define what resources and configurations are being audited._

## AWS Resource Inventory

### Compute Services

#### EC2 Instances

| Instance ID | Name   | Type   | State   | AZ   | Launch Time   | Key Pair   |
| ----------- | ------ | ------ | ------- | ---- | ------------- | ---------- |
| _i-xxxx_    | _Name_ | _Type_ | _State_ | _AZ_ | _Launch Time_ | _Key Pair_ |

#### ECS Resources

##### Clusters

| Cluster Name | Status   | Registered Container Instances | Running Tasks | Pending Tasks |
| ------------ | -------- | ------------------------------ | ------------- | ------------- |
| _Name_       | _Status_ | _Count_                        | _Count_       | _Count_       |

##### Services

| Service Name | Cluster   | Task Definition | Desired Count | Running Count | Pending Count |
| ------------ | --------- | --------------- | ------------- | ------------- | ------------- |
| _Name_       | _Cluster_ | _Task Def_      | _Count_       | _Count_       | _Count_       |

##### Tasks

| Task ID | Cluster   | Service   | Status   | Health Status | Last Status   | AZ   | Creation Time |
| ------- | --------- | --------- | -------- | ------------- | ------------- | ---- | ------------- |
| _ID_    | _Cluster_ | _Service_ | _Status_ | _Health_      | _Last Status_ | _AZ_ | _Time_        |

#### Lambda Functions

| Function Name | Runtime   | Memory   | Timeout   | Last Modified   | Code Size |
| ------------- | --------- | -------- | --------- | --------------- | --------- |
| _Name_        | _Runtime_ | _Memory_ | _Timeout_ | _Last Modified_ | _Size_    |

### Storage Services

#### S3 Buckets

| Bucket Name | Creation Date | Versioning | Encryption | Public Access |
| ----------- | ------------- | ---------- | ---------- | ------------- |
| _Name_      | _Date_        | _Status_   | _Status_   | _Status_      |

#### RDS Instances

| DB Identifier | Engine   | Version   | Class   | Storage   | Multi-AZ     | Backup Retention |
| ------------- | -------- | --------- | ------- | --------- | ------------ | ---------------- |
| _ID_          | _Engine_ | _Version_ | _Class_ | _Storage_ | _True/False_ | _Days_           |

### Networking

#### VPCs

| VPC ID    | Name   | CIDR Block | Default      | Number of Subnets |
| --------- | ------ | ---------- | ------------ | ----------------- |
| _vpc-xxx_ | _Name_ | _CIDR_     | _True/False_ | _Count_           |

#### Subnets

| Subnet ID    | VPC ID    | Name   | CIDR Block | AZ   | Public       |
| ------------ | --------- | ------ | ---------- | ---- | ------------ |
| _subnet-xxx_ | _vpc-xxx_ | _Name_ | _CIDR_     | _AZ_ | _True/False_ |

#### Security Groups

| SG ID    | VPC ID    | Name   | Description   | Inbound Rules | Outbound Rules |
| -------- | --------- | ------ | ------------- | ------------- | -------------- |
| _sg-xxx_ | _vpc-xxx_ | _Name_ | _Description_ | _Rules_       | _Rules_        |

#### Load Balancers

| LB Name | Type   | Scheme   | VPC   | AZs   | Listeners | Target Groups |
| ------- | ------ | -------- | ----- | ----- | --------- | ------------- |
| _Name_  | _Type_ | _Scheme_ | _VPC_ | _AZs_ | _Count_   | _Count_       |

### IAM Resources

#### Roles

| Role Name | Created | Last Used | Attached Policies | Trusted Entities |
| --------- | ------- | --------- | ----------------- | ---------------- |
| _Name_    | _Date_  | _Date_    | _Policies_        | _Entities_       |

#### Policies

| Policy Name | Type   | Attached Entities | Last Updated |
| ----------- | ------ | ----------------- | ------------ |
| _Name_      | _Type_ | _Count_           | _Date_       |

### Monitoring & Logging

#### CloudWatch Log Groups

| Log Group Name | Retention | Size   | Last Event |
| -------------- | --------- | ------ | ---------- |
| _Name_         | _Days_    | _Size_ | _Date_     |

#### CloudWatch Alarms

| Alarm Name | State   | Metric   | Threshold   | Actions   |
| ---------- | ------- | -------- | ----------- | --------- |
| _Name_     | _State_ | _Metric_ | _Threshold_ | _Actions_ |

## Cost Analysis

### Monthly Cost Breakdown by Service

| Service   | Current Month Cost | Previous Month Cost | Change     |
| --------- | ------------------ | ------------------- | ---------- |
| _Service_ | _Cost_             | _Cost_              | _% Change_ |

### Resource Utilization

| Resource Type | Total Count | Idle/Unused | Utilization % |
| ------------- | ----------- | ----------- | ------------- |
| _Type_        | _Count_     | _Count_     | _%_           |

## Security Assessment

### Public Access and Exposure

_Document resources with public accessibility and associated risks._

### IAM Permissions

_Review IAM roles and policies for principle of least privilege._

### Encryption Status

_Check encryption status for data at rest and in transit._

### Security Groups

_Analyze security group rules for overly permissive settings._

## Best Practices Compliance

| Best Practice Category | Compliant        | Findings   | Recommendations   |
| ---------------------- | ---------------- | ---------- | ----------------- |
| _Category_             | _Yes/No/Partial_ | _Findings_ | _Recommendations_ |

## Resource Optimization Opportunities

_Identify resources that can be optimized for cost, performance, or security._

## Findings and Recommendations

### High Priority

| Finding       | Impact   | Recommendation   | Effort            | Timeline                         |
| ------------- | -------- | ---------------- | ----------------- | -------------------------------- |
| _Description_ | _Impact_ | _Recommendation_ | _Low/Medium/High_ | _Immediate/Short-term/Long-term_ |

### Medium Priority

| Finding       | Impact   | Recommendation   | Effort            | Timeline                         |
| ------------- | -------- | ---------------- | ----------------- | -------------------------------- |
| _Description_ | _Impact_ | _Recommendation_ | _Low/Medium/High_ | _Immediate/Short-term/Long-term_ |

### Low Priority

| Finding       | Impact   | Recommendation   | Effort            | Timeline                         |
| ------------- | -------- | ---------------- | ----------------- | -------------------------------- |
| _Description_ | _Impact_ | _Recommendation_ | _Low/Medium/High_ | _Immediate/Short-term/Long-term_ |

## Action Plan

| Action Item | Responsible | Due Date | Status   |
| ----------- | ----------- | -------- | -------- |
| _Task_      | _Person_    | _Date_   | _Status_ |

## Appendix

### Audit Commands Used

```bash
# List of AWS CLI or other commands used during the audit
```

### References

_List of relevant documentation, best practices, or benchmarks used._
