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
    exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

    apt update -y
    apt install -y curl git nodejs npm nginx

    # Install latest Node.js
    npm install -g n
    n stable

    # Clone your repo (fresh every time)
    rm -rf /home/ubuntu/reactapp
    git clone https://github.com/${var.github_username}/${var.github_repo}.git /home/ubuntu/reactapp
    cd /home/ubuntu/reactapp

    # Install deps & build React
    npm install
    npm run build

    # Replace nginx root with React build
    rm -rf /var/www/html/*
    cp -r build/* /var/www/html/

    # Restart nginx
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
