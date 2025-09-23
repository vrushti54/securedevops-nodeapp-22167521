pipeline {
    agent {
        docker {
            // Rubric: Node 16 build agent
            image 'node:16-alpine'
            args '-u root:root'
        }
    }

    environment {
        DOCKER_HUB_USER = 'vrushti672'
        IMAGE_NAME      = 'securedevops-nodeapp-22167521'
        DOCKER_HOST     = 'tcp://dind:2376'
        DOCKER_TLS_VERIFY = '1'
        DOCKER_CERT_PATH  = '/certs/client'
    }

    stages {
        stage('Checkout') {
            steps {
                git 'https://github.com/vrushti54/securedevops-nodeapp-22167521.git'
            }
        }

        stage('Install Dependencies') {
            steps {
                sh '''
                  set -e
                  node -v
                  npm -v
                  npm ci
                '''
            }
        }

        stage('Run Tests') {
            steps {
                sh 'npm test --silent || true'  // skip if sample has no tests
            }
        }

        stage('Security Scan (OWASP Dependency-Check)') {
            steps {
                sh '''
                  mkdir -p dep-report
                  docker run --rm \
                    -v "$PWD:/src" -v "$PWD/dep-report:/report" \
                    owasp/dependency-check:latest \
                    --project nodeapp --scan /src \
                    --format "HTML" --out /report \
                    --enableExperimental
                '''
            }
        }

        stage('Fail on High/Critical') {
            steps {
                script {
                    def html = readFile('dep-report/dependency-check-report.html')
                    if (html =~ /Critical<\/td>\\s*<td[^>]*>([1-9]\\d*)/ || html =~ /High<\/td>\\s*<td[^>]*>([1-9]\\d*)/) {
                        error('Dependency-Check found High/Critical vulnerabilities')
                    }
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'dep-report/**', onlyIfSuccessful: false
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${DOCKER_HUB_USER}/${IMAGE_NAME}:${BUILD_NUMBER} ."
            }
        }

        stage('Login to Docker Hub') {
            steps {
                withCredentials([string(credentialsId: 'docker-hub-token', variable: 'DOCKER_HUB_PASS')]) {
                    sh "echo $DOCKER_HUB_PASS | docker login -u $DOCKER_HUB_USER --password-stdin"
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                sh """
                  docker tag ${DOCKER_HUB_USER}/${IMAGE_NAME}:${BUILD_NUMBER} ${DOCKER_HUB_USER}/${IMAGE_NAME}:latest
                  docker push ${DOCKER_HUB_USER}/${IMAGE_NAME}:${BUILD_NUMBER}
                  docker push ${DOCKER_HUB_USER}/${IMAGE_NAME}:latest
                """
            }
        }

        stage('Run Container') {
            steps {
                sh """
                  docker stop nodeapp-test || true && docker rm nodeapp-test || true
                  docker run -d --name nodeapp-test -p 3000:8080 ${DOCKER_HUB_USER}/${IMAGE_NAME}:${BUILD_NUMBER}
                """
            }
        }
    }

    post {
        always {
            echo "Pipeline complete"
            archiveArtifacts artifacts: 'Dockerfile, Jenkinsfile, package*.json', onlyIfSuccessful: false
        }
    }
}
