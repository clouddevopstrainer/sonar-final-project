provider "aws" {
  region = var.region
}

# ------------------------------
# Security Group
# ------------------------------
resource "aws_security_group" "devnw4_sg" {
  name        = "dev-sgnw1"
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
    Name = "devnw3_sg"
  }
}

# ------------------------------
# EC2 Instance
# ------------------------------
resource "aws_instance" "app3_servernew1" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.devnw4_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              set -e

              # Log setup
              exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

              echo "===== Updating system ====="
              apt update -y
              apt upgrade -y

              echo "===== Installing Docker ====="
              apt install -y ca-certificates curl gnupg lsb-release
              mkdir -p /etc/apt/keyrings
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
              echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list

              apt update -y
              apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

              systemctl enable docker
              systemctl start docker

              echo "===== Waiting for Docker to be ready ====="
              sleep 10

              echo "===== Pulling Prometheus and Grafana images ====="
              docker pull prom/prometheus
              docker pull grafana/grafana

              echo "===== Creating Prometheus config ====="
              mkdir -p /opt/prometheus
              cat <<EOPROM > /opt/prometheus/prometheus.yml
              global:
                scrape_interval: 15s

              scrape_configs:
                - job_name: 'prometheus'
                  static_configs:
                    - targets: ['localhost:9090']
              EOPROM

              echo "===== Starting Prometheus container ====="
              docker run -d \
                --restart always \
                --name prometheus \
                -p 9090:9090 \
                -v /opt/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml \
                prom/prometheus

              echo "===== Starting Grafana container ====="
              docker run -d \
                --restart always \
                --name grafana \
                -p 3000:3000 \
                grafana/grafana

              echo "===== Setup complete ====="
              EOF

  tags = {
    Name = "app3_servernew1"
  }
}

# ------------------------------
# Output
# ------------------------------
output "instance_public_ip" {
  value       = aws_instance.app3_servernew1.public_ip
  description = "Public IP of the EC2 instance"
}

output "prometheus_url" {
  value       = "http://${aws_instance.app3_servernew1.public_ip}:9090"
  description = "Prometheus Web UI"
}

output "grafana_url" {
  value       = "http://${aws_instance.app3_servernew1.public_ip}:3000"
  description = "Grafana Web UI"
}
