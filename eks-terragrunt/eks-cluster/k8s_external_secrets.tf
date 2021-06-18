data "aws_iam_policy_document" "k8s_external_secrets_iam_policy" {

  # Secrets manager
  statement {
    actions = [
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds"
    ]

    resources = [
      "arn:aws:secretsmanager:*:${data.aws_caller_identity.current.id}:secret:${local.cluster_name}/*"
    ]
  }

  # KMS key policy for Secrets Manager Parameters
  statement {
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
    ]

    resources = [
      aws_kms_key.eks.arn
    ]

    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:SecretARN"
      values = [
        "arn:aws:secretsmanager:*:${data.aws_caller_identity.current.id}:secret:${local.cluster_name}/*"
      ]
    }
  }

  # SSM parameter store
  statement {
    actions = [
      "ssm:GetParameter*",
    ]

    resources = [
      "arn:aws:ssm:*:${data.aws_caller_identity.current.id}:parameter/${local.cluster_name}/*"
    ]
  }

  # KMS key policy for SSM Parameters
  statement {
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
    ]

    resources = [
      aws_kms_key.eks.arn
    ]

    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:PARAMETER_ARN"
      values = [
        "arn:aws:ssm:*:${data.aws_caller_identity.current.id}:parameter/${local.cluster_name}/*"
      ]
    }
  }

}

data "aws_iam_policy_document" "k8s_external_secrets_sassume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.id}:oidc-provider/${local.eks_oids_issuer}"]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "${local.eks_oids_issuer}:sub"
      values = [
        "system:serviceaccount:external-secrets:external-secrets-kubernetes-external-secrets"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.eks_oids_issuer}:aud"
      values = [
        "sts.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "k8s_external_secrets_role" {
  name               = "EKSExternalSecretsRole"
  path               = "/${local.cluster_name}/"
  assume_role_policy = data.aws_iam_policy_document.k8s_external_secrets_sassume_role.json
  tags               = local.common_tags
}

resource "aws_iam_policy" "k8s_external_secrets_iam_policy" {
  name        = "EKSExternalSecretsIAMPolicy"
  path        = "/${local.cluster_name}/"
  description = "Policy used by EKS to use external secrets from AWS resources"
  policy      = data.aws_iam_policy_document.k8s_external_secrets_iam_policy.json
}

resource "aws_iam_role_policy_attachment" "k8s_external_secrets" {
  role       = aws_iam_role.k8s_external_secrets_role.name
  policy_arn = aws_iam_policy.k8s_external_secrets_iam_policy.arn
}
