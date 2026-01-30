# Jenkins Pipeline – Angular Application with Docker

## Overview

This project implements a **CI/CD pipeline using Jenkins** to automatically **build, package, and deploy an Angular application inside a Docker container**.  
The pipeline detects changes in a Git repository, builds the Angular application, creates a Docker image using a multi-stage build, and deploys it to a remote server using Docker Compose.

The solution is designed for **automation, repeatability, and clean deployments**.

---

## Architecture Summary

1. Jenkins monitors a Git repository for changes.
2. If changes are detected (or forced), the pipeline:
   - Updates the local repository
   - Prepares Docker content
   - Builds the Angular application
   - Creates a Docker image
   - Deploys the container using Docker Compose
3. Old Docker images are cleaned up after a successful deployment.

---

## Technologies Used

- Jenkins – CI/CD orchestration
- Git – Source code version control
- Angular – Frontend framework
- Node.js (Alpine) – Build environment for Angular
- Docker – Application containerization
- Docker Compose – Container orchestration
- Nginx – Web server to serve the Angular app
- Shell / Batch Scripts – Automation and remote execution
- SSH – Secure remote server access

---

## Jenkins Pipeline Description

The pipeline is defined in the `Jenkinsfile` and runs on a Jenkins agent labeled `SERVER_1`.

### Pipeline Parameters

- **Force pipeline execution**  
  Allows the pipeline to run even if no changes are detected in the Git repository.

---

## Pipeline Stages

### 1. Checking Changes

Checks whether there are new commits in the monitored Git branch.  
If no changes are detected and the pipeline is not forced, execution stops.

---

### 2. Update Changes

Pulls the latest changes from the Git repository if updates are detected or forced.

---

### 3. Set Content Docker Image

Prepares Docker context and transfers application files to the remote Docker host.

---

### 4. Create and Deploy Docker Image

Builds the Docker image, tags it dynamically, and deploys it using Docker Compose.

---

## Post Actions

- On success: Old Docker images are removed.
- On failure: Deployment error is logged.

---

## Docker Configuration

### Multi-Stage Dockerfile

- Build stage using Node.js Alpine
- Runtime stage using Nginx Alpine

---

## Project Structure

```
Pipeline_Jenkins_Angular_Docker/
├── Jenkinsfile
├── bat/
├── docker/
├── sh/
└── README.md
```

---

## Benefits

- Fully automated CI/CD
- Clean Docker images
- Scalable deployments
