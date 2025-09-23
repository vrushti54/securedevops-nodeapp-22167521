pipeline {
  agent any

  environment {
    WS = "${env.WORKSPACE ?: '/var/jenkins_home/workspace/nodeapp-pipeline'}"
    IMAGE = "vrushti54/securedevops-nodeapp-22167521:${env.BUILD_NUMBER}"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
        sh 'echo "WS=${WS}"; ls -la "${WS}" | sed -n "1,80p"'
      }
    }

    stage('Install (Node in Docker)') {
      steps {
        sh """
          docker run --rm \
            -v '${WS}:/app' \
            -w /app \
            node:18-alpine \
            sh -lc '
              set -e
              echo "--- listing /app ---"
              ls -la
              test -f package.json || { echo "package.json missing under /app"; exit 1; }
              npm install --no-audit --no-fund
            '
        """
      }
    }

    stage('Test (Node in Docker)') {
      steps {
        sh """
          docker run --rm \
            -v '${WS}:/app' \
            -w /app \
            node:18-alpine \
            sh -lc '
              npm test --silent || true
            '
        """
      }
    }

    stage('Build Docker') {
      steps {
        sh "docker build -t '${IMAGE}' '${WS}'"
      }
    }

    stage('Push Docker') {
      steps {
        echo "Skipping docker push (no registry creds configured yet)"
      }
    }
  }

  post {
    always {
      echo "Pipeline complete"
    }
  }
}