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

variable "default_vpc_id" {
}

variable "default_route_id" {
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

resource "aws_internet_gateway" "gw" {
  vpc_id = var.default_vpc_id
  tags = {
    name = "wordpress_internet_gateway"
  }
}

resource "aws_route" "default_route_table" {
  route_table_id         = var.default_route_id
  gateway_id             = aws_internet_gateway.gw.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_subnet" "public_1a" {
  vpc_id                  = var.default_vpc_id
  cidr_block              = "172.31.0.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-1a"
  }
}

resource "aws_subnet" "public_1c" {
  vpc_id                  = var.default_vpc_id
  cidr_block              = "172.31.1.0/24"
  availability_zone       = "${var.region}c"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-1c"
  }
}

resource "aws_subnet" "private_1a" {
  vpc_id                  = var.default_vpc_id
  cidr_block              = "172.31.2.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = false
  tags = {
    Name = "private-1a"
  }
}

resource "aws_subnet" "private_1c" {
  vpc_id                  = var.default_vpc_id
  cidr_block              = "172.31.3.0/24"
  availability_zone       = "${var.region}c"
  map_public_ip_on_launch = false

  tags = {
    Name = "private-1c"
  }
}

resource "aws_security_group" "webserver_sg" {
  name        = "webserver_security_group"
  description = "Security Group for WordPress server"
  vpc_id      = var.default_vpc_id

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
}

resource "aws_instance" "wordpress_1" {
  ami                    = var.wordpress_ami
  instance_type          = "t2.micro"
  key_name               = var.key_name
  subnet_id              = aws_subnet.public_1a.id
  vpc_security_group_ids = [aws_security_group.webserver_sg.id]

  tags = {
    Name = "wordpress-1a"
  }
}

resource "aws_lb_target_group" "wordpress_lb_target_group" {
  target_type      = "instance"
  name             = "wordpress-target-group"
  vpc_id           = var.default_vpc_id
  protocol_version = "HTTP1"
  protocol         = "HTTP"
  port             = 80
  health_check {
    protocol = "HTTP"
    path     = "/wp-includes/images/blank.gif"
  }
}

resource "aws_lb_target_group_attachment" "wordpress_lb_target_group_attachment" {
  target_group_arn = aws_lb_target_group.wordpress_lb_target_group.id
  target_id        = aws_instance.wordpress_1.id
}

resource "aws_lb" "wordpreess_alb" {
  load_balancer_type = "application"
  name               = "wordpress-alb"
  internal           = false
  ip_address_type    = "ipv4"
  security_groups    = [aws_security_group.webserver_sg.id]
  subnets            = [aws_subnet.public_1a.id, aws_subnet.public_1c.id]
}

resource "aws_lb_listener" "wordpress_alb_listener" {
  load_balancer_arn = aws_lb.wordpreess_alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wordpress_lb_target_group.arn
  }
}

resource "aws_instance" "wordpress_2" {
  ami                    = var.wordpress_ami
  instance_type          = "t2.micro"
  key_name               = var.key_name
  subnet_id              = aws_subnet.public_1c.id
  vpc_security_group_ids = [aws_security_group.webserver_sg.id]

  tags = {
    Name = "wordpress-1c"
  }
}

resource "aws_lb_target_group_attachment" "wordpress_lb_target_group_attachment_2" {
  target_group_arn = aws_lb_target_group.wordpress_lb_target_group.id
  target_id        = aws_instance.wordpress_2.id
}
