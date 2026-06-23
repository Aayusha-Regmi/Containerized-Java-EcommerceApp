#Stage 1: Build using maven base image

FROM maven:3.9.6-eclipse-temurin-17 AS builder

#Create Workdir in the conatiner to add all project files
WORKDIR /app

#Copy the pom files and install them at once
COPY /EcommerceApp/pom.xml .

#install all dependencies
RUN mvn dependency:go-offline -B

#Copy other files
COPY README.md .
COPY EcommerceApp/src ./src
COPY EcommerceApp/mydatabase.db ./
COPY EcommerceApp/*.png ./

RUN mvn clean package -DskipTests
#Package the application (skipping test for speed)

RUN mvn clean package -DskipTests 

#Stage 2: Run the application

# We use Tomcat 9 because the source code uses the legacy 'javax.servlet' namespace.
FROM tomcat:9.0-jre17

# Wipe out webapps completely so Tomcat has zero default application hooks
RUN rm -rf /usr/local/tomcat/webapps/*

# Create an isolated directory outside of 'webapps' to avoid Tomcat auto-mapping conflicts
RUN mkdir -p /usr/local/tomcat/custom-apps/

# Copy the built binary into our custom path (retains developer's name structure)
COPY --from=builder /app/target/*.war /usr/local/tomcat/custom-apps/EcommerceApp.war

# Inject the deployment context file straight into the Catalina configuration engine
COPY context.xml /usr/local/tomcat/conf/Catalina/localhost/ROOT.xml

# Mount backend files and data
WORKDIR /usr/local/tomcat
COPY --from=builder /app/*.png ./
COPY --from=builder /app/README.md ./
COPY --from=builder /app/mydatabase.db ./

EXPOSE 8080
CMD ["catalina.sh", "run"]

