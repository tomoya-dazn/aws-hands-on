terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

variable "region" {
}

variable "access_key" {
}

variable "secret_key" {
}

variable "wordpress_ami" {
}

variable "key_name" {
}

provider "aws" {
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}

# security group
data "aws_vpc" "wordpress-vpc" {
  filter {
    name   = "tag:Name"
    values = ["wordpress-vpc"]
  }
}

resource "aws_security_group" "webserver_sg" {
  name        = "webserver_security_group"
  description = "Security Group for WordPress server"
  vpc_id      = data.aws_vpc.wordpress-vpc.*.id[0]

  ingress = [
    {
      description      = "HTTP"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
    {
      description      = "SSH"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  egress = [{
    description      = "ALL"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }]

  tags = {
    Name = "webserver-sg"
  }
}

# ec2
data "aws_subnet" "public-1a" {
  filter {
    name   = "tag:Name"
    values = ["wordpress-subnet-public-1a"]
  }
}

resource "aws_instance" "wordpress_1" {
  ami                         = var.wordpress_ami
  instance_type               = "t2.micro"
  key_name                    = var.key_name
  subnet_id                   = data.aws_subnet.public-1a.*.id[0]
  vpc_security_group_ids      = [aws_security_group.webserver_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "wordpress-1a"
  }
}
