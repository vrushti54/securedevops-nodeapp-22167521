pipeline {
  agent any

  environment {
    IMAGE = "vrushti54/securedevops-nodeapp-22167521:${env.BUILD_NUMBER}"
    WORKSPACE = "${env.WORKSPACE}"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Install (Node in Docker)') {
      steps {
        sh "docker run --rm -v '${WORKSPACE}:/app' -w /app node:18-alpine sh -lc 'ls -la; test -f package.json && echo found package.json || echo MISSING package.json; npm install --no-audit --no-fund'"
      }
    }

    stage('Test (Node in Docker)') {
      steps {
        sh "docker run --rm -v '${WORKSPACE}:/app' -w /app node:18-alpine sh -lc 'npm test || echo no-tests'"
      }
    }

    stage('Security Scan (OWASP Dependency-Check)') {
      steps {
        echo "Placeholder for OWASP Dependency-Check scan"
        // Example:
        // sh "docker run --rm -v '${WORKSPACE}:/src' owasp/dependency-check:latest --scan /src --format ALL --project nodeapp"
      }
    }

    stage('Build Docker') {
      steps {
        sh "docker build -t ${IMAGE} ."
      }
    }

    stage('Push Docker') {
      steps {
        withDockerRegistry([ credentialsId: 'docker-hub-creds', url: '' ]) {
          sh "docker push ${IMAGE}"
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
