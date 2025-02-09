provider "aws" {
  region = "us-west-2"
}

variable "user" {
  type        = string
  description = "Username for resource naming and tags"
}

variable "public_ip" {
  type        = string
  description = "Public IP address for SSH access"
}

variable "instance_type" {
  type        = string
  description = "Instance type for the kernel development instance"
  default     = "m6i.4xlarge"
}

variable "instance_state" {
  type        = string
  description = "Desired state of the instance (running or stopped)"
  default     = "running"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = ["qa northwest"]
  }
}

data "aws_subnet" "subnet" {
  vpc_id = data.aws_vpc.vpc.id
  filter {
    name   = "tag:Name"
    values = ["qa internal us-west-2a"]
  }
}

resource "aws_security_group" "kernel_dev" {
  name        = "${var.user}-kernel-dev"
  description = "Security group for kernel development"
  vpc_id      = data.aws_vpc.vpc.id

  ingress {
    description = "Allow SSH on port 22, locked down to my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.public_ip}/32"]
  }

  egress {
    description = "Allow full egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.user}-kernel-dev"
    contact = var.user
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_instance" "kernel_dev" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.user

  vpc_security_group_ids = [aws_security_group.kernel_dev.id]
  subnet_id              = data.aws_subnet.subnet.id

  associate_public_ip_address = true

  root_block_device {
    volume_size = 100
    volume_type = "gp3"
  }

  tags = {
    Name    = "${var.user}-kernel-dev"
    contact = var.user
  }

  volume_tags = {
    Name    = "${var.user}-kernel-dev"
    contact = var.user
  }
}

resource "aws_ec2_instance_state" "kernel_dev" {
  instance_id = aws_instance.kernel_dev.id
  state       = var.instance_state
  depends_on  = [aws_instance.kernel_dev]
}
