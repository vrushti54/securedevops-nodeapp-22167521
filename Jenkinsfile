pipeline {
    environment {
        DOCKER_IMAGE = 'vrushti672/securedevops-nodeapp-22167521'
    }

    agent {
        docker {
            image 'node:16-alpine'
            args '-u 1000:1000 -v /usr/local/bin/docker:/usr/local/bin/docker:ro'
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
                echo 'Verifying Docker CLI and Docker-in-Docker connection...'
                sh '''
                    node --version
                    npm --version
                    docker --version
                    docker -H tcp://172.17.0.1:2375 info --format "Docker Server: {{.ServerVersion}}"
                '''

                echo 'Building Docker application image...'
                sh 'docker -H tcp://172.17.0.1:2375 build -t $DOCKER_IMAGE:$BUILD_NUMBER .'
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
                        echo "$DOCKERHUB_TOKEN" | docker -H tcp://172.17.0.1:2375 login -u "$DOCKERHUB_USERNAME" --password-stdin
                        docker -H tcp://172.17.0.1:2375 push $DOCKER_IMAGE:$BUILD_NUMBER
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
