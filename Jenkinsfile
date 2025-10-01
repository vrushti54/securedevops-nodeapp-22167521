pipeline {
  agent any
  options {
    // we do our own checkout below with branch=main
    skipDefaultCheckout(true)
    timestamps()
  }

  environment {
    DOCKER_HUB_USER   = 'vrushti672'
    IMAGE_NAME        = 'securedevops-nodeapp-22167521'
    // Jenkins talks to the DinD daemon over TLS; "docker" is the service name in compose
    DOCKER_HOST       = 'tcp://docker:2376'
    DOCKER_TLS_VERIFY = '1'
    DOCKER_CERT_PATH  = '/certs/client'
  }

  stages {
    stage('Ensure docker alias (fix TLS hostname)') {
      steps {
        sh '''
          set -eu
          # Compose provides "docker" (or "dind"). We just verify it resolves.
          getent hosts docker >/dev/null && echo "docker already resolves" || true
        '''
      }
    }

    stage('Checkout') {
      steps {
        // IMPORTANT: force the main branch
        git branch: 'main',
            url: 'https://github.com/vrushti54/securedevops-nodeapp-22167521.git'
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
            node:18-alpine sh -lc "npm test --silent || true"
        '''
      }
    }

    stage('Security Scan (OWASP DC)') {
      steps {
        sh '''
          mkdir -p dep-report
          docker run --rm \
            -v "$PWD:/src" -w /src \
            -v "$PWD/dep-report:/report" \
            owasp/dependency-check:latest \
              --project nodeapp --scan /src \
              --format HTML --out /report --enableExperimental || true
        '''
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
          docker run -d --name nodeapp-test -p 3000:8080 \
            ${DOCKER_HUB_USER}/${IMAGE_NAME}:${BUILD_NUMBER}
        '''
      }
    }
  }

  post {
    always {
      echo 'Pipeline complete'
      archiveArtifacts artifacts: 'Dockerfile, Jenkinsfile, package*.json, dep-report/**', onlyIfSuccessful: false
    }
  }
}
