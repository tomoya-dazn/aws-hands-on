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
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}

variable "region" {
}

variable "access_key" {
}

variable "secret_key" {
}

# vpc
resource "aws_vpc" "wordpress-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "wordpress-vpc"
  }
}

# subnet
resource "aws_subnet" "public-1a" {
  vpc_id                  = aws_vpc.wordpress-vpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = false

  tags = {
    Name = "wordpress-subnet-public-1a"
  }
}

resource "aws_subnet" "public-1c" {
  vpc_id                  = aws_vpc.wordpress-vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.region}c"
  map_public_ip_on_launch = false

  tags = {
    Name = "wordpress-subnet-public-1c"
  }
}

resource "aws_subnet" "private-1a" {
  vpc_id                  = aws_vpc.wordpress-vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = false

  tags = {
    Name = "wordpress-subnet-private-1a"
  }
}

resource "aws_subnet" "private-1c" {
  vpc_id                  = aws_vpc.wordpress-vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "${var.region}c"
  map_public_ip_on_launch = false

  tags = {
    Name = "wordpress-subnet-private-1c"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "wordpress-igw" {
  vpc_id = aws_vpc.wordpress-vpc.id

  tags = {
    Name = "wordpress-internet-gateway"
  }
}

# route table
resource "aws_route_table" "wordpress-private1a-route-table" {
  vpc_id = aws_vpc.wordpress-vpc.id

  tags = {
    "Name" = "wordpress-private1a-route-table"
  }
}

resource "aws_route_table_association" "associate-private1a" {
  subnet_id      = aws_subnet.private-1a.id
  route_table_id = aws_route_table.wordpress-private1a-route-table.id
}

resource "aws_route_table" "wordpress-private1c-route-table" {
  vpc_id = aws_vpc.wordpress-vpc.id

  tags = {
    "Name" = "wordpress-private1c-route-table"
  }
}

resource "aws_route_table_association" "associate-private1c" {
  subnet_id      = aws_subnet.private-1c.id
  route_table_id = aws_route_table.wordpress-private1c-route-table.id
}

resource "aws_route_table" "wordpress-public-route-table" {
  vpc_id = aws_vpc.wordpress-vpc.id

  tags = {
    "Name" = "wordpress-public-route-table"
  }
}

resource "aws_route" "r" {
  route_table_id         = aws_route_table.wordpress-public-route-table.id
  gateway_id             = aws_internet_gateway.wordpress-igw.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "associate-public1a" {
  subnet_id      = aws_subnet.public-1a.id
  route_table_id = aws_route_table.wordpress-public-route-table.id
}

resource "aws_route_table_association" "associate-public1c" {
  subnet_id      = aws_subnet.public-1c.id
  route_table_id = aws_route_table.wordpress-public-route-table.id
}
