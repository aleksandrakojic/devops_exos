provider "aws" {
  region = "us-east-1"
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "ubuntu_sg" {
  name        = "ubuntu-vm-sg"
  description = "Allow SSH inbound traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ubuntu_vm" {
  ami           = "ami-0c02fb55956c7d316" # Ubuntu 22.04 LTS in us-east-1
  instance_type = "t2.micro"
  key_name      = "terraform-key"         # Replace with your AWS key pair name

  vpc_security_group_ids = [aws_security_group.ubuntu_sg.id]

  tags = {
    Name = "Terraform-Ubuntu-VM"
  }
}

output "instance_public_ip" {
  description = "Public IP of the Ubuntu EC2 instance"
  value       = aws_instance.ubuntu_vm.public_ip
}

output "instance_id" {
  description = "ID of the Ubuntu EC2 instance"
  value       = aws_instance.ubuntu_vm.id
}