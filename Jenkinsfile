pipeline {
    agent any // Or a specific agent label

    environment {
        NEXUS_URL = 'http://local-nexus:8081/repository/maven-releases/'
        NEXUS_CREDENTIALS_ID = 'nexus-credentials'
        DOCKER_REGISTRY_URL = 'https://hub.docker.com/u/harshana2020'
        DOCKER_CREDENTIALS_ID = 'docker-registry-credentials'
    }


    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build, Publish & Push All Services') {
            parallel {

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
                                    def latestImageName = "${env.DOCKER_REGISTRY_URL}/department-service:latest"
                                    sh "docker build -t ${imageName} ."
                                    sh "docker tag ${imageName} ${latestImageName}"
                                }
                            }
                            stage('Push Docker Image') {
                                script {
                                    def imageName = "${env.DOCKER_REGISTRY_URL}/department-service:${env.BUILD_NUMBER}"
                                    def latestImageName = "${env.DOCKER_REGISTRY_URL}/department-service:latest"
                                    docker.withRegistry("https://${env.DOCKER_REGISTRY_URL}", env.DOCKER_CREDENTIALS_ID) {
                                        sh "docker push ${imageName}"
                                        sh "docker push ${latestImageName}"
                                    }
                                }
                            }
                        }
                    }
                }

                stage('frontend') {
                    steps {
                        dir('frontend') {
                            // stage('Build') {
                            //     sh 'npm install'
                            //     sh 'npm run build'
                            // }
                            stage('Build Docker Image') {
                                script {
                                    def imageName = "${env.DOCKER_REGISTRY_URL}/frontend:${env.BUILD_NUMBER}"
                                    def latestImageName = "${env.DOCKER_REGISTRY_URL}/frontend:latest"
                                    sh "docker build -t ${imageName} ."
                                    sh "docker tag ${imageName} ${latestImageName}"
                                }
                            }
                            stage('Push Docker Image') {
                                script {
                                    def imageName = "${env.DOCKER_REGISTRY_URL}/frontend:${env.BUILD_NUMBER}"
                                    def latestImageName = "${env.DOCKER_REGISTRY_URL}/frontend:latest"
                                    docker.withRegistry("https://${env.DOCKER_REGISTRY_URL}", env.DOCKER_CREDENTIALS_ID) {
                                        sh "docker push ${imageName}"
                                        sh "docker push ${latestImageName}"
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
                                    def latestImageName = "${env.DOCKER_REGISTRY_URL}/service-registry:latest"
                                    sh "docker build -t ${imageName} ."
                                    sh "docker tag ${imageName} ${latestImageName}"
                                }
                            }
                            stage('Push Docker Image') {
                                script {
                                    def imageName = "${env.DOCKER_REGISTRY_URL}/service-registry:${env.BUILD_NUMBER}"
                                    def latestImageName = "${env.DOCKER_REGISTRY_URL}/service-registry:latest"
                                    docker.withRegistry("https://${env.DOCKER_REGISTRY_URL}", env.DOCKER_CREDENTIALS_ID) {
                                        sh "docker push ${imageName}"
                                        sh "docker push ${latestImageName}"
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
                                    def latestImageName = "${env.DOCKER_REGISTRY_URL}/config-server:latest"
                                    sh "docker build -t ${imageName} ."
                                    sh "docker tag ${imageName} ${latestImageName}"
                                }
                            }
                            stage('Push Docker Image') {
                                script {
                                    def imageName = "${env.DOCKER_REGISTRY_URL}/config-server:${env.BUILD_NUMBER}"
                                    def latestImageName = "${env.DOCKER_REGISTRY_URL}/config-server:latest"
                                    docker.withRegistry("https://${env.DOCKER_REGISTRY_URL}", env.DOCKER_CREDENTIALS_ID) {
                                        sh "docker push ${imageName}"
                                        sh "docker push ${latestImageName}"
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
                                    def latestImageName = "${env.DOCKER_REGISTRY_URL}/api-gateway:latest"
                                    sh "docker build -t ${imageName} ."
                                    sh "docker tag ${imageName} ${latestImageName}"
                                }
                            }
                            stage('Push Docker Image') {
                                script {
                                    def imageName = "${env.DOCKER_REGISTRY_URL}/api-gateway:${env.BUILD_NUMBER}"
                                    def latestImageName = "${env.DOCKER_REGISTRY_URL}/api-gateway:latest"
                                    docker.withRegistry("https://${env.DOCKER_REGISTRY_URL}", env.DOCKER_CREDENTIALS_ID) {
                                        sh "docker push ${imageName}"
                                        sh "docker push ${latestImageName}"
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
                                    def latestImageName = "${env.DOCKER_REGISTRY_URL}/employee-service:latest"
                                    sh "docker build -t ${imageName} ."
                                    sh "docker tag ${imageName} ${latestImageName}"
                                }
                            }
                            stage('Push Docker Image') {
                                script {
                                    def imageName = "${env.DOCKER_REGISTRY_URL}/employee-service:${env.BUILD_NUMBER}"
                                    def latestImageName = "${env.DOCKER_REGISTRY_URL}/employee-service:latest"
                                    docker.withRegistry("https://${env.DOCKER_REGISTRY_URL}", env.DOCKER_CREDENTIALS_ID) {
                                        sh "docker push ${imageName}"
                                        sh "docker push ${latestImageName}"
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
        stage('Deploy to Kubernetes') {
            steps {
                echo "Deploying application to Kubernetes namespace ems-app..."
                // Ensure KUBECONFIG is set up in the Jenkins agent environment
                // or use withKubeconfig if credentials plugin is used.
                sh 'kubectl config current-context' // Good to log which context is being used
                sh 'kubectl apply -f deploy/k8s/00-namespace.yaml'
                sh 'kubectl apply -f deploy/k8s/configmaps/ -n ems-app'
                sh 'kubectl apply -f deploy/k8s/secrets/ -n ems-app' // Secrets should be managed securely, e.g. Jenkins credentials
                sh 'kubectl apply -f deploy/k8s/pvcs/ -n ems-app'
                sh 'kubectl apply -f deploy/k8s/headless-services/ -n ems-app'
                sh 'kubectl apply -f deploy/k8s/services/ -n ems-app'
                sh 'kubectl apply -f deploy/k8s/statefulsets/ -n ems-app'
                sh 'kubectl apply -f deploy/k8s/deployments/ -n ems-app'
                sh 'kubectl apply -f deploy/k8s/ingress/ -n ems-app'
                
                echo "Waiting a bit for resources to be created..."
                sh 'sleep 30'

                echo "Current pods in ems-app namespace:"
                sh 'kubectl get pods -n ems-app'
            }
        }
    }
}
