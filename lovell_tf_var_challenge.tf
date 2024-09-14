provider "aws" {}

variable "is_production" {
  default = true
}

variable "to_create" {
    default = true
}

variable "ec2_small" {
    default = "t2.small"
}

variable "ec2_micro" {
    default = "t2.micro"
}

variable "ami_id" {
  description = "AMI ID"
  type        = string
  default     = "ami-0b72821e2f351e396"
}

variable "ec2_name" {
  description = "Name of EC2"
  type        = string
  default     = "lovell-sample-ec2-from-tf-conditional" # Replace with your preferred EC2 Instance Name 
}

variable "instance_type" {
  description = "EC2 Instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name of EC2 Key Pair"
  type        = string
  default     = "lovell-useast1-13072024" # Replace with your own key pair name (without .pem extension) that you have downloaded from AWS console previously
}

variable "sg_name" {
  description = "Name of EC2 security group"
  type        = string
  default     = "lovell-tf-ec2-allow-ssh-http-https" # Replace with your own preferred security group name that gives an overview of the security group coverage
}

variable "vpc_name" {
  description = "Name of VPC to use"
  type        = string
  default     = "lovell-tf-vpc" # Update with your own VPC name, found under VPC > your VPC > Tags > value of Name
}

variable "subnet_name" {
  description = "Name of subnet to use"
  type        = string
  default     = "lovell-tf-public-subnet-us-east-1c" # Update with your own Subnet name, found under VPC > your VPC > selected Public Subnet > tags > value of Name
}

output "environment_message" {
  value = var.is_production ? "Production Environment" : "Non-Production Environment"
}

# Uses an existing VPC, filtered by vpc_name defined in variables.tf
data "aws_vpc" "selected_vpc" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

# Uses an existing subnet, filtered by subnet_name defined in variables.tf
data "aws_subnet" "selected_subnet" {
  filter {
    name   = "tag:Name"
    values = [var.subnet_name]
  }
}

resource "aws_security_group" "ec2_sg" {
  name   = var.sg_name
  vpc_id = data.aws_vpc.selected_vpc.id # var.vpc_id
  # count = var.to_create ? 1 : 0

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

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_instance" "sample_ec2_variables" {
  # Creates one EC2 if to_create == true
  count = var.to_create ? 1 : 0

  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = data.aws_subnet.selected_subnet.id
  associate_public_ip_address = true
  vpc_security_group_ids = aws_security_group.ec2_sg.id
  # vpc_security_group_ids = aws_security_group.ec2_sg.id != null ? [aws_security_group.ec2_sg.id] : null

  tags = {
    Name = var.ec2_name
  }
}
