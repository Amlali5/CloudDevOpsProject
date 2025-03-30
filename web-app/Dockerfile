# Use an OpenJDK base image
FROM openjdk:17-jdk-slim

# Set working directory in the container
WORKDIR /app

# Copy the JAR file to the container
COPY build/libs/demo-0.0.1-SNAPSHOT.jar app.jar

# Expose port 8080 (or the port your app uses)
EXPOSE 8080

# Command to run the application
CMD ["java", "-jar", "app.jar"]
