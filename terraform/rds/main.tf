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

data "aws_security_group" "webserver_sg" {
  filter {
    name   = "tag:Name"
    values = ["webserver-sg"]
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "rds_security_group"
  description = "Security Group for RDS"
  vpc_id      = data.aws_vpc.wordpress-vpc.*.id[0]

  ingress = [
    {
      description      = "RDS for MySQL"
      from_port        = 3306
      to_port          = 3306
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = [data.aws_security_group.webserver_sg.*.id[0]]
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
    Name = "rds-sg"
  }
}

# db subnet
data "aws_subnet" "private-1a" {
  filter {
    name   = "tag:Name"
    values = ["wordpress-subnet-private-1a"]
  }
}

data "aws_subnet" "private-1c" {
  filter {
    name   = "tag:Name"
    values = ["wordpress-subnet-private-1c"]
  }
}

resource "aws_db_subnet_group" "rds_subnet" {
  name       = "rds_subnet"
  subnet_ids = [data.aws_subnet.private-1a.*.id[0], data.aws_subnet.private-1c.*.id[0]]

  tags = {
    Name = "rds-subnet"
  }
}

# rds instance
resource "aws_db_instance" "rds" {
  allocated_storage = 10
  engine            = "mysql"
  engine_version    = "8.0.28"
  instance_class    = "db.t3.micro"
  db_name           = "wordpress"
  username          = "admin"
  password          = "0628faith"
  # parameter_group_name   = "default.mysql8.0.28"
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  availability_zone      = "ap-northeast-1a"
  identifier             = "rds-user1"
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet.name
}
