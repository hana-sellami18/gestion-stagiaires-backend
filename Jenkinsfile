pipeline {
    agent any

    environment {
        IMAGE_NAME = 'asm-backend'
        IMAGE_TAG = "${BUILD_NUMBER}"
        CONTAINER_NAME = 'asm-backend'
    }

    stages {
        stage('Checkout') {
            steps {
                echo '📥 Récupération du code depuis GitHub...'
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                echo '🐳 Construction de l\'image Docker...'
                sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
                sh "docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_NAME}:latest"
            }
        }

        stage('Verify Image') {
            steps {
                echo '✅ Vérification de l\'image créée...'
                sh "docker images | grep ${IMAGE_NAME}"
            }
        }

        stage('Deploy') {
            steps {
                echo '🚀 Déploiement du nouveau conteneur...'
                sh '''
                    docker stop ${CONTAINER_NAME} || true
                    docker rm ${CONTAINER_NAME} || true
                    docker run -d \
                        --name ${CONTAINER_NAME} \
                        --network asm-network \
                        -p 8089:8089 \
                        -e SPRING_PROFILES_ACTIVE=prod \
                        --restart unless-stopped \
                        ${IMAGE_NAME}:latest
                '''
                echo '✅ Conteneur déployé sur le port 8089'
            }
        }

        stage('Health Check') {
            steps {
                echo '🏥 Vérification du healthcheck...'
                sh 'sleep 20'
                sh 'docker ps | grep ${CONTAINER_NAME}'
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline terminé avec succès ! Backend déployé.'
        }
        failure {
            echo '❌ Pipeline échoué.'
        }
    }
}