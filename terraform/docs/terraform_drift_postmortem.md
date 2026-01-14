# Terraform Drift Postmortem

## 1. What happened
- Manually **deleted IAM role** `dev-tf-MyAppRole`.
- **Disabled S3 versioning** for `dev-tf-s3bucket`.
- Terraform detected the changes (drift) during `terraform plan`.
- Terraform proposed:
  - **Recreate IAM role** and **reattach the policy**.
  - **Re-enable S3 versioning** (update in-place).

## 2. Why Terraform reacted this way
- Terraform's **state file** still had the role and S3 versioning as `Enabled`.
- Drift occurs when actual resources differ from the state.
- Terraform plans corrective actions to **reconcile the state with reality**.

## 3. Key concepts illustrated
| Concept | Example | Analogy |
|---------|--------|---------|
| Drift | Manual deletion of IAM role and S3 change | Someone rearranged the warehouse while your inventory list assumed the old layout |
| Plan | Terraform shows what it will do to fix drift | The "correction list" before the warehouse workers start restoring order |
| Apply | Terraform executes the correction | Workers rebuild the missing shelves and restore S3 rules |

## 4. Lessons learned
1. Terraform assumes it **controls the resources** it manages. Manual changes = drift.
2. `terraform plan` **always reveals drift**, even if nothing is broken yet.
3. `terraform apply` **fixes drift** by reconciling state with reality.
4. **Avoid manual edits** on resources managed by Terraform unless for experimentation.

## 5. Optional actions to handle drift safely
- Use `terraform import` to bring manually changed resources back under Terraform control.
- Use `lifecycle { ignore_changes = [...] }` for attributes expected to change outside Terraform.
- Always **run `terraform plan` first** to see what will change before applying.

## 6. Analogy Recap
Terraform is my **warehouse manager**:
- Keeps an inventory (`state file`).
- Any manual changes = drift.
- Apply = restores the warehouse to match the inventory list.

