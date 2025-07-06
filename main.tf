provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "shreyas_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "shreyas_public_subnet" {
  vpc_id                     = aws_vpc.shreyas_vpc.id
  cidr_block                 = "10.0.1.0/24"
  map_public_ip_on_creation  = true
}

resource "aws_subnet" "shreyas_private_subnet" {
  vpc_id     = aws_vpc.shreyas_vpc.id
  cidr_block = "10.0.2.0/24"
}

resource "aws_internet_gateway" "shreyas_internet_gateway" {
  vpc_id = aws_vpc.shreyas_vpc.id
}

resource "aws_route_table" "shreyas_route_table" {
  vpc_id = aws_vpc.shreyas_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.shreyas_internet_gateway.id
  }
}

resource "aws_route_table_association" "shreyas_route_table_association" {
  subnet_id      = aws_subnet.shreyas_public_subnet.id
  route_table_id = aws_route_table.shreyas_route_table.id
}

resource "aws_iam_role" "shreyas_ec2_role" {
  name               = "shreyas_ec2_role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role_policy.json
}

data "aws_iam_policy_document" "ec2_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_security_group" "shreyas_security_group" {
  name        = "shreyas_security_group"
  vpc_id      = aws_vpc.shreyas_vpc.id
  description = "Allow SSH and HTTP access"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "shreyas_ec2_instance" {
  ami                    = "ami-0c55b159cbfafe1f0"  # Use a valid AMI ID
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.shreyas_public_subnet.id
  iam_instance_profile    = aws_iam_instance_profile.shreyas_ec2_instance_profile.name
  security_groups        = [aws_security_group.shreyas_security_group.name]

  tags = {
    Name = "shreyas_ec2_instance"
  }

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World!"
              EOF
}

resource "aws_iam_instance_profile" "shreyas_ec2_instance_profile" {
  name = "shreyas_ec2_instance_profile"
  role = aws_iam_role.shreyas_ec2_role.name
}

resource "aws_s3_bucket" "shreyas_s3_bucket" {
  bucket = "shreyas-s3-bucket"
  acl    = "private"

  versioning {
    enabled = true
  }

  tags = {
    Name = "shreyas_s3_bucket"
  }
}

resource "aws_s3_bucket_policy" "shreyas_s3_bucket_policy" {
  bucket = aws_s3_bucket.shreyas_s3_bucket.id
  policy = data.aws_iam_policy_document.s3_bucket_policy.json
}

data "aws_iam_policy_document" "s3_bucket_policy" {
  statement {
    actions = ["s3:GetObject", "s3:PutObject"]
    resources = [aws_s3_bucket.shreyas_s3_bucket.arn, "${aws_s3_bucket.shreyas_s3_bucket.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.shreyas_ec2_role.arn]
    }
  }
}

resource "aws_security_group_rule" "allow_ec2_to_s3" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "tcp"
  security_group_id       = aws_security_group.shreyas_security_group.id
  source_security_group_id = aws_security_group.shreyas_security_group.id
}

resource "aws_security_group_rule" "allow_s3_to_ec2" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "tcp"
  security_group_id       = aws_security_group.shreyas_security_group.id
  source_security_group_id = aws_security_group.shreyas_security_group.id
}