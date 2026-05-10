data "aws_iam_policy_document" "kms" {
  statement {
    sid    = "EnableAccountAdministration"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_id}:root"]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowDynamoDBUseForTableEncryption"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["dynamodb.amazonaws.com"]
    }

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncryptFrom",
      "kms:ReEncryptTo",
      "kms:GenerateDataKey",
      "kms:GenerateDataKeyWithoutPlaintext",
      "kms:DescribeKey",
      "kms:CreateGrant"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [var.account_id]
    }

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["dynamodb.${var.region}.amazonaws.com"]
    }
  }

  statement {
    sid    = "AllowCloudWatchLogsUseForLambdaLogGroup"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logs.${var.region}.amazonaws.com"]
    }

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncryptFrom",
      "kms:ReEncryptTo",
      "kms:GenerateDataKey",
      "kms:GenerateDataKeyWithoutPlaintext",
      "kms:DescribeKey"
    ]

    resources = ["*"]

    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values = [
        "arn:aws:logs:${var.region}:${var.account_id}:log-group:/aws/lambda/${var.env}-health-check-function",
        "arn:aws:logs:${var.region}:${var.account_id}:log-group:/aws/lambda/${var.env}-health-check-function:*"
      ]
    }
  }
}

resource "aws_kms_key" "this" {
  description             = "${var.name_prefix} customer managed key for DynamoDB and Lambda logs"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.kms.json
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.env}-health-check-key"
  target_key_id = aws_kms_key.this.key_id
}
