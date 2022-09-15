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

# target group
data "aws_vpc" "wordpress-vpc" {
  filter {
    name   = "tag:Name"
    values = ["wordpress-vpc"]
  }
}

resource "aws_lb_target_group" "wordpress_lb_target_group" {
  target_type      = "instance"
  name             = "wordpress-target-group"
  vpc_id           = data.aws_vpc.wordpress-vpc.*.id[0]
  protocol_version = "HTTP1"
  protocol         = "HTTP"
  port             = 80
  health_check {
    protocol = "HTTP"
    path     = "/wp-includes/images/blank.gif"
  }

  tags = {
    "Name" = "wordpress-alb-target-group"
  }
}

# target group attachment
data "aws_instance" "wordpress_1" {
  filter {
    name   = "tag:Name"
    values = ["wordpress-1a"]
  }
}

resource "aws_lb_target_group_attachment" "wordpress_lb_target_group_attachment" {
  target_group_arn = aws_lb_target_group.wordpress_lb_target_group.id
  target_id        = data.aws_instance.wordpress_1.*.id[0]
}

# alb
data "aws_security_group" "webserver_sg" {
  filter {
    name   = "tag:Name"
    values = ["webserver-sg"]
  }
}

data "aws_subnet" "public-1a" {
  filter {
    name   = "tag:Name"
    values = ["wordpress-subnet-public-1a"]
  }
}

data "aws_subnet" "public-1c" {
  filter {
    name   = "tag:Name"
    values = ["wordpress-subnet-public-1c"]
  }
}

resource "aws_lb" "wordpreess_alb" {
  load_balancer_type = "application"
  name               = "wordpress-alb"
  internal           = false
  ip_address_type    = "ipv4"
  security_groups    = [data.aws_security_group.webserver_sg.*.id[0]]
  subnets            = [data.aws_subnet.public-1a.*.id[0], data.aws_subnet.public-1c.*.id[0]]

  tags = {
    "Name" = "wordpress-alb"
  }
}

# listener
resource "aws_lb_listener" "wordpress_alb_listener" {
  load_balancer_arn = aws_lb.wordpreess_alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wordpress_lb_target_group.arn
  }
}
