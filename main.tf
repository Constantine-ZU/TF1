terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}



provider "aws" {
  #access_key = var.access_key
  #secret_key = var.secret_key

  region     = "eu-north-1"
}

resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "defaultVPC"
  }
}

resource "aws_subnet" "default" {
  vpc_id            = aws_vpc.default.id
  cidr_block        = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "defaultSubnet"
  }
}

resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id

  tags = {
    Name = "defaultIGW"
  }
}

resource "aws_security_group" "launch_wizard" {
  name        = "launch-wizard"
  description = "launch-wizard security group for EC2 instance"
  vpc_id      = aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
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

resource "aws_instance" "example" {
  ami                     = "ami-03035978b5aeb1274"
  instance_type           = "t3.micro"
  key_name                = "pair-key"
  subnet_id               = aws_subnet.default.id
  vpc_security_group_ids  = [aws_security_group.launch_wizard.id]
  associate_public_ip_address = true

  tags = {
    Name = "MyExampleInstance"
  }
}

