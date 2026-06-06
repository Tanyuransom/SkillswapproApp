pipeline {
    agent any

    environment {
        DOCKER_REGISTRY = 'registry.hub.docker.com'
        DOCKER_CREDENTIALS_ID = 'docker-hub-credentials'
        VPS_SSH_CREDENTIALS_ID = 'vps-ssh-credentials'
        VPS_HOST = '167.86.100.54'
        VPS_USER = 'root'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/Tanyuransom/SkillswapproApp.git'
            }
        }

        stage('Install Dependencies') {
            steps {
                echo 'Installing workspace dependencies...'
                dir('backend') {
                    sh 'npm install --workspaces'
                }
            }
        }

        stage('Run Tests') {
            steps {
                echo 'Running unit and integration tests...'
                dir('backend') {
                    // Triggers test scripts in identity-service and other tested services
                    sh 'npm run test --workspaces --if-present'
                }
            }
        }

        stage('Build Project') {
            steps {
                echo 'Compiling project source files...'
                dir('backend') {
                    sh 'npm run build --workspaces --if-present'
                }
            }
        }

        stage('Build Docker Images') {
            steps {
                echo 'Building production Docker images...'
                dir('backend') {
                    sh 'docker build -t tanyuransom/skillprof-gateway-service:latest ./gateway-service'
                    sh 'docker build -t tanyuransom/skillprof-identity-service:latest ./identity-service'
                    sh 'docker build -t tanyuransom/skillprof-user-service:latest ./user-service'
                    sh 'docker build -t tanyuransom/skillprof-course-service:latest ./course-service'
                }
            }
        }

        stage('Push Docker Images') {
            steps {
                echo 'Pushing Docker images to Docker Hub...'
                withCredentials([usernamePassword(credentialsId: DOCKER_CREDENTIALS_ID, usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASSWORD')]) {
                    sh "docker login -u ${DOCKER_USER} -p ${DOCKER_PASSWORD} ${DOCKER_REGISTRY}"
                    sh "docker push tanyuransom/skillprof-gateway-service:latest"
                    sh "docker push tanyuransom/skillprof-identity-service:latest"
                    sh "docker push tanyuransom/skillprof-user-service:latest"
                    sh "docker push tanyuransom/skillprof-course-service:latest"
                }
            }
        }

        stage('Deploy to Kubernetes (VPS)') {
            steps {
                echo 'Deploying application to Kubernetes on VPS...'
                sshagent([VPS_SSH_CREDENTIALS_ID]) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no ${VPS_USER}@${VPS_HOST} "
                            cd /opt/skillprof &&
                            git pull origin main &&
                            kubectl apply -f k8s/databases-k8s.yaml &&
                            kubectl apply -f k8s/services-k8s.yaml &&
                            kubectl apply -f k8s/gateway-k8s.yaml &&
                            kubectl rollout restart deployment/gateway-service &&
                            kubectl rollout restart deployment/identity-service &&
                            kubectl rollout restart deployment/user-service &&
                            kubectl rollout restart deployment/course-service
                        "
                    '''
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline successfully executed! All builds, tests, pushes, and Kubernetes deployments are complete.'
        }
        failure {
            echo 'Pipeline execution failed. Please check build logs for errors.'
        }
    }
}
