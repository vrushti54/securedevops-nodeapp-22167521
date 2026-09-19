pipeline {
    environment {
        DOCKER_IMAGE = 'vrushti672/securedevops-nodeapp-22167521'
    }

    agent {
        docker {
            image 'node:16'
        }
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out application source code...'
                checkout scm
            }
        }

        stage('Install Dependencies') {
            steps {
                echo 'Installing Node.js dependencies...'
                sh 'npm ci'
            }
        }

        stage('Unit Tests') {
            steps {
                echo 'Running unit tests...'
                sh 'npm test'
            }
        }

        stage('Dependency Vulnerability Scan') {
            steps {
                echo 'Scanning dependencies for High and Critical vulnerabilities...'
                sh 'npm audit --audit-level=high'
            }
        }

        stage('Docker Build') {
            steps {
                echo 'Installing Docker CLI in Node 16 build agent...'
                sh '''
                    apt-get update
                    apt-get install -y docker.io
                    docker --version
                '''

                echo 'Building Docker application image...'
                sh 'docker build -t $DOCKER_IMAGE:$BUILD_NUMBER .'
            }
        }

        stage('Docker Push') {
            steps {
                echo 'Authenticating to Docker Hub and pushing image...'
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-credentials',
                    usernameVariable: 'DOCKERHUB_USERNAME',
                    passwordVariable: 'DOCKERHUB_TOKEN'
                )]) {
                    sh '''
                        echo "$DOCKERHUB_TOKEN" | docker login -u "$DOCKERHUB_USERNAME" --password-stdin
                        docker push $DOCKER_IMAGE:$BUILD_NUMBER
                    '''
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully.'
        }

        failure {
            echo 'Pipeline failed. Review the Jenkins console output.'
        }
    }
}
