provider "aws" {
  region = var.region
}

# ------------------------------
# Security Group
# ------------------------------
resource "aws_security_group" "devnw4_sg" {
  name        = "dev-sgnw1"
  description = "Allow SSH, HTTP, NodePort, Grafana"

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

              echo "===== Installing Grafana OSS ====="
              apt-get install -y apt-transport-https software-properties-common wget
              mkdir -p /etc/apt/keyrings/
              wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | tee /etc/apt/keyrings/grafana.gpg > /dev/null
              echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | tee -a /etc/apt/sources.list.d/grafana.list
              apt-get update
              apt-get install -y grafana

              echo "===== Starting Grafana ====="
              systemctl enable grafana-server
              systemctl start grafana-server

              echo "===== Grafana Setup Complete ====="
              EOF

  tags = {
    Name = "app3_servernew1"
  }
}

# ------------------------------
# Outputs
# ------------------------------
output "instance_public_ip" {
  value       = aws_instance.app3_servernew1.public_ip
  description = "Public IP of the EC2 instance"
}

output "grafana_url" {
  value       = "http://${aws_instance.app3_servernew1.public_ip}:3000"
  description = "Grafana Web UI"
}
