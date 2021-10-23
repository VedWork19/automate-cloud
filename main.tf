terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}

provider "aws" {
  shared_credentials_file = "./creds"
  region  = "ap-south-1"
  profile = "customprofile"
}

#Steps:-
#Make a VPC
resource "aws_vpc" "CustomVPC" {
  cidr_block       = "9.9.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true

  tags = {
    Name = "Custom VPC"
  }
}

#Make Subnets
resource "aws_subnet" "PublicSubnet-1" {
  vpc_id     = aws_vpc.CustomVPC.id
  cidr_block = "9.9.1.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "PublicSubnet-1"
  }
}
resource "aws_subnet" "PrivateSubnet-1" {
  vpc_id     = aws_vpc.CustomVPC.id
  cidr_block = "9.9.2.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "PrivateSubnet-1"
  }
}

resource "aws_subnet" "PublicSubnet-2" {
  vpc_id     = aws_vpc.CustomVPC.id
  cidr_block = "9.9.3.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "PublicSubnet-2"
  }
}
resource "aws_subnet" "PrivateSubnet-2" {
  vpc_id     = aws_vpc.CustomVPC.id
  cidr_block = "9.9.4.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "PrivateSubnet-2"
  }
}

resource "aws_subnet" "PublicSubnet-3" {
  vpc_id     = aws_vpc.CustomVPC.id
  cidr_block = "9.9.5.0/24"
  availability_zone = "ap-south-1c"

  tags = {
    Name = "PublicSubnet-3"
  }
}
resource "aws_subnet" "PrivateSubnet-3" {
  vpc_id     = aws_vpc.CustomVPC.id
  cidr_block = "9.9.6.0/24"
  availability_zone = "ap-south-1c"

  tags = {
    Name = "PrivateSubnet-3"
  }
}

#Make Internet Gateway
resource "aws_internet_gateway" "CustomInternetGateway" {
  vpc_id = aws_vpc.CustomVPC.id

  tags = {
    Name = "Custom Internet-Gateway"
  }
}

#Create Elastic IP
resource "aws_eip" "IP" {
  vpc      = true
}

#Make NAT Gateway
resource "aws_nat_gateway" "NATGateway" {
  allocation_id = aws_eip.IP.id
  subnet_id     = aws_subnet.PublicSubnet-3.id

  tags = {
    Name = "Custom NAT-Gateway"
  }
}

#Make Public and Private Route Table
resource "aws_route_table" "PublicRouteTable" {
  vpc_id = aws_vpc.CustomVPC.id

  tags = {
    Name = "Public Route Table"
  }
}

resource "aws_route_table" "PrivateRouteTable" {
  vpc_id = aws_vpc.CustomVPC.id

  tags = {
    Name = "Private Route Table"
  }
}

#Make Routes
resource "aws_route" "PublicRoute1" {
  route_table_id            = aws_route_table.PublicRouteTable.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.CustomInternetGateway.id
}

resource "aws_route" "PrivateRoute1" {
  route_table_id            = aws_route_table.PrivateRouteTable.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_nat_gateway.NATGateway.id
}

#Associate Subnets to Route Table
resource "aws_route_table_association" "Public1" {
  subnet_id      = aws_subnet.PublicSubnet-1.id
  route_table_id = aws_route_table.PublicRouteTable.id
}
resource "aws_route_table_association" "Public2" {
  subnet_id      = aws_subnet.PublicSubnet-2.id
  route_table_id = aws_route_table.PublicRouteTable.id
}
resource "aws_route_table_association" "Public3" {
  subnet_id      = aws_subnet.PublicSubnet-3.id
  route_table_id = aws_route_table.PublicRouteTable.id
}

resource "aws_route_table_association" "Private1" {
  subnet_id      = aws_subnet.PrivateSubnet-1.id
  route_table_id = aws_route_table.PrivateRouteTable.id
}
resource "aws_route_table_association" "Private2" {
  subnet_id      = aws_subnet.PrivateSubnet-2.id
  route_table_id = aws_route_table.PrivateRouteTable.id
}
resource "aws_route_table_association" "Private3" {
  subnet_id      = aws_subnet.PrivateSubnet-3.id
  route_table_id = aws_route_table.PrivateRouteTable.id
}

#Make Security Group
resource "aws_security_group" "CustomHTTP" {
  name        = "Allow HTTP"
  vpc_id      = aws_vpc.CustomVPC.id

  ingress{
      description      = "SSH"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
  }
  ingress{
      description      = "HTTP"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
  }
  egress{
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "Allow HTTP Trafic"
  }
}

#Launch EC2 in Public Subnet with the above Security Group
resource "aws_instance" "PublicInstance" {
  ami           = "ami-0c1a7f89451184c8b"
  associate_public_ip_address = true
  instance_type = "t2.micro"
  key_name = "nayaAccount"
  security_groups = [aws_security_group.CustomHTTP.id]
  subnet_id = aws_subnet.PublicSubnet-2.id
  tags = {
    "Name" = "Public Instance"
  }
  user_data = <<EOF
#!/bin/bash
apt update -y
apt upgrade -y
apt install apache2 -y
systemctl restart apache2
bash -c 'echo Cloud automation with Terraform Successful!!!!!!! > /var/www/html/index.html'
EOF

  root_block_device {
      volume_size = "10"
  }
}

resource "aws_instance" "PrivateInstance1" {
  ami           = "ami-0c1a7f89451184c8b"
  instance_type = "t2.micro"
  key_name = "nayaAccount"
  security_groups = [aws_security_group.CustomHTTP.id]
  subnet_id = aws_subnet.PrivateSubnet-2.id
  tags = {
    "Name" = "Private Instance"
  }

  root_block_device {
      volume_size = "10"
  }
}
