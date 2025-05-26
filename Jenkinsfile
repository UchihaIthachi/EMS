pipeline {
    agent any // Or a specific agent label

    environment {
        NEXUS_URL = 'http://your-nexus-url/repository/maven-releases/' // Example
        NEXUS_CREDENTIALS_ID = 'nexus-credentials' // Jenkins credential ID for Nexus
        DOCKER_REGISTRY_URL = 'yourdockerregistry' // E.g., your Docker Hub username or private registry URL
        DOCKER_CREDENTIALS_ID = 'docker-registry-credentials' // Jenkins credential ID for Docker registry
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build, Publish & Push All Services') {
            parallel {
                // --- Example for one Java Microservice: department-service ---
                stage('department-service') {
                    steps {
                        dir('department-service') {
                            stage('Build & Test') {
                                sh './mvnw clean package' // Use Maven wrapper
                            }
                            stage('Publish to Nexus') {
                                // Requires pom.xml <distributionManagement> and Jenkins Nexus config
                                // For this task, we'll assume the pom.xml would be manually configured
                                // Example: sh './mvnw deploy -DaltDeploymentRepository=nexus::default::${env.NEXUS_URL} -Dnexus.credentialsId=${env.NEXUS_CREDENTIALS_ID}'
                                echo "Simulating: Publishing department-service JAR to Nexus"
                                // In a real setup, use withMaven block or mvn deploy with settings
                            }
                            stage('Build Docker Image') {
                                script {
                                    def imageName = "${env.DOCKER_REGISTRY_URL}/department-service:${env.BUILD_NUMBER}"
                                    sh "docker build -t ${imageName} ."
                                }
                            }
                            stage('Push Docker Image') {
                                script {
                                    def imageName = "${env.DOCKER_REGISTRY_URL}/department-service:${env.BUILD_NUMBER}"
                                    // Assumes Docker credentials are set up in Jenkins
                                    docker.withRegistry("https://${env.DOCKER_REGISTRY_URL}", env.DOCKER_CREDENTIALS_ID) {
                                        sh "docker push ${imageName}"
                                    }
                                }
                            }
                        }
                    }
                }

                // --- Example for Frontend ---
                stage('frontend') {
                    steps {
                        dir('frontend') {
                            stage('Build') {
                                sh 'npm install'
                                sh 'npm run build'
                            }
                            stage('Build Docker Image') {
                                script {
                                    def imageName = "${env.DOCKER_REGISTRY_URL}/frontend:${env.BUILD_NUMBER}"
                                    sh "docker build -t ${imageName} ."
                                }
                            }
                            stage('Push Docker Image') {
                                script {
                                    def imageName = "${env.DOCKER_REGISTRY_URL}/frontend:${env.BUILD_NUMBER}"
                                    docker.withRegistry("https://${env.DOCKER_REGISTRY_URL}", env.DOCKER_CREDENTIALS_ID) {
                                        sh "docker push ${imageName}"
                                    }
                                }
                            }
                        }
                    }
                }

                stage('service-registry') {
                    steps {
                        dir('service-registry') {
                            stage('Build & Test') {
                                sh './mvnw clean package'
                            }
                            stage('Publish to Nexus') {
                                echo "Simulating: Publishing service-registry JAR to Nexus"
                            }
                            stage('Build Docker Image') {
                                script {
                                    def imageName = "${env.DOCKER_REGISTRY_URL}/service-registry:${env.BUILD_NUMBER}"
                                    sh "docker build -t ${imageName} ."
                                }
                            }
                            stage('Push Docker Image') {
                                script {
                                    def imageName = "${env.DOCKER_REGISTRY_URL}/service-registry:${env.BUILD_NUMBER}"
                                    docker.withRegistry("https://${env.DOCKER_REGISTRY_URL}", env.DOCKER_CREDENTIALS_ID) {
                                        sh "docker push ${imageName}"
                                    }
                                }
                            }
                        }
                    }
                }

                stage('config-server') {
                    steps {
                        dir('config-server') {
                            stage('Build & Test') {
                                sh './mvnw clean package'
                            }
                            stage('Publish to Nexus') {
                                echo "Simulating: Publishing config-server JAR to Nexus"
                            }
                            stage('Build Docker Image') {
                                script {
                                    def imageName = "${env.DOCKER_REGISTRY_URL}/config-server:${env.BUILD_NUMBER}"
                                    sh "docker build -t ${imageName} ."
                                }
                            }
                            stage('Push Docker Image') {
                                script {
                                    def imageName = "${env.DOCKER_REGISTRY_URL}/config-server:${env.BUILD_NUMBER}"
                                    docker.withRegistry("https://${env.DOCKER_REGISTRY_URL}", env.DOCKER_CREDENTIALS_ID) {
                                        sh "docker push ${imageName}"
                                    }
                                }
                            }
                        }
                    }
                }

                stage('api-gateway') {
                    steps {
                        dir('api-gateway') {
                            stage('Build & Test') {
                                sh './mvnw clean package'
                            }
                            stage('Publish to Nexus') {
                                echo "Simulating: Publishing api-gateway JAR to Nexus"
                            }
                            stage('Build Docker Image') {
                                script {
                                    def imageName = "${env.DOCKER_REGISTRY_URL}/api-gateway:${env.BUILD_NUMBER}"
                                    sh "docker build -t ${imageName} ."
                                }
                            }
                            stage('Push Docker Image') {
                                script {
                                    def imageName = "${env.DOCKER_REGISTRY_URL}/api-gateway:${env.BUILD_NUMBER}"
                                    docker.withRegistry("https://${env.DOCKER_REGISTRY_URL}", env.DOCKER_CREDENTIALS_ID) {
                                        sh "docker push ${imageName}"
                                    }
                                }
                            }
                        }
                    }
                }

                stage('employee-service') {
                    steps {
                        dir('employee-service') {
                            stage('Build & Test') {
                                sh './mvnw clean package'
                            }
                            stage('Publish to Nexus') {
                                echo "Simulating: Publishing employee-service JAR to Nexus"
                            }
                            stage('Build Docker Image') {
                                script {
                                    def imageName = "${env.DOCKER_REGISTRY_URL}/employee-service:${env.BUILD_NUMBER}"
                                    sh "docker build -t ${imageName} ."
                                }
                            }
                            stage('Push Docker Image') {
                                script {
                                    def imageName = "${env.DOCKER_REGISTRY_URL}/employee-service:${env.BUILD_NUMBER}"
                                    docker.withRegistry("https://${env.DOCKER_REGISTRY_URL}", env.DOCKER_CREDENTIALS_ID) {
                                        sh "docker push ${imageName}"
                                    }
                                }
                            }
                        }
                    }
                }
                // TODO: Add similar parallel stages for other microservices:
                // - service-registry (Done)
                // - config-server (Done)
                // - api-gateway (Done)
                // - employee-service (Done)
            }
        }
        // Optional Stage for K8s deployment
        // stage('Deploy to Minikube') {
        //     steps {
        //         echo "Applying K8s manifests..."
        //         // This would require kubectl configured on the Jenkins agent
        //         // and access to the Minikube cluster.
        //         // Also, image names in K8s manifests need to be updated or use :latest and imagePullPolicy: Always
        //         sh 'kubectl apply -f deploy/k8s/ --recursive'
        //     }
        // }
    }
}
