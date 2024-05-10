# terraform {
#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = "~> 4.16"
#     }
#   }
#   required_version = ">= 1.2.0"
# }

terraform {
  backend "s3" {
    bucket         = "constantine-z"
    region         = "eu-north-1"
    # dynamodb_table = "terraform-locks"
    encrypt        = true
    key            = "tf1.tfstate"
  }
  required_version = ">= 1.4"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.64.0"
    }
  }
}



provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key

  region     = "eu-north-1"
}

# data "aws_s3_object" "ssh_key" {
#   bucket = "constantine-z"
#   key    = "pair-key.pem"
# }

# resource "local_sensitive_file" "ssh_key_file" {
#   content_base64 = data.aws_s3_object.ssh_key.body
#   filename       = "${path.module}/temp-key.pem"
# }

resource "aws_vpc" "default" {
  cidr_block = "10.10.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "defaultVPC"
  }
}

resource "aws_subnet" "default" {
  vpc_id            = aws_vpc.default.id
  cidr_block        = "10.10.10.0/24"
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

resource "aws_route_table" "default" {
  vpc_id = aws_vpc.default.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.default.id
  }

  tags = {
    Name = "defaultRouteTable"
  }
}

resource "aws_route_table_association" "default" {
  subnet_id      = aws_subnet.default.id
  route_table_id = aws_route_table.default.id
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

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  
  ingress {
    from_port   = 5000
    to_port     = 5000
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
  ami                     = "ami-0705384c0b33c194c"
  instance_type           = "t3.micro"
  key_name                = "pair-key"
  subnet_id               = aws_subnet.default.id
  vpc_security_group_ids  = [aws_security_group.launch_wizard.id]
  associate_public_ip_address = true
  private_ip              = "10.10.10.5"
  iam_instance_profile = "IAM_CERT_ROLE"  # access to s3 Constantine-z-2

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("${path.module}/pair-key.pem")
    host        = self.public_ip
  }

provisioner "remote-exec" {
  inline = [
    "sudo apt-get update",
    "sudo apt-get install -y pipx",  
    "sudo pipx ensurepath",  
    "sudo pipx install awscli",  
    "aws s3 cp s3://constantine-z-2/20240808_43c3e236.pfx ./20240808_43c3e236.pfx",  
    "sudo mv ./20240808_43c3e236.pfx /etc/ssl/certs/20240808_43c3e236.pfx", 
    "sudo chmod 600 /etc/ssl/certs/20240808_43c3e236.pfx",  
    "sudo mkdir -p /var/www/BlazorForTF",
    "curl -L -o BlazorForTF.tar https://constantine-z.s3.eu-north-1.amazonaws.com/BlazorForTF.tar",
    "sudo tar -xf BlazorForTF.tar -C /var/www/BlazorForTF",
    "sudo chmod +x /var/www/BlazorForTF/BlazorForTF",
    "sudo chmod -R 755 /var/www/BlazorForTF/wwwroot/",
    "echo '[Unit]\nDescription=BlazorForTF Web App\n\n[Service]\nWorkingDirectory=/var/www/BlazorForTF\nExecStart=/var/www/BlazorForTF/BlazorForTF\nRestart=always\nRestartSec=10\nSyslogIdentifier=blazorfortf\n\n[Install]\nWantedBy=multi-user.target' | sudo tee /etc/systemd/system/blazorfortf.service",
    "sudo systemctl daemon-reload",
    "sudo systemctl enable blazorfortf",
    "sudo systemctl start blazorfortf"
  ]
}



provisioner "local-exec" {
  command = "python3 update_hetzner.py"

  environment = {
    HETZNER_DNS_KEY   = var.hetzner_dns_key
    NEW_IP           = aws_instance.example.public_ip
    HETZNER_ZONE_ID  = "tLLEG6S2qyErGWPvS324um"  
    HETZNER_RECORD_ID = "e9e32d0b9efd0df86c35bd7b49db3b4b"  
    HETZNER_RECORD_NAME = "webaws"
  }
}

  tags = {
    Name = "Ubuntu-Blazor-10-5"
  }
}

