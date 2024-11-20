#region rds_master_password_demo
resource "aws_kms_key" "dynamo" {
  description                        = "for dynamo"
  bypass_policy_lockout_safety_check = null
  custom_key_store_id                = null
  customer_master_key_spec           = "SYMMETRIC_DEFAULT"
  deletion_window_in_days            = null
  enable_key_rotation                = false
  is_enabled                         = true
  key_usage                          = "ENCRYPT_DECRYPT"
  multi_region                       = false
  xks_key_id                         = null
}

# ref. https://docs.aws.amazon.com/secretsmanager/latest/userguide/security-encryption.html
data "aws_iam_policy_document" "kms_rds_password" {
  statement {
    effect = "Allow"
    actions = [
      "kms:CreateAlias",
      "kms:UpdateAlias",
      "kms:DeleteAlias",
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:CreateGrant",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values   = ["secretsmanager.*.amazonaws.com", "rds.*.amazonaws.com"]
    }
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Describe*",
      "kms:Get*",
      "kms:List*",
      "kms:RevokeGrant",
      "kms:PutKeyPolicy",
    ]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
      ]
    }
    resources = ["*"]
  }
}

resource "aws_kms_key_policy" "dynamo" {
  key_id = aws_kms_key.dynamo.id
  policy = data.aws_iam_policy_document.kms_rds_password.json
}

