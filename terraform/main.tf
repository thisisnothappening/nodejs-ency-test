provider "aws" {
  region = "eu-north-1"
}

resource "aws_security_group" "my_security_group" {
  name        = "my-security-group"
  description = "My security group"
  vpc_id      = "vpc-02698e4f80102fd40"

  ingress {
  	from_port   = 22
  	to_port     = 22
  	protocol    = "tcp"
  	cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
	from_port 	= 3000
	to_port 	= 3000
	protocol 	= "tcp"
	cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
	from_port 	= 8080
	to_port 	= 8080
	protocol 	= "tcp"
	cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
  	from_port   = 0
  	to_port     = 0
  	protocol    = "all"
  	cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "encyclopedia_docker" {
  ami             = "ami-0989fb15ce71ba39e" // Ubuntu
  instance_type   = "t3.micro"
  key_name        = "aws_vm_key"
  security_groups = [aws_security_group.my_security_group.name]
  tags = {
	Name = "Welcomepedia in Docker"
  }

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }
}

resource "aws_eip" "my_elastic_ip" {
  vpc = true
  instance = aws_instance.encyclopedia_docker.id
}
