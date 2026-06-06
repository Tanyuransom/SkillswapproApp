pipeline {
    agent any

    environment {
        DOCKER_REGISTRY = 'registry.hub.docker.com'
        DOCKER_CREDENTIALS_ID = 'docker-hub-credentials'
        VPS_SSH_CREDENTIALS_ID = 'vps-ssh-credentials'
        VPS_HOST = '167.86.100.54'
        APP_DIR = '/opt/skillprof'
    }

    stages {
        stage('Pull Latest Code on VPS') {
            steps {
                echo 'Pulling code from Git repository on VPS host...'
                withCredentials([sshUserPrivateKey(credentialsId: VPS_SSH_CREDENTIALS_ID, keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')]) {
                    sh '''
                        ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no ${SSH_USER}@${VPS_HOST} "
                            cd ${APP_DIR} &&
                            git fetch origin &&
                            git reset --hard origin/main
                        "
                    '''
                }
            }
        }

        stage('Install Dependencies on Host') {
            steps {
                echo 'Installing workspace dependencies on VPS host...'
                withCredentials([sshUserPrivateKey(credentialsId: VPS_SSH_CREDENTIALS_ID, keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')]) {
                    sh '''
                        ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no ${SSH_USER}@${VPS_HOST} "
                            cd ${APP_DIR}/backend &&
                            npm install --workspaces
                        "
                    '''
                }
            }
        }

        stage('Run Tests on Host') {
            steps {
                echo 'Running tests on VPS host...'
                withCredentials([sshUserPrivateKey(credentialsId: VPS_SSH_CREDENTIALS_ID, keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')]) {
                    sh '''
                        ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no ${SSH_USER}@${VPS_HOST} "
                            cd ${APP_DIR}/backend &&
                            npm run test --workspaces --if-present
                        "
                    '''
                }
            }
        }

        stage('Build Project on Host') {
            steps {
                echo 'Compiling project on VPS host...'
                withCredentials([sshUserPrivateKey(credentialsId: VPS_SSH_CREDENTIALS_ID, keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')]) {
                    sh '''
                        ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no ${SSH_USER}@${VPS_HOST} "
                            cd ${APP_DIR}/backend &&
                            npm run build --workspaces --if-present
                        "
                    '''
                }
            }
        }

        stage('Build Docker Images on Host') {
            steps {
                echo 'Building Docker images on VPS host...'
                withCredentials([sshUserPrivateKey(credentialsId: VPS_SSH_CREDENTIALS_ID, keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')]) {
                    sh '''
                        ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no ${SSH_USER}@${VPS_HOST} "
                            cd ${APP_DIR}/backend &&
                            docker build -t tanyuransom/skillprof-gateway-service:latest ./gateway-service &&
                            docker build -t tanyuransom/skillprof-identity-service:latest ./identity-service &&
                            docker build -t tanyuransom/skillprof-user-service:latest ./user-service &&
                            docker build -t tanyuransom/skillprof-course-service:latest ./course-service
                        "
                    '''
                }
            }
        }

        stage('Push Docker Images to Docker Hub') {
            steps {
                echo 'Logging in and pushing images from VPS host...'
                withCredentials([
                    usernamePassword(credentialsId: DOCKER_CREDENTIALS_ID, usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASSWORD'),
                    sshUserPrivateKey(credentialsId: VPS_SSH_CREDENTIALS_ID, keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')
                ]) {
                    sh '''
                        ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no ${SSH_USER}@${VPS_HOST} "
                            docker login -u ${DOCKER_USER} -p ${DOCKER_PASSWORD} ${DOCKER_REGISTRY} &&
                            docker push tanyuransom/skillprof-gateway-service:latest &&
                            docker push tanyuransom/skillprof-identity-service:latest &&
                            docker push tanyuransom/skillprof-user-service:latest &&
                            docker push tanyuransom/skillprof-course-service:latest
                        "
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes (VPS)') {
            steps {
                echo 'Deploying manifests and restarting deployments on VPS K3s...'
                withCredentials([sshUserPrivateKey(credentialsId: VPS_SSH_CREDENTIALS_ID, keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')]) {
                    sh '''
                        ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no ${SSH_USER}@${VPS_HOST} "
                            cd ${APP_DIR} &&
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
            echo 'Pipeline successfully executed!'
        }
        failure {
            echo 'Pipeline execution failed.'
        }
    }
}
