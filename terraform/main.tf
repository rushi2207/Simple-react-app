provider "aws" {
  region = var.aws_region
}

resource "aws_instance" "react_app" {
  ami           = "ami-08c40ec9ead489470" # Ubuntu 22.04 (check region)
  instance_type = "t2.micro"
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.react_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    apt update -y
    apt install -y curl git nodejs npm nginx

    # Get latest node
    npm install -g n
    n stable

    # Clone your repo
    git clone https://github.com/${var.github_username}/${var.github_repo}.git /home/ubuntu/reactapp
    cd /home/ubuntu/reactapp

    # Build react app
    npm install
    npm run build

    # Serve with nginx
    rm -rf /var/www/html/*
    cp -r build/* /var/www/html/

    systemctl enable nginx
    systemctl restart nginx
  EOF

  tags = {
    Name = "react-app-server"
  }
}

resource "aws_security_group" "react_sg" {
  name        = "react-sg"
  description = "Allow HTTP and SSH"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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
