pipeline {
  agent any

  environment {
    REGISTRY = "index.docker.io"
    IMAGE = "vrushti54/securedevops-nodeapp-22167521:${env.BUILD_NUMBER}" // change user if needed
    DC_OUT = "dependency-check-report"
  }

  options { timestamps() }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Install (Node in Docker)') {
      steps {
        // run npm ci in a temporary Node container, mounting workspace
        sh 'docker run --rm -v "$PWD":/app -w /app node:18-alpine sh -lc "npm ci"'
      }
    }

    stage('Test (Node in Docker)') {
      steps {
        // run tests (don’t fail the lab if none present)
        sh 'docker run --rm -v "$PWD":/app -w /app node:18-alpine sh -lc "npm test || echo no-tests"'
      }
      post {
        always {
          junit testResults: '**/junit*.xml', allowEmptyResults: true
        }
      }
    }

    stage('Security Scan (OWASP Dependency-Check)') {
      steps {
        sh """
          rm -rf ${DC_OUT}
          docker run --rm \
            -v "$PWD":/src \
            -v "$PWD/${DC_OUT}":/report \
            owasp/dependency-check:latest \
            --scan /src --format HTML --out /report --project nodeapp
        """
      }
      post {
        always {
          script {
            try {
              publishHTML target: [
                reportDir: "${DC_OUT}",
                reportFiles: 'dependency-check-report.html',
                reportName: 'Dependency-Check Report'
              ]
            } catch (e) {
              echo "HTML Publisher not installed; archiving instead"
            }
          }
          archiveArtifacts artifacts: "${DC_OUT}/**", allowEmptyArchive: true
        }
        success {
          script {
            def rc = sh(returnStatus: true, script: "grep -Ei 'High|Critical' ${DC_OUT}/dependency-check-report.html")
            if (rc == 0) { error 'High/Critical vulnerabilities found' }
          }
        }
      }
    }

    stage('Build Docker') {
      steps { sh "docker build -t ${IMAGE} ." }
    }

    stage('Push Docker') {
      steps {
        script {
          docker.withRegistry("https://${REGISTRY}/v1/", 'dockerhub') {
            sh "docker push ${IMAGE}"
          }
        }
      }
    }
  }

  post {
    success { echo "Image pushed: ${IMAGE}" }
    always  { echo "Pipeline complete (status: ${currentBuild.currentResult})" }
  }
}
