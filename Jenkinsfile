pipeline {
    agent any

    environment {
        APP_NAME        = "springboot-app"
        DOCKER_IMAGE    = "preetz1303/${APP_NAME}"
        DOCKER_TAG      = "v${BUILD_NUMBER}"
        MAVEN_HOME      = tool 'Maven3'
        JAVA_HOME       = tool 'JDK17'
        SONARQUBE_ENV   = 'ec2-token'        // Exact SonarQube server name in Jenkins
        DOCKER_CRED     = 'dockerhub-credentials'
        TERRAFORM_CRED  = 'aws-access-key'
        EC2_KEY_CRED    = 'ec2-key-credentials-id'
        K8S_MANIFEST    = 'k8s/'
    }

    stages {
        stage('Checkout') {
            steps { 
                git branch: 'main', url: 'https://github.com/clouddevopstrainer/sonar-final-project.git'
            }
        }

        stage('Build & SonarQube Analysis') {
            steps {
                withEnv(["PATH+MAVEN=${MAVEN_HOME}/bin", "JAVA_HOME=${JAVA_HOME}"]) {
                    withSonarQubeEnv("${SONARQUBE_ENV}") {
                        sh """
                            ${MAVEN_HOME}/bin/mvn clean verify sonar:sonar \
                            -Dsonar.projectKey=cicd \
                            -Dsonar.projectName='cicd' \
                            -Dsonar.java.binaries=target \
                            -Dsonar.scm.provider=git
                        """
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 20, unit: 'MINUTES') {
                    script {
                        def qg = null
                        retry(5) {
                            qg = waitForQualityGate()
                            if (qg.status == 'PENDING') {
                                echo "SonarQube task pending. Retrying in 30 seconds..."
                                sleep 30
                                error("Retrying pending task")
                            }
                        }
                        echo "SonarQube Quality Gate status: ${qg.status}"
                        if (qg.status != 'OK') {
                            currentBuild.result = 'UNSTABLE'
                            echo "⚠️ Quality Gate failed, but continuing pipeline"
                        }
                    }
                }
            }
        }

        stage('SonarQube Dashboard') {
            steps {
                script {
                    def sonarURL = "http://54.82.107.198/:9000/dashboard?id=cicd" // Replace with actual URL
                    echo "🔗 SonarQube Project Dashboard: ${sonarURL}"
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
                    dir('terraform') {
                        sh 'terraform init'
                        sh 'terraform plan -out=tfplan'
                        sh 'terraform apply -auto-approve tfplan'
                    }
                }
            }
        }

        stage('Get EC2 Public IP') {
            steps {
                script {
                    env.EC2_PUBLIC_IP = sh(script: 'terraform -chdir=terraform output -raw instance_public_ip', returnStdout: true).trim()
                    echo "EC2 Public IP: ${env.EC2_PUBLIC_IP}"
                }
            }
        }

        stage('Deploy Docker on EC2') {
            steps {
                sshagent(credentials: ["${EC2_KEY_CRED}"]) {
                    sh """ssh -o StrictHostKeyChecking=no ubuntu@${env.EC2_PUBLIC_IP} '
                        sudo docker pull ${DOCKER_IMAGE}:${DOCKER_TAG} &&
                        sudo docker stop ${APP_NAME} || true &&
                        sudo docker rm ${APP_NAME} || true &&
                        sudo docker run -d --name ${APP_NAME} -p 8080:8080 ${DOCKER_IMAGE}:${DOCKER_TAG}'
                    """
                }
            }
        }

        stage('Deploy Kubernetes on EC2 (Optional)') {
            steps {
                sshagent(credentials: ["${EC2_KEY_CRED}"]) {
                    sh """ssh -o StrictHostKeyChecking=no ubuntu@${env.EC2_PUBLIC_IP} '
                        if [ -f /home/ubuntu/.kube/config ]; then
                            export KUBECONFIG=/home/ubuntu/.kube/config &&
                            kubectl apply -f ${K8S_MANIFEST} || echo "K8s manifests already applied"
                        else
                            echo "K8s config not found. Skipping K8s deployment."
                        fi
                    '
                    """
                }
            }
        }
    }

    post {
        success { echo "✅ Deployment Successful! App is running on EC2: ${env.EC2_PUBLIC_IP}:8080" }
        unstable { echo "⚠️ Pipeline completed, but Quality Gate failed! Check SonarQube dashboard above." }
        failure { echo "❌ Pipeline Failed!" }
    }
}