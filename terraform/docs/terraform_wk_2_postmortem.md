# Terraform Week 2 Postmortem

## 1. What Went Right

- **Plan & Apply Workflow:**
  - `terraform plan` and `terraform apply` executed successfully.
  - Outputs confirm all resources were created in correct order.

- **Resource Definitions:**
  - **ECR repository:** immutability rules applied, lifecycle policy prevents storage bloat.
  - **S3 bucket:** versioning and public access blocks applied; naming consistent with environment.
  - **IAM Role & Policy:** ECS trust policy correct; IAM policy attached allows S3 and ECR access.

- **Terraform Outputs:**
  - Clean outputs for future pipelines (ECR URL, IAM Role ARN).

## 2. What Was Confusing / Mistakes

- **Variables referencing resources:**
  - Cannot use resource attributes in variable defaults; must reference resource directly.

- **IAM policy vs Trust Policy confusion:**
  - Trust policy = "who can assume the role"
  - IAM policy = "what the role can do"

- **Commented-out Terraform snippets:**
  - Conditional username-based S3 restrictions added complexity unnecessarily.

- **ECR Lifecycle JSON:**
  - Tag prefix filters (`dev-*`) needed clarification.

- **Minor:**
  - Typos in variable names (`s3-bucket-id` vs `s3_bucket_id`) can break references.

## 3. Lessons Learned

1. **Trust policy vs IAM policy:** keep separate and clear.
2. **Variables should not depend on resources for defaults.**
3. **Always review Terraform plan outputs** before applying.
4. **Keep lifecycle rules simple** at first, then expand.
5. **Consistent naming** using `var.environment` prevents chaos.
6. **Terraform is your worker bee:** it executes instructions in order; you provide the instructions.

## 4. Action Items / Next Steps

- Clean up variables referencing resources indirectly.
- Use outputs in downstream modules (ECS tasks, etc.).
- Document IAM role/policy separation.
- Consider explicit resource dependencies if Terraform misorders anything.

---
**TL;DR:** Week 2 Terraform run was solid. Minor mistakes were mainly variable references and IAM trust vs access confusion. Structurally, setup is modular and ready for CI/CD progression.

