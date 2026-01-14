output "repository_url" {
    description = "Repository url"
    value = aws_ecr_repository.tf_ECRInstance.repository_url
}

output "repository_arn" {
    description = "Repository ARN"
    value = aws_ecr_repository.tf_ECRInstance.arn
}

output "tf_iam_trust_policy" {
    description = "Trust policy ARN"
    value = data.aws_iam_policy_document.tf_iam_trust_policy
}

output "tf_MyAppRole" {
    description = "MyAppRole ARN"
    value = aws_iam_role.tf_MyAppRole.arn
}

output "tf_iam_access_policy"{
    description = "Inline Policy ARN"
    value = data.aws_iam_policy_document.tf_iam_access_policy
}