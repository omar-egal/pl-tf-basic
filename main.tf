terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
}

# Create Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

# Create Public Subnets in two availability zones
resource "aws_subnet" "public_subnet_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a" # Replace with your desired AZ
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b" # Replace with your desired AZ
}

# Create Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

# Associate the Public Subnets with the Public Route Table
resource "aws_route_table_association" "public_subnet_a" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_subnet_b" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public.id
}

# Create Security Group to allow HTTP traffic
resource "aws_security_group" "instance_sg" {
  name_prefix = "instance_sg_"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create EC2 Instances
resource "aws_instance" "web_instance_a" {
  ami                    = "ami-0f34c5ae932e6f0e4" # AMI ID for Amazon Linux 2023 AMI 2023.1.20230725.0 x86_64 HVM kernel-6.1
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet_a.id
  vpc_security_group_ids = [aws_security_group.instance_sg.id]
  user_data              = file("userdata.sh")
}

resource "aws_instance" "web_instance_b" {
  ami                    = "ami-0f34c5ae932e6f0e4" # AMI ID for Amazon Linux 2023 AMI 2023.1.20230725.0 x86_64 HVM kernel-6.1
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet_b.id
  vpc_security_group_ids = [aws_security_group.instance_sg.id]
  user_data              = file("userdata.sh")
}