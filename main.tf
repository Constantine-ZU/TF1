terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.1.0"
}

variable "TF_VAR_ACCESS_KEY" {
  description = "AWS Access Key ID"
}

variable "TF_VAR_SECRET_KEY" {
  description = "AWS Secret Access Key"
}


provider "aws" {
    access_key = var.TF_VAR_ACCESS_KEY
  secret_key = var.TF_VAR_SECRET_KEY
  region = "eu-north-1"
}

resource "aws_instance" "app_server" {
  ami           = "ami-0c0ec0a3a3a4c34c0"
  instance_type = "t2.micro"

  tags = {
    Name = "ExampleAppServerInstance"
  }
}
