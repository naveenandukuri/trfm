terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}
provider "aws" {
  region     = "${var.region}"
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
}
resource "aws_vpc" "vpc1" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = "true"

  tags = {
    Name = "vpc1"
  }
}
resource "aws_subnet" "pub1" {
  vpc_id     = "${aws_vpc.vpc1.id}"
  cidr_block = "192.168.0.0/24"
  availability_zone = "us-east-2a"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "pubsub1"
  }
}
resource "aws_subnet" "pub2" {
  vpc_id     = "${aws_vpc.vpc1.id}"
  cidr_block = "192.168.1.0/24"
  availability_zone = "us-east-2b"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "pubsub2"
  }
}
resource "aws_subnet" "dmz1" {
  vpc_id     = "${aws_vpc.vpc1.id}"
  cidr_block = "192.168.2.0/24"
  availability_zone = "us-east-2a"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "dmzsub1"
  }
}
resource "aws_subnet" "dmz2" {
  vpc_id     = "${aws_vpc.vpc1.id}"
  cidr_block = "192.168.3.0/24"
  availability_zone = "us-east-2b"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "dmzsub2"
  }
}
resource "aws_subnet" "pri1" {
  vpc_id     = "${aws_vpc.vpc1.id}"
  cidr_block = "192.168.4.0/24"
  availability_zone = "us-east-2a"
  map_public_ip_on_launch = "false"

  tags = {
    Name = "prisub1"
  }
}
resource "aws_subnet" "pri2" {
  vpc_id     = "${aws_vpc.vpc1.id}"
  cidr_block = "192.168.5.0/24"
  availability_zone = "us-east-2b"
  map_public_ip_on_launch = "false"

  tags = {
    Name = "pubsub2"
  }
}
resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.vpc1.id}"

  tags = {
    Name = "igw"
  }
}

resource "aws_route_table" "pubrt" {
  vpc_id = "${aws_vpc.vpc1.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }
  tags = {
    Name = "pubrt"
  }
}

resource "aws_route_table" "dmzrt" {
  vpc_id = "${aws_vpc.vpc1.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }
    tags = {
      Name = "dmzrt"
  } 
}
resource "aws_route_table" "prirt" {
  vpc_id = "${aws_vpc.vpc1.id}"

    tags = {
      Name = "prirt"
  } 
}
resource "aws_route_table_association" "a" {
  subnet_id      = "${aws_subnet.pub1.id}"
  route_table_id = "${aws_route_table.pubrt.id}"
}
resource "aws_route_table_association" "b" {
  subnet_id      = "${aws_subnet.dmz1.id}" 
  route_table_id = "${aws_route_table.dmzrt.id}"
}
resource "aws_route_table_association" "c" {
  subnet_id      = "${aws_subnet.pri1.id}"
  route_table_id = "${aws_route_table.prirt.id}"
}
resource "aws_route_table_association" "d" {
  subnet_id      = "${aws_subnet.pub2.id}" 
  route_table_id = "${aws_route_table.pubrt.id}"
}
resource "aws_route_table_association" "e" {
  subnet_id      = "${aws_subnet.dmz2.id}"
  route_table_id = "${aws_route_table.dmzrt.id}"
}
resource "aws_route_table_association" "f" {
  subnet_id      = "${aws_subnet.pri2.id}"
  route_table_id = "${aws_route_table.prirt.id}"
}
resource "aws_security_group" "lbasg" {
  name        = "lbasg"
  description = "Allow ssh http inbound traffic"
  vpc_id      = "${aws_vpc.vpc1.id}"

  ingress {
    description      = "ssh"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
   }
  
  ingress {
    description      = "http"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
   }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "lbasg"
  }
}
resource "aws_lb" "lb1" {
  name               = "lb1"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.lbasg.id}"]
  subnets            = ["${aws_subnet.pub1.id}" , "${aws_subnet.pub2.id}"]
}
resource "aws_lb_target_group" "tg1" {
  name     = "tg1"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.vpc1.id}"
  
  stickiness {
    type = "lb_cookie"
  }
  # Alter the destination of the health check to be the login page.
  health_check {
    path = "/login"
    port = 80
  }

}

resource "aws_lb_listener" "listner" {
  load_balancer_arn = "${aws_lb.lb1.arn}"
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.tg1.arn}"
  }
}
