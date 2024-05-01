terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}

variable "access_key" {
  description = "AWS Access Key ID"
}

variable "secret_key" {
  description = "AWS Secret Access Key"
}

provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = "eu-north-1"
}

# Security Group for EC2 instance
resource "aws_security_group" "launch_wizard_sg" {
  name        = "launch-wizard"
  description = "launch-wizard created 2024-05-01T19:01:58.158Z"
  vpc_id      = "vpc-0c4bcc31755a8df93"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["213.149.169.233/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance with specific configurations
resource "aws_instance" "example_instance" {
  ami           = "ami-03035978b5aeb1274"
  instance_type = "t3.micro"
  key_name      = "pair-key"
  ebs_optimized = true
  security_groups = [aws_security_group.launch_wizard_sg.id]

  root_block_device {
    volume_size           = 10
    delete_on_termination = true
    encrypted             = false
    volume_type           = "gp3"
    iops                  = 3000
    throughput            = 125
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 2
    http_tokens                 = "required"
  }

  private_dns_name_options {
    hostname_type                 = "ip-name"
    enable_resource_name_dns_a_record    = true
    enable_resource_name_dns_aaaa_record = false
  }
}

# Network interface setup (using a separate resource if needed for more customization)
resource "aws_network_interface" "primary_nic" {
  subnet_id       = "<your_subnet_id_here>"  # Specify your subnet ID
  security_groups = [aws_security_group.launch_wizard_sg.id]

  attachment {
    instance     = aws_instance.example_instance.id
    device_index = 0
  }
}
