provider "aws" {
  region = "us-east-1"  # change as needed
}

# Create a VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Create public subnet
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

# Create private subnet
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"
}

# Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

# Route table for public subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group for Bastion (allow SSH from anywhere, for demo)
resource "aws_security_group" "bastion_sg" {
  name        = "bastion_sg"
  description = "Allow SSH inbound"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "SSH from anywhere"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group for Private Server (allow SSH from Bastion only)
resource "aws_security_group" "private_sg" {
  name        = "private_sg"
  description = "Allow SSH from Bastion"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "SSH from Bastion SG"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    security_groups  = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Key Pair (use your existing key or generate one)
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = file("~/.ssh/id_rsa.pub")  # change path as needed
}

# Bastion EC2 Instance
resource "aws_instance" "bastion" {
  ami                         = "ami-0c94855ba95c71c99" # Amazon Linux 2 in us-east-1
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public.id
#   security_group_ids          = [aws_security_group.bastion_sg.id]
  key_name                    = aws_key_pair.deployer.key_name
  associate_public_ip_address = true

  tags = {
    Name = "BastionHost"
  }
}

# Private EC2 Instance
resource "aws_instance" "private" {
  ami                         = "ami-0c94855ba95c71c99" # Amazon Linux 2
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.private.id
#   security_group_ids          = [aws_security_group.private_sg.id]
  key_name                    = aws_key_pair.deployer.key_name
  associate_public_ip_address = false

  tags = {
    Name = "PrivateServer"
  }
}

# Outputs
output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "private_ip" {
  value = aws_instance.private.private_ip
}