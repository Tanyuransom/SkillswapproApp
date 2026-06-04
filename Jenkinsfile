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

        stage('Build Docker Images') {
            steps {
                echo 'Building production Docker images...'
                dir('backend') {
                    sh 'docker build -t skillprof-gateway-service:latest ./gateway-service'
                    sh 'docker build -t skillprof-identity-service:latest ./identity-service'
                    sh 'docker build -t skillprof-user-service:latest ./user-service'
                    sh 'docker build -t skillprof-course-service:latest ./course-service'
                }
            }
        }

        stage('Deploy to Production (VPS)') {
            steps {
                echo 'Deploying application to VPS...'
                sshagent([VPS_SSH_CREDENTIALS_ID]) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no ${VPS_USER}@${VPS_HOST} "
                            cd /opt/skillprof &&
                            git pull origin main &&
                            cd backend &&
                            docker-compose down &&
                            docker-compose up -d --build
                        "
                    '''
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline successfully executed! All builds and tests passed, and deployment is complete.'
        }
        failure {
            echo 'Pipeline execution failed. Please check build logs for errors.'
        }
    }
}
