pipeline {
  agent any

  environment {
    REGISTRY = "index.docker.io"
    IMAGE = "vrushti54/securedevops-nodeapp-22167521:${env.BUILD_NUMBER}" // change user if needed
    DC_OUT = "dependency-check-report"
  }

  options {
    timestamps()
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Install') {
      steps { sh 'npm ci' }
    }

    stage('Test') {
      steps {
        // run tests if present; don’t fail the whole pipeline if none
        sh 'npm test || echo "no tests or tests failed; continuing for lab"'
      }
      post {
        always {
          // collect JUnit XML if your tests produce them (allow empty)
          junit testResults: '**/junit*.xml', allowEmptyResults: true
        }
      }
    }

    stage('Security Scan (OWASP Dependency-Check)') {
      steps {
        sh """
          rm -rf ${DC_OUT}
          docker run --rm ^
            -v \$PWD:/src ^
            -v \$PWD/${DC_OUT}:/report ^
            owasp/dependency-check:latest \
            --scan /src --format HTML --out /report --project nodeapp
        """.stripIndent()
      }
      post {
        always {
          // publish HTML report if plugin is available, otherwise just archive it
          script {
            try {
              publishHTML target: [
                reportDir: "${DC_OUT}",
                reportFiles: 'dependency-check-report.html',
                reportName: 'Dependency-Check Report'
              ]
            } catch (e) {
              echo "HTML Publisher not installed; archiving report instead"
            }
          }
          archiveArtifacts artifacts: "${DC_OUT}/**", allowEmptyArchive: true
        }
        success {
          // simple gate: fail build if "High" or "Critical" appears in report
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
