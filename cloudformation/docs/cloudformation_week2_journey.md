# CloudFormation Learning Journey – Week 2 Project

## Objective
The goal of this exercise was **not** just to deploy AWS resources, but to build real familiarity with **AWS CloudFormation** in preparation for the **AWS DevOps Engineer – Professional** exam, and later replicate the same infrastructure using Terraform.

---

## Initial Requirements
The stack was required to include:
- Parameters (environment awareness)
- Amazon ECR repository
- Amazon S3 bucket
- IAM Role with least-privilege policy
- Outputs for cross-stack or pipeline usage

---

## Initial Implementation
The first iteration of the template included:
- `Parameters` for environment and build number
- An ECR repository with immutable tags
- A basic S3 bucket
- A single IAM role with inline policies
- Outputs exporting key resource identifiers

At this stage, the template **worked conceptually** but failed multiple validations.

---

## Validation Issues Encountered (and Fixes)

### 1. ECR Image Tag Mutability Error
**Problem**
- Used `IMMUTABLE_WITH_EXCLUSION` which is **not supported in CloudFormation**.

**Fix**
- Replaced with:
```yaml
ImageTagMutability: IMMUTABLE
```
- Used a **LifecyclePolicy** instead for image retention logic.

---

### 2. Lifecycle Policy JSON Errors
**Problem**
- Inline lifecycle policy JSON failed validation due to formatting issues.

**Fix**
- Used a properly structured JSON block inside `LifecyclePolicyText`:
```yaml
LifecyclePolicy:
  LifecyclePolicyText: |
    {
      "rules": [
        {
          "rulePriority": 1,
          "description": "Keep only the last 5 images",
          "selection": {
            "tagStatus": "any",
            "countType": "imageCountMoreThan",
            "countNumber": 5
          },
          "action": { "type": "expire" }
        }
      ]
    }
```

---

### 3. IAM Policy Action Formatting
**Problem**
- IAM actions were initially malformed or incorrectly spaced.

**Fix**
- Corrected to valid IAM action syntax:
```yaml
Action:
  - s3:PutObject
  - s3:GetObject
  - s3:ListBucket
```

---

### 4. S3 Bucket Security Warnings
**Problem**
- Bucket lacked encryption, versioning, and public access blocks.

**Fix**
- Added:
  - Server-side encryption (AES256)
  - Versioning
  - Public access block configuration

---

### 5. Validation Workflow
Used:
```bash
aws cloudformation validate-template --template-body file://main.yaml
```

This caught **syntax-level errors early**, before stack creation.

---

## Final Working Template Features
- Parameterized environment (`dev | staging | prod`)
- Secure S3 bucket (encrypted, versioned, private)
- ECR repository with:
  - Immutable tags
  - Image scanning
  - Lifecycle policy
- IAM role with scoped permissions
- Exported outputs for reuse

---

## What This Template Is (and Is Not)

### This Template IS:
- A strong **learning artifact**
- Valid CloudFormation syntax
- Suitable for dev / sandbox environments
- A foundation for DevOps Pro exam concepts

### This Template IS NOT:
- A true production-grade stack (yet)

---

## What a Production CloudFormation Template Would Add

### 1. Conditions
```yaml
Conditions:
  IsProd: !Equals [!Ref EnvironmentName, prod]
```

Used to:
- Increase image retention in prod
- Enable stricter policies
- Prevent accidental deletion

---

### 2. Mappings
```yaml
Mappings:
  ECRRetention:
    dev:
      Count: 5
    prod:
      Count: 30
```

Used with `!FindInMap` inside lifecycle policies.

---

### 3. Deletion & Update Protection
```yaml
DeletionPolicy: Retain
UpdateReplacePolicy: Retain
```

Applied to:
- S3 buckets
- ECR repositories

---

### 4. IAM Role Separation
- **Task Execution Role** (pull images, write logs)
- **Application Role** (S3, business logic)

This is heavily tested in DevOps Pro.

---

### 5. Logging & Observability
- CloudWatch Log Groups
- Parameterized retention
- Explicit log permissions

---

## Terraform Next Step
Once CloudFormation mastery is achieved:
- Rebuild the same stack in Terraform
- Compare:
  - CFN Conditions vs Terraform expressions
  - Outputs vs remote state
  - Change sets vs `terraform plan`

---

## Final Takeaway
This exercise successfully:
- Exposed real CloudFormation pain points
- Forced deep reading of official AWS docs
- Built muscle memory for validation and debugging

This is exactly the kind of struggle that **pays off massively** in the DevOps Engineer – Professional exam.
