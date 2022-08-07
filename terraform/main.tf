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
}

variable "secret_key" {
}

provider "aws" {
  region     = "ap-northeast-1"
  access_key = var.access_key
  secret_key = var.secret_key
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "vpc-0ba872d46dc4b2213"
  tags = {
    name = "wordpress_internet_gateway"
  }
}

