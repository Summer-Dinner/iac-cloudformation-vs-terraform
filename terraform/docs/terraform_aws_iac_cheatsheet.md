# AWS Terraform Cheat Sheet: Week 2 Lab

This is a simplified guide with analogies that helped me understand  Terraform AWS setup.

---

## 1. ECR Repository & Lifecycle Policy
**Think of ECR as a warehouse for Docker images.**

```hcl
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
```

**Warehouse Rules (Lifecycle Policy):**
```hcl
resource "aws_ecr_lifecycle_policy" "example" {
  repository = aws_ecr_repository.tf_ECRInstance.name
  policy = <<EOF
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep only 5 most recently pushed tagged images",
      "selection": { "tagStatus": "tagged", "countType": "imageCountMoreThan", "countNumber": 5 },
      "action": { "type": "expire" }
    },
    {
      "rulePriority": 2,
      "description": "Expire untagged images older than 7 days",
      "selection": { "tagStatus": "untagged", "countType": "sinceImagePushed", "countUnit": "days", "countNumber": 7 },
      "action": { "type": "expire" }
    }
  ]
}
EOF
}
```

**Key points:**
- Immutability prevents overwriting an image with the same tag.
- Lifecycle rules manage storage and safe rollbacks.

---

## 2. S3 Bucket & Configurations
**Think of S3 buckets as shelves in the warehouse.**

```hcl
resource "aws_s3_bucket" "tf_S3Bucket" {
  bucket = "${var.environment}-tf-S3Bucket"
  tags={
    Name = "${var.environment}-Wk2-tf-bucket"
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
```

- Versioning = history for every file.
- Public access block = locked doors.

---

## 3. IAM Role & Policies
**Think of IAM roles as workers with badges and toolbelts.**

```hcl
resource "aws_iam_role" "tf-MyAppRole" {
  name = "${var.environment}-tf-MyAppRole"
  assume_role_policy = data.aws_iam_policy_document.tf_iam_policy_document
}

data "aws_iam_policy_document" "tf_iam_policy_document" {
  statement {
    sid = "S3WriteAccess"
    actions = ["s3:PutObject", "s3:GetObject", "s3:ListBucket"]
    resources = ["${aws_s3_bucket.tf_S3Bucket.arn}/*"]
  }

  statement {
    sid = "ECRPushAccess"
    actions = [
      "ecr:PutImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchCheckLayerAvailability",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:InitiateLayerUpload"
    ]
    resources = [aws_ecr_repository.tf_ECRInstance.arn]
  }
}

resource "aws_iam_policy" "tf_MyAppRole_policy" {
  name   = "tf_MyAppRole_policy"
  path   = "/"
  policy = data.aws_iam_policy_document.tf_iam_policy_document.json
}

resource "aws_iam_role_policy_attachment" "tf_MyAppRole_attach" {
  role       = aws_iam_role.tf-MyAppRole.name
  policy_arn = aws_iam_policy.tf_MyAppRole_policy.arn
}
```

- **Role** = worker.
- **Assume Role Policy** = badge, who is allowed in (ECS tasks).
- **Policy Document** = toolbelt, what they can do.
- **Policy Attachment** = giving the tools to the worker.

**Important:** Commented-out sections in Terraform often define restrictions for per-user folders (like limiting a worker to their own cubicle).

---

## 4. Terraform Variables
```hcl
variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}
```
- Used to dynamically name resources (dev, prod, etc.)

---

### 5. Summary Analogy Table
| AWS Resource | Warehouse Analogy |
|--------------|-----------------|
| ECR Repo | Warehouse for Docker images |
| ECR Lifecycle Policy | Rules to keep/remove old crates |
| S3 Bucket | Shelves for storing files |
| S3 Versioning | History of shelf items |
| Public Access Block | Locked doors |
| IAM Role | Worker with a badge |
| Assume Role Policy | Who can enter the warehouse |
| IAM Policy | Tools worker can use |
| Policy Attachment | Giving tools to the worker |

---

This cheat sheet helps you visuali