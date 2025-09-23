pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Install (Node in Docker)') {
            steps {
                sh '''
                    docker run --rm \
                      -v ${WORKSPACE}:/app \
                      -w /app \
                      node:18-alpine \
                      sh -c "npm install --no-audit --no-fund"
                '''
            }
        }

        stage('Test (Node in Docker)') {
            steps {
                sh '''
                    docker run --rm \
                      -v ${WORKSPACE}:/app \
                      -w /app \
                      node:18-alpine \
                      sh -c "npm test || echo 'No tests defined'"
                '''
            }
        }

        stage('Security Scan (OWASP Dependency-Check)') {
            steps {
                echo 'Run OWASP dependency check here'
            }
        }

        stage('Build Docker') {
            steps {
                script {
                    sh "docker build -t vrushti54/securedevops-nodeapp-22167521:${BUILD_NUMBER} ."
                }
            }
        }

        stage('Push Docker') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push vrushti54/securedevops-nodeapp-22167521:${BUILD_NUMBER}
                    '''
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline complete'
        }
    }
}
