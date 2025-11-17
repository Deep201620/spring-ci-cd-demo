pipeline {
    // Defines the default agent for stages without a specific agent block.
    // The Docker build stage will still use this agent, relying on the mounted Docker socket.
    agent any

    options {
        skipDefaultCheckout(false)
        timestamps() // Adds timestamps to the console output
    }

    // 💡 Add the global tools section back to use your Jenkins-managed Maven
        tools {
            maven 'M3_HOME' // M3_HOME must match the Name in your Jenkins configuration
            jdk 'JDK_21'
        }

    // Note: The global 'tools' directive is removed as the tool is now defined per stage.

    stages {
        // 1. Source Code Retrieval
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        // 2. Build and Unit Tests (Uses a dedicated Maven Docker Agent)
        stage('Build and Test') {
            steps {
                script {
                    // 💡 ADDED: Use withEnv to set JAVA_HOME using the JDK_21 tool path
                    withEnv(["JAVA_HOME=${tool('JDK_21')}"]) {
                        echo "JAVA_HOME is set to: $JAVA_HOME" // Optional: for verification
                        // Now run Maven, which relies on JAVA_HOME
                        sh 'mvn clean install'
                    }
                }
            }
        }

        // 3. Docker Image Creation (Reverts to 'agent any' to access the host Docker daemon)
        stage('Docker Build') {
            agent any
            steps {
                // This step relies on the Docker CLI being accessible via the host's Docker socket mount.
                script {
                    sh 'docker build -t spring-ci-cd-demo:latest .'
                    echo "Docker image spring-ci-cd-demo:latest built successfully."
                }
            }
        }

        // 4. Local Run and Verification (Simulating Local Deployment)
        stage('Local Deployment Test') {
            agent any
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
                    // Note: If running this stage inside a container, 'localhost' might not work.
                    // We are running on 'agent any', so 'localhost' should still refer to the host system.
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