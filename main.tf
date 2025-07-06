provider "aws" {
  region = "us-east-1"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "july3test4_ec2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  iam_instance_profile = aws_iam_instance_profile.july3test4_ec2_profile.name

  tags = {
    Name = "july3test4-ec2-instance"
  }
}

resource "aws_s3_bucket" "july3test4_bucket" {
  bucket = "july3test4-bucket"

  tags = {
    Name        = "july3test4-bucket"
    Environment = "Production"
  }
}

resource "aws_iam_role" "july3test4_ec2_role" {
  name = "july3test4-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "july3test4_s3_access_policy" {
  name        = "july3test4-s3-access-policy"
  description = "Policy to allow EC2 access to S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject"
        ]
        Effect   = "Allow"
        Resource = [
          aws_s3_bucket.july3test4_bucket.arn,
          "${aws_s3_bucket.july3test4_bucket.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "july3test4_ec2_role_policy_attach" {
  role       = aws_iam_role.july3test4_ec2_role.name
  policy_arn = aws_iam_policy.july3test4_s3_access_policy.arn
}

resource "aws_iam_instance_profile" "july3test4_ec2_profile" {
  name = "july3test4-ec2-profile"
  role = aws_iam_role.july3test4_ec2_role.name
}