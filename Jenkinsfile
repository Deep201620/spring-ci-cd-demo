pipeline {
    // Defines where the pipeline will execute.
    // 'any' uses any available Jenkins agent/executor.
    // For production, you might specify a Docker image (e.g., 'docker { image "maven:3.9.5-eclipse-temurin-21" }')
    agent any

    options {
        // Keeps the build clean by deleting workspaces after the build is finished
        // Note: For local development, this might slow down subsequent builds if caching is not used well.
        skipDefaultCheckout(false)
        timestamps() // Adds timestamps to the console output
    }

    stages {
        // 1. Source Code Retrieval
        stage('Checkout Code') {
            steps {
                // Assuming the repository is configured in Jenkins job SCM settings
                checkout scm
            }
        }

        // 2. Build and Unit Tests
        stage('Build and Test') {
            steps {
                // Ensure Maven is available on the Jenkins agent or installed via Tool Configuration
                sh 'mvn clean install'
            }
        }

        // 3. Docker Image Creation
        stage('Docker Build') {
            steps {
                // Assuming Docker CLI is installed and accessible on the Jenkins agent
                script {
                    sh 'docker build -t spring-ci-cd-demo:latest .'
                    echo "Docker image spring-ci-cd-demo:latest built successfully."
                }
            }
        }

        // 4. Local Run and Verification (Simulating Local Deployment)
        stage('Local Deployment Test') {
            // Only runs if the previous stages succeeded
            when {
                expression { currentBuild.result == null || currentBuild.result == 'SUCCESS' }
            }
            steps {
                script {
                    echo "Starting temporary container for testing..."

                    // Stop and remove any existing container instance with the same name
                    sh 'docker stop spring-demo-app || true'
                    sh 'docker rm spring-demo-app || true'

                    // Run the new container in detached mode
                    sh 'docker run -d --name spring-demo-app -p 8080:8080 spring-ci-cd-demo:latest'

                    // Wait for the Spring Boot app to initialize
                    sleep 10

                    // Test the application endpoint using curl
                    echo "Testing application endpoint..."
                    def response = sh(returnStdout: true, script: 'curl -s http://localhost:8080/')

                    if (response.contains("Hello from Spring Boot")) {
                        echo "Deployment Test Passed: Application is running and responding correctly."
                    } else {
                        error "Deployment Test Failed: Did not receive expected greeting."
                    }
                }
            }
            // Cleanup the test container regardless of the test result
            post {
                always {
                    echo "Cleaning up test container..."
                    sh 'docker stop spring-demo-app'
                    sh 'docker rm spring-demo-app'
                }
            }
        }
    }
}