data "aws_iam_policy_document" "k3s_master_ssm_access_document" {
  statement {
    effect = "Allow"

    actions = [
      "ssm:GetParameter",
      "ssm:PutParameter",
      "ssm:GetParametersByPath",
      "ssm:GetParameterHistory"
    ]

    resources = [
      "arn:aws:ssm:*:*:parameter/k3s*"
    ]
  }
}

resource "aws_iam_policy" "k3s_master_ssm_access" {
  name        = "k3s_master_ssm_access_policy"
  path        = "/"
  description = "Policy for K3s master to have read/write access to SSM parameters with prefix 'k3s'."

  policy = data.aws_iam_policy_document.k3s_master_ssm_access_document.json
}
