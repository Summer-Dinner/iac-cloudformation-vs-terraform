terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.28.0"
    }
  }
}
    
resource "aws_ecr_repository" "tf_ECRInstance" {
    name = "${var.environment}-wk2-ecr"
    image_tag_mutability = "IMMUTABLE_WITH_EXCLUSION"
    image_tag_mutability_exclusion_filter {
      filter = "latest*"
      filter_type = "WILDCARD"
    }
    image_tag_mutability_exclusion_filter {
      filter = "dev-*"
      filter_type = "WILDCARD"
    }
    tags = {
      Environment = var.environment
      ManagedBy   = "Terraform"
}
}

resource "aws_ecr_lifecycle_policy" "example" {
  repository = aws_ecr_repository.tf_ECRInstance.name
  policy = <<EOF
          {
            "rules": [
              {
                "rulePriority": 1,
                "description": "Keep only 5 most recently pushed tagged images",
                "selection": {
                  "tagStatus": "tagged",
                  "tagPrefixList": ["dev-"],
                  "countType": "imageCountMoreThan",
                  "countNumber": 5
                },
                "action": {
                  "type": "expire"
                }
              },
              {
                "rulePriority": 2,
                "description": "Expire untagged images older than 7 days",
                "selection": {
                  "tagStatus": "untagged",
                  "countType": "sinceImagePushed",
                  "countUnit": "days",
                  "countNumber": 7
                },
                "action": {
                  "type": "expire"
                }
              }
              
            ]
          }
          EOF
}

resource "aws_s3_bucket" "tf_S3Bucket" {
    bucket = "${var.environment}-tf-s3bucket"
    tags={
        Name = "${var.environment}-wk2-tf-bucket"
        Environment = var.environment
    } 
}

resource "aws_s3_bucket_versioning" "this_versioning" {
  bucket = aws_s3_bucket.tf_S3Bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_account_public_access_block" "this" {
  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
  
}

#######################################################
# 1️⃣ Trust Policy (Who can assume the role)
#######################################################

data "aws_iam_policy_document" "tf_iam_trust_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

#######################################################
# 2️⃣ IAM Role
#######################################################

resource "aws_iam_role" "tf_MyAppRole" {
  name = "${var.environment}-tf-MyAppRole"
  assume_role_policy = data.aws_iam_policy_document.tf_iam_trust_policy.json
  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

#######################################################
# 3️⃣ Inline Policy (Permissions for S3 + ECR)
#######################################################
data "aws_iam_policy_document" "tf_iam_access_policy" {
  # S3 access
  statement {
    sid    = "S3WriteAccess"
    effect = "Allow"

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket"
    ]

    resources = [
      aws_s3_bucket.tf_S3Bucket.arn,       # bucket itself
      "${aws_s3_bucket.tf_S3Bucket.arn}/*" # all objects inside
    ]
  }

  # ECR access
  statement {
    sid    = "ECRPushAccess"
    effect = "Allow"

    actions = [
      "ecr:PutImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchCheckLayerAvailability",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:InitiateLayerUpload"
    ]

    resources = [
      aws_ecr_repository.tf_ECRInstance.arn
    ]
  }
}

#######################################################
# 4️⃣ Attach the policy to the role
#######################################################

resource "aws_iam_policy" "tf_MyAppRole_policy" {
  name   = "${var.environment}-tf-MyAppRole-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.tf_iam_access_policy.json
}

resource "aws_iam_role_policy_attachment" "tf_MyAppRole_attach" {
  role       = aws_iam_role.tf_MyAppRole.name
  policy_arn = aws_iam_policy.tf_MyAppRole_policy.arn
}


# Image immutability prevents tags from being overwritten, ensuring that deployed images
# are cryptographically consistent across environments.
# Combined with lifecycle policies, this provides:
# - Safe rollbacks (previous images still exist)
# - Controlled storage growth
# - Predictable, auditable deployments