# DevOps Project Documentation

## (1) Understand the App

### Clone the App
```bash
git clone <repository-url>
```

### Build the JAR File
```bash
./gradlew build
```

### Run Unit Tests
```bash
./gradlew test
```


### Run the App
```bash
java -jar build/libs/demo-0.0.1-SNAPSHOT.jar
```

### Open the App
- Open in browser: http://localhost:8081 (or the port in logs)

---

## (2) Understand SonarQube

### Install SonarQube Manually
```bash
wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-9.9.1.69595.zip
unzip sonarqube-9.9.1.69595.zip
cd sonarqube-9.9.1.69595/bin/linux-x86-64
./sonar.sh start
./sonar.sh status
```
- Access UI: http://localhost:9000
- Credentials:
  - Username: admin
  - Password: admin

### Install SonarScanner
```bash
wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip
unzip sonar-scanner-cli-5.0.1.3006-linux.zip
export PATH=$PATH:/path/to/sonar-scanner-5.0.1.3006-linux/bin
```

### Apply Test Locally on the App
Create sonar-project.properties:

```properties
sonar.projectKey=demo-app
sonar.projectName=Demo Application
sonar.projectVersion=1.0
sonar.sources=src
sonar.host.url=http://localhost:9000
sonar.login=<your-sonar-token>
```

Run scanner:
```bash
sonar-scanner
```

---

## (3) Docker

### Dockerfile
```dockerfile
FROM openjdk:17-jdk-slim
WORKDIR /app
COPY build/libs/demo-0.0.1-SNAPSHOT.jar app.jar
EXPOSE 8080
CMD ["java", "-jar", "app.jar"]
```

### Build Image
```bash
docker build -t web-app:latest .
```

### Run Container
```bash
docker run -d -p 8080:8080 web-app:latest
```

### Open the App from Container
- Go to: http://localhost:8080



---

## (4) Kubernetes

### Create Namespace
```bash
kubectl create namespace web-app
```

### Create Deployment
deployment.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app-deployment
  labels:
    app: web-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
      - name: web-app
        image: your-docker-image:tag
        ports:
        - containerPort: 8081
```

### Create Service
service.yaml
```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-app-service
spec:
  selector:
    app: web-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8081
  type: ClusterIP
```

### Create Ingress
ingress.yaml
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-app-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: web-app.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-app-service
            port:
              number: 80
```

### Open the App via Ingress URL
1. Add to /etc/hosts:

```bash
<ingress-ip> web-app.local
```

2. Access: http://web-app.local



---

## (5) Terraform

### Create Terraform Network Module
- VPC, subnet, security group defined in modules/network/main.tf

### Create Terraform Server Module
- EC2 defined in modules/server/main.tf

### Files Structure
- main.tf: Calls modules
- variables.tf: Input variables
- outputs.tf: Outputs like VPC ID

### Deploy Infra
```bash
terraform init
terraform plan
terraform apply -auto-approve
```



---

## (6) Ansible

### Plan Required Packages for the Pipeline
- Example: git, docker, openjdk

### Create Ansible Modules and Playbooks
```yaml
# playbook.yml
- hosts: all
  become: yes
  tasks:
    - name: Install required packages
      apt:
        name: "{{ item }}"
        state: present
      loop:
        - git
        - openjdk-17-jdk
        - docker.io
```

### Create Dynamic Inventory
- Using AWS EC2 inventory plugin or dynamic inventory script



---

## (7) Understand CI/CD Flow with Jenkins and ArgoCD

### Understand ArgoCD
- GitOps tool to automate Kubernetes deployments

### Deploy ArgoCD in Kubernetes
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### Open ArgoCD UI Page
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

- Open browser: https://localhost:8080
- Default credentials:
  - Username: admin
  - Password: Run:
```bash
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d
```



---

## (8) Jenkins

### 🛠 Create Jenkins Pipeline

We created a Jenkinsfile in the root of the GitHub repository to automate the CI/CD process. The pipeline is responsible for:

- Cloning the app
- Building the app
- Running tests
- Building a Docker image and pushing it to Docker Hub
- Triggering deployment using ArgoCD

### 📁 Jenkinsfile (Key Stages)
```groovy
pipeline {
    agent any

    environment {
        IMAGE_NAME = 'amlali5/cloud-devops-app'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
    }

    stages {
        stage('Clone Repository') {
            steps {
                git credentialsId: 'github-token', url: 'https://github.com/Amlali5/CloudDevOpsProject.git'
            }
        }

        stage('Build App') {
            steps {
                sh './gradlew build'
            }
        }

        stage('Run Unit Tests') {
            steps {
                sh './gradlew test'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t $IMAGE_NAME:$IMAGE_TAG ."
            }
        }

        stage('Push Image to Docker Hub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-hub', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
                    sh "docker push $IMAGE_NAME:$IMAGE_TAG"
                }
            }
        }

        stage('Trigger ArgoCD Sync') {
            steps {
                sh "argocd app sync cloud-devops-app --auth-token \$ARGOCD_TOKEN"
            }
        }
    }
}
```

### 🧹 Jenkins Configuration

- *GitHub Token* stored under github-token credential ID
- *Docker Hub Credentials* stored as docker-hub with username/password
- *ARGOCD_TOKEN* exported in Jenkins environment or configured in pipeline secrets

### 🔗 Run the Pipeline

The pipeline runs on every commit or can be triggered manually in Jenkins. Once complete, it automatically updates the app image on Docker Hub and triggers ArgoCD to sync the Kubernetes deployment.

### ✅ Output

- Docker image successfully built and pushed to Docker Hub (e.g., amlali5/cloud-devops-app:25)
- ArgoCD sync triggered and deployment updated with new image
- App available at the Ingress URL: http://web-app.local 🚀 ArgoCD (GitOps)
We used ArgoCD to automate deployment from GitHub repo.

✅ ArgoCD App Manifest
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: cloud-devops-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: 'https://github.com/Amlali5/CloudDevOpsProject.git'
    targetRevision: main
    path: web-app
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

Apply to Cluster:
```bash
kubectl apply -f argocd-app.yaml
```

Sync Application:
```bash
argocd app sync cloud-devops-app
```
