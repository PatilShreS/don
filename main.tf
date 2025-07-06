provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "s3buckettesting_s3" {
  bucket = "s3buckettesting-s3-1749109313689-l9qht43ba"
  acl    = "private"

  versioning {
    enabled = true
  }

  logging {
    target_bucket = "${aws_s3_bucket.s3buckettesting_s3.bucket}"
    target_prefix = "log/"
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  lifecycle {
    prevent_destroy = true
  }

  block_public_access {
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
  }
}

resource "aws_s3_bucket_policy" "s3buckettesting_policy" {
  bucket = aws_s3_bucket.s3buckettesting_s3.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.s3buckettesting_s3.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role" "s3buckettesting_role" {
  name = "s3buckettesting-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Effect    = "Allow"
        Sid       = ""
      }
    ]
  })
}

resource "aws_iam_policy" "s3buckettesting_policy" {
  name        = "s3buckettesting-policy"
  description = "IAM Policy for S3 access permissions."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          aws_s3_bucket.s3buckettesting_s3.arn,
          "${aws_s3_bucket.s3buckettesting_s3.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3buckettesting_attachment" {
  policy_arn = aws_iam_policy.s3buckettesting_policy.arn
  role       = aws_iam_role.s3buckettesting_role.name
}

resource "aws_iam_role_policy_attachment" "s3buckettesting_role_attachment" {
  policy_arn = aws_iam_policy.s3buckettesting_policy.arn
  role       = aws_iam_role.s3buckettesting_role.name
}