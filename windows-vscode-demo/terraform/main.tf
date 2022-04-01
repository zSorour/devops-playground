terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket                  = "windows-vs-demo-backend-state-unique"
    workspace_key_prefix    = "exam-name"
    key                     = "backend-state"
    region                  = "eu-central-1"
    dynamodb_table          = "windows-vs-demo_locks"
    encrypt                 = true
    shared_credentials_file = "/home/zsorour/.aws/creds"
  }

}

provider "aws" {
  region                   = "eu-central-1"
  shared_credentials_files = ["/home/zsorour/.aws/creds"]
}


# let terraform adopt my default vpc on AWS so that I can use its data
# instead of hardcoding the values later on.
resource "aws_default_vpc" "default_vpc" {
  tags = {
    Name = "Default VPC"
  }
}


# create security group
resource "aws_security_group" "windows_instance_sg" {
  name   = "windows_instance_sg_${terraform.workspace}"
  vpc_id = aws_default_vpc.default_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5986
    to_port     = 5986
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5900
    to_port     = 5900
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 6080
    to_port     = 6080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "name" = "windows_instance_sg"
  }
}


# Creating a random password
resource "random_string" "instance_password" {
  length  = 12
  special = false
}


# Creating an EC2 Instance
resource "aws_instance" "windows_instance" {
  ami                    = data.aws_ami.windows-vs-ami.id
  key_name               = "default-ec2"
  instance_type          = "c5.xlarge"
  vpc_security_group_ids = [aws_security_group.windows_instance_sg.id]
  subnet_id              = tolist(data.aws_subnets.default_subnets.ids)[0]

  ebs_block_device {
    volume_size           = 100
    device_name           = "/dev/sda1"
    delete_on_termination = true
  }

  connection {
    type     = "winrm"
    user     = "admin"
    password = "testing@Password1"
    host     = self.public_ip
    insecure = true
    https    = true
  }

  provisioner "remote-exec" {
    inline = [
      "powershell net user student ${random_string.instance_password.result}",
      "powershell Remove-Item -Path 'C:\\Users\\admin\\Desktop\\EC2 Feedback.website'",
      "powershell Remove-Item -Path 'C:\\Users\\admin\\Desktop\\EC2 Microsoft Windows Guide.website'"
    ]
  }

}
