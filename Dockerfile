# 1. Build Stage: Use a slim JDK image to compile the Java code

FROM eclipse-temurin:17-jdk AS build
WORKDIR /app

# Copy the Maven configuration and source code

COPY pom.xml .
COPY src ./src

# Build the application (runs tests, compiles, and creates the JAR)

RUN --mount=type=cache,target=/root/.m2 ./mvnw package -DskipTests

# 2. Production Stage: Use a smaller JRE image for the final running container

FROM eclipse-temurin:17-jre

# Set the user to 'nonroot' for better security

# RUN addgroup -S springboot && adduser -S springboot -G springboot
RUN addgroup -S springboot && adduser -S -G springboot springboot
USER springboot

# Expose the default Spring Boot port

EXPOSE 8080

# Copy the application JAR from the build stage

# The JAR is typically found in target/ with the artifact name from pom.xml

ARG JAR_FILE=target/spring-ci-cd-demo-0.0.1-SNAPSHOT.jar
COPY --from=build /app/${JAR_FILE} app.jar

# Define the entrypoint command to run the application

ENTRYPOINT ["java","-jar","/app.jar"]