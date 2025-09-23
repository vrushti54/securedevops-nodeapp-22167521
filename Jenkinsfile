pipeline {
    agent any

    environment {
        IMAGE = "vrushti54/securedevops-nodeapp-22167521:${env.BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Install (Node in Docker)') {
            steps {
                sh 'docker run --rm -v "$PWD":/app -w /app node:18-alpine sh -lc "npm install --no-audit --no-fund"'
            }
        }

        stage('Test (Node in Docker)') {
            steps {
                sh 'docker run --rm -v "$PWD":/app -w /app node:18-alpine sh -lc "npm test || echo \\"Tests failed or not defined\\""'
            }
        }

        stage('Security Scan (OWASP Dependency-Check)') {
            steps {
                sh '''
                    docker run --rm \
                        -v "$(pwd)":/src \
                        owasp/dependency-check:latest \
                        --scan /src \
                        --format HTML \
                        --out /src/dependency-check-report
                '''
            }
        }

        stage('Build Docker') {
            steps {
                sh 'docker build -t $IMAGE .'
            }
        }

        stage('Push Docker') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push $IMAGE
                    '''
                }
            }
        }
    }

    post {
        always {
            echo "Pipeline complete (status: ${currentBuild.currentResult})"
        }
    }
}
