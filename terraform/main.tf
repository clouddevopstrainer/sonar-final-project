provider "aws" {
  region = var.region
}

# Security group to allow SSH, HTTP, NodePort
resource "aws_security_group" "devnw3_sg" {
  name        = "dev-sgnw"
  description = "Allow SSH, HTTP, NodePort"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "App HTTP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Kubernetes NodePort"
    from_port   = 30080
    to_port     = 30080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "devnw3_sg"
  }
}

# EC2 instance for app deployment
resource "aws_instance" "app3_servernew" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.devnw3_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              set -e

              # Update system
              apt update -y
              apt upgrade -y

              # -------------------
              # Install Docker
              # -------------------
              apt install -y ca-certificates curl gnupg lsb-release
              mkdir -p /etc/apt/keyrings
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
              echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
              apt update -y
              apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

              # Add ubuntu user to docker group
              usermod -aG docker ubuntu

              # Enable & start Docker
              systemctl enable docker
              systemctl start docker

              # -------------------
              # Install Minikube
              # -------------------
              curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
              install minikube-linux-amd64 /usr/local/bin/minikube

              # -------------------
              # Install kubectl
              # -------------------
              curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
              install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

              # Cleanup
              rm -f minikube-linux-amd64 kubectl
              EOF

  tags = {
    Name = "app3_servernew"
  }
}

# Output public IP
output "instance_public_ip" {
  value = aws_instance.app3_servernew.public_ip
}
