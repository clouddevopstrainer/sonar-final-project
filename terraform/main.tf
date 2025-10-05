provider "aws" {
  region = var.region
}

# ------------------------------
# Security Group
# ------------------------------
resource "aws_security_group" "devnw5_sg" {
  name        = "dev-sgnw5"
  description = "Allow SSH, HTTP, NodePort, Prometheus, Grafana"

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

  ingress {
    description = "Prometheus"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Grafana"
    from_port   = 3000
    to_port     = 3000
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
    Name = "devnw5_sg"
  }
}

# ------------------------------
# EC2 Instance
# ------------------------------
resource "aws_instance" "app5_servernew" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.devnw5_sg.id]

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

              usermod -aG docker ubuntu
              newgrp docker
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
              rm -f minikube-linux-amd64 kubectl

              # -------------------
              # Setup Prometheus
              # -------------------
              mkdir -p /opt/prometheus
              cat <<EOPROM > /opt/prometheus/prometheus.yml
              global:
                scrape_interval: 15s

              scrape_configs:
                - job_name: 'prometheus'
                  static_configs:
                    - targets: ['localhost:9090']
              EOPROM

              docker run -d \
                --name prometheus \
                -p 9090:9090 \
                -v /opt/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml \
                prom/prometheus

              # -------------------
              # Setup Grafana
              # -------------------
              docker run -d \
                --name grafana \
                -p 3000:3000 \
                grafana/grafana

              EOF

  tags = {
    Name = "app5_servernew"
  }
}

# ------------------------------
# Output
# ------------------------------
output "instance_public_ip" {
  value = aws_instance.app5_servernew.public_ip
}
