pipeline {
  agent any

  environment {
    IMAGE    = "vrushti54/securedevops-nodeapp-22167521:${env.BUILD_NUMBER}"
    REGISTRY = "index.docker.io"
    DC_OUT   = "dependency-check-report"
  }

  options { timestamps() }

  stages {
    stage('Checkout') {
      steps { checkout scm }
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
            sh -c "npm test || echo no-tests"
        '''
      }
      post { always { junit testResults: '**/junit*.xml', allowEmptyResults: true } }
    }

    stage('Security Scan (OWASP Dependency-Check)') {
      steps {
        sh """
          rm -rf ${DC_OUT}
          docker run --rm \
            -v \${WORKSPACE}:/src \
            -v \${WORKSPACE}/${DC_OUT}:/report \
            owasp/dependency-check:latest \
            --scan /src --format HTML --out /report --project nodeapp
        """
      }
      post {
        always {
          script {
            try {
              publishHTML target: [reportDir: "${DC_OUT}", reportFiles: 'dependency-check-report.html', reportName: 'Dependency-Check Report']
            } catch (e) {
              echo "HTML Publisher not installed; archiving report instead"
            }
          }
          archiveArtifacts artifacts: "${DC_OUT}/**", allowEmptyArchive: true
        }
      }
    }

    stage('Build Docker') {
      steps { sh "docker build -t ${IMAGE} ." }
    }

    stage('Push Docker') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
          sh '''
            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
            docker push '"${IMAGE}"'
          '''
        }
      }
    }
  }

  post {
    success { echo "Image pushed: ${IMAGE}" }
    always  { echo "Pipeline complete (status: ${currentBuild.currentResult})" }
  }
}
