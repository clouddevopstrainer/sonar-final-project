pipeline {
    agent any

    environment {
        APP_NAME        = "springboot-app"
        DOCKER_IMAGE    = "your-dockerhub-username/${APP_NAME}"
        DOCKER_TAG      = "v${BUILD_NUMBER}"
        MAVEN_HOME      = tool 'Maven3'
        JAVA_HOME       = tool 'JDK17'
        SONARQUBE_ENV   = 'SonarQubeServer'
        DOCKER_CRED     = 'dockerhub-credentials'
        TERRAFORM_CRED  = 'aws-access-key'
        EC2_KEY_CRED    = 'ec2-key-credentials-id'
        K8S_MANIFEST    = 'k8s/'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/your-org/your-repo.git'
            }
        }

        stage('Build with Maven') {
            steps {
                withEnv(["PATH+MAVEN=${MAVEN_HOME}/bin", "JAVA_HOME=${JAVA_HOME}"]) {
                    sh "mvn clean package -DskipTests"
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv("${SONARQUBE_ENV}") {
                    sh "mvn sonar:sonar -Dsonar.projectKey=${APP_NAME} -Dsonar.java.binaries=target"
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 2, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Build & Push Docker Image') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', "${DOCKER_CRED}") {
                        def app = docker.build("${DOCKER_IMAGE}:${DOCKER_TAG}")
                        app.push()
                        app.push("latest")
                    }
                }
            }
        }

        stage('Terraform Apply Infra') {
            steps {
                withCredentials([usernamePassword(credentialsId: "${TERRAFORM_CRED}", usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    sh '''
                        cd terraform
                        terraform init
                        terraform plan -out=tfplan
                        terraform apply -auto-approve tfplan
                    '''
                }
            }
        }

        stage('Get EC2-2 Public IP') {
            steps {
                script {
                    EC2_PUBLIC_IP = sh(script: 'terraform -chdir=terraform output -raw instance_public_ip', returnStdout: true).trim()
                    echo "EC2-2 Public IP: ${EC2_PUBLIC_IP}"
                }
            }
        }

        stage('Deploy Docker on EC2-2') {
            steps {
                sshagent(credentials: ["${EC2_KEY_CRED}"]) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ubuntu@${EC2_PUBLIC_IP} '
                        docker pull ${DOCKER_IMAGE}:${DOCKER_TAG} &&
                        docker stop ${APP_NAME} || true &&
                        docker rm ${APP_NAME} || true &&
                        docker run -d --name ${APP_NAME} -p 8080:8080 ${DOCKER_IMAGE}:${DOCKER_TAG}
                        '
                    """
                }
            }
        }

        stage('Deploy Kubernetes on EC2-2 (Optional)') {
            steps {
                sshagent(credentials: ["${EC2_KEY_CRED}"]) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ubuntu@${EC2_PUBLIC_IP} '
                        export KUBECONFIG=/home/ubuntu/.kube/config
                        kubectl apply -f ${K8S_MANIFEST} || echo "K8s manifests already applied"
                        '
                    """
                }
            }
        }
    }

    post {
        success {
            echo "✅ Deployment Successful! App is running on EC2-2: ${EC2_PUBLIC_IP}:8080"
        }
        failure {
            echo "❌ Pipeline Failed!"
        }
    }
}
