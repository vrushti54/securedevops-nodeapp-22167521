pipeline {
  agent any

  environment {
    IMAGE = "vrushti54/securedevops-nodeapp-22167521:${env.BUILD_NUMBER}"
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Build Docker') {
      steps { sh "docker build -t ${IMAGE} ." }
    }
  }
}
