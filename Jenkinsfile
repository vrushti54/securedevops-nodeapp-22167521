pipeline {
  agent any

  environment {
    DOCKER_HUB_USER   = 'vrushti672'
    IMAGE_NAME        = 'securedevops-nodeapp-22167521'

    // ---- talk to DinD securely with the hostname the cert was issued for ----
    DOCKER_HOST       = 'tcp://docker:2376'
    DOCKER_TLS_VERIFY = '1'
    DOCKER_CERT_PATH  = '/certs/client'
  }

  options {
    timestamps()
  }

  stages {
    stage('Ensure docker alias (fix TLS hostname)') {
      steps {
        // Create a hosts entry so "docker" resolves even if compose doesn’t alias it.
        sh '''
          set -eu
          if getent hosts docker >/dev/null 2>&1; then
            echo "docker already resolves"
          else
            ip="$(getent hosts dind | awk '{print $1}')"
            echo "$ip docker" >> /etc/hosts
            echo "Added hosts alias: $ip docker"
            getent hosts docker
          fi
        '''
      }
    }

    stage('Checkout') {
      steps {
        git 'https://github.com/vrushti54/securedevops-nodeapp-22167521.git'
      }
    }

    stage('Install (Node in Docker)') {
      steps {
        sh '''
          set -e
          echo "--- using Node inside Docker ---"
          docker run --rm \
            -v "$PWD:/app" -w /app \
            node:18-alpine sh -lc '
              node -v
              npm -v
              npm ci
            '
        '''
      }
    }

    stage('Test (Node in Docker)') {
      steps {
        sh '''
          docker run --rm \
            -v "$PWD:/app" -w /app \
            node:18-alpine sh -lc '
              npm test --silent || true
            '
        '''
      }
    }

    stage('Security Scan (OWASP DC)') {
      steps {
        sh '''
          mkdir -p dep-report
          docker run --rm \
            -v "$PWD:/src" \
            -v "$PWD/dep-report:/report" \
            -v /var/jenkins_home/owasp-data:/usr/share/dependency-check/data \
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
          if (html =~ /Critical<\/td>\s*<td[^>]*>([1-9]\d*)/ ||
              html =~ /High<\/td>\s*<td[^>]*>([1-9]\d*)/) {
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
        sh 'docker build -t ${DOCKER_HUB_USER}/${IMAGE_NAME}:${BUILD_NUMBER} .'
      }
    }

    stage('Login to Docker Hub') {
      steps {
        withCredentials([string(credentialsId: 'docker-hub-token', variable: 'DOCKER_HUB_PASS')]) {
          sh 'echo "$DOCKER_HUB_PASS" | docker login -u "$DOCKER_HUB_USER" --password-stdin'
        }
      }
    }

    stage('Push Docker Image') {
      steps {
        sh '''
          docker tag ${DOCKER_HUB_USER}/${IMAGE_NAME}:${BUILD_NUMBER} ${DOCKER_HUB_USER}/${IMAGE_NAME}:latest
          docker push ${DOCKER_HUB_USER}/${IMAGE_NAME}:${BUILD_NUMBER}
          docker push ${DOCKER_HUB_USER}/${IMAGE_NAME}:latest
        '''
      }
    }

    stage('Run Container (port 3000 -> 8080)') {
      steps {
        sh '''
          docker stop nodeapp-test || true
          docker rm   nodeapp-test || true
          docker run -d --name nodeapp-test -p 3000:8080 ${DOCKER_HUB_USER}/${IMAGE_NAME}:${BUILD_NUMBER}
        '''
      }
    }
  }

  post {
    always {
      echo 'Pipeline complete'
      archiveArtifacts artifacts: 'Dockerfile, Jenkinsfile, package*.json', onlyIfSuccessful: false
    }
  }
}
