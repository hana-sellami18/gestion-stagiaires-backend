# ====================================================================
# DOCKERFILE MULTI-STAGE - Backend Spring Boot Gradle
# Reference : Guide Section 2 + Section 3 (Multi-Stage Builds) + Section 7 (Health Checks)
# Adapte pour Gradle (au lieu de Maven) et Java 17
# ====================================================================

# ====================================================================
# STAGE 1 : BUILD - Compile le projet avec Gradle
# ====================================================================
FROM gradle:8.5-jdk17-alpine AS builder

WORKDIR /build

# 1. Copier d'abord les fichiers de configuration Gradle
# (cette couche sera mise en cache si elle ne change pas)
COPY build.gradle settings.gradle gradlew ./
COPY gradle ./gradle

# 2. Donner les droits d'execution au Gradle Wrapper
RUN chmod +x ./gradlew

# 3. Telecharger toutes les dependances en avance (optimisation cache)
RUN ./gradlew dependencies --no-daemon || true

# 4. Copier le code source de l'application
COPY src ./src

# 5. Compiler et generer le JAR executable (skip tests pour rapidite)
RUN ./gradlew bootJar --no-daemon -x test

# ====================================================================
# STAGE 2 : RUNTIME - Image legere pour faire tourner le JAR
# ====================================================================
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

# 1. Installer curl pour le HEALTHCHECK (Reference guide Section 7)
RUN apk add --no-cache curl

# 2. Creer un utilisateur non-root pour la securite
RUN addgroup -S spring && adduser -S spring -G spring

# 3. Creer le dossier des uploads de CV avec les bons droits
RUN mkdir -p /app/uploads/cvs && chown -R spring:spring /app

# 4. Passer en utilisateur non-root
USER spring:spring

# 5. Copier uniquement le JAR depuis le stage builder (gain de taille)
COPY --from=builder --chown=spring:spring /build/build/libs/*.jar app.jar

# 6. Exposer le port 8089 (celui de ton application)
EXPOSE 8089

# 7. HEALTHCHECK Docker (Reference guide Section 7)
# Verifie toutes les 30s que l'endpoint Spring Boot Actuator repond
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8089/actuator/health || exit 1

# 8. Commande de demarrage du conteneur
ENTRYPOINT ["java", "-jar", "app.jar"]