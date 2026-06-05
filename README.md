# SkillSwap Pro 🚀

A state-of-the-art, peer-to-peer microservices educational platform. Empowering students and instructors to seamlessly switch between learning new skills and monetizing their expertise.

---

## 📖 Table of Contents
1. [Overview](#-overview)
2. [Key Features](#-key-features)
3. [System Architecture & Microservices](#-system-architecture--microservices)
4. [Infrastructure & DevOps Integration](#-infrastructure--devops-integration)
   - [Docker Compose Deployment](#1-docker-compose-deployment)
   - [Jenkins CI/CD Pipeline](#2-jenkins-cicd-pipeline)
   - [Ansible IaC Playbooks](#3-ansible-iac-playbooks)
   - [Kubernetes Orchestration](#4-kubernetes-orchestration)
   - [Prometheus & Grafana Monitoring](#5-prometheus--grafana-monitoring)
5. [Frontend (Flutter) Client Setup](#-frontend-flutter-client-setup)
6. [API Documentation](#-api-documentation)
7. [User Onboarding Guide](#-user-onboarding-guide)

---

## 📖 Overview

**SkillSwap Pro** is an innovative peer-to-peer microservices learning platform designed for the modern educational ecosystem. It breaks away from traditional monolithic LMS structures, splitting business logic into **decoupled microservices** backed by independent databases and a unified API Gateway.

The application features a premium Flutter-based mobile client supporting role-based dashboards, TikTok-style chronological learning videos ("Shorts"), real-time chat, Mobile Money transactions, and an interactive knowledge blog.

---

## ✨ Key Features

*   **Dual-Role Access:** Seamless toggle between **Student** dashboard (course search, enrollment, payments) and **Tutor** dashboard (monetization statistics, lesson uploads, shorts publication).
*   **Micro-Learning "Shorts":** Quick, bite-sized vertical video tips with optimized ExoPlayer media streaming.
*   **Cameroon Mobile Money (MTN & Orange):** Integrated payment flow supporting USSD push simulation, automatic 10% tax calculation, and instant course access.
*   **Knowledge Blog & Comments:** Discover articles written by tutors, with integrated comment section powered by comment-service.
*   **Real-Time Mentorship Messaging:** Integrated live chat communication between students and tutors.
*   **AI-Powered Verification Exams:** Dynamic question generation for validating tutor credentials.

---

## 🏗 System Architecture & Microservices

The backend is built as a set of highly decoupled Node.js (TypeScript) services:

| Microservice | Port | Description | DB Instance |
|--------------|------|-------------|-------------|
| **Gateway Service** | `3000` | Unified API entry point, route proxy, and public static file serving. | None |
| **Identity Service** | `3001` | JWT Generation, User Authentication, Google Sign-in validation. | `identity-db` |
| **User Service** | `3003` | User profile data, avatars, user preferences management. | `user-db` |
| **Course Service** | `3002` | Courses creation, details, outlines, reviews database. | `course-db` |
| **Enrollment Service** | `3008` | Enrollment flow, course participation logs. | `enrollment-db` |
| **Shorts Service** | `3005` | Uploading and streaming short-form video assets. | `common-db` |
| **Payment Service** | `3009` | checkout invoices, 10% tax addition, USSD authentication. | `user-db` |
| **Blog Service** | `3011` | Blog posts management, CRUD operations, cover uploads. | `common-db` |
| **Comment Service** | `3015` | Interactive comments on blogs and courses. | `common-db` |

---

## 🛠 Infrastructure & DevOps Integration

### 1. Docker Compose Deployment
To launch the complete microservices stack locally or on a production VPS:
```bash
cd backend
docker-compose up -d --build
```

### 2. Jenkins CI/CD Pipeline
The repository includes a `Jenkinsfile` at the root which automates the build-test-deploy workflow:
*   **Checkout**: Pulls the latest commits from the main branch.
*   **Dependencies**: Installs Node packages across all package workspaces.
*   **Unit Tests**: Runs Jest test suites with coverage validation (achieving over 80% coverage).
*   **Docker Build**: Validates image compilation locally.
*   **Deploy**: Connects to the production VPS and triggers an automatic restart.

### 3. Ansible IaC Playbooks
Provision and deploy using the Ansible playbooks under `ansible/playbooks/`:
*   **Install Dependencies (`install_dependencies.yml`)**: Installs Git, Docker, Docker Compose, and sets up project path folder permissions.
*   **App Deployment (`deploy_app.yml`)**: Clones the repo, ensures writable storage paths, and restarts services.
```bash
ansible-playbook -i ansible/hosts.ini ansible/playbooks/install_dependencies.yml
ansible-playbook -i ansible/hosts.ini ansible/playbooks/deploy_app.yml
```

### 4. Kubernetes Orchestration
Manifests are structured inside `k8s/` for production clustering:
*   **Databases (`databases-k8s.yaml`)**: Sets up PersistentVolumeClaims (PVCs) and deployments for database pods.
*   **Services (`services-k8s.yaml`)**: Orchestrates the service deployments and cluster service endpoints.
*   **Gateway (`gateway-k8s.yaml`)**: Maps public entry traffic via NodePort to internal ports.
```bash
kubectl apply -f k8s/databases-k8s.yaml
kubectl apply -f k8s/services-k8s.yaml
kubectl apply -f k8s/gateway-k8s.yaml
```

### 5. Prometheus & Grafana Monitoring
Continuous metric collection is configured under `monitoring/`:
*   **Prometheus (`prometheus.yml`)**: Scrapes performance statistics across microservices.
*   **Grafana (`docker-compose.monitoring.yml`)**: Visualizes container health, memory use, and gateway request metrics.
To spin up monitoring on the VPS:
```bash
cd monitoring
docker-compose -f docker-compose.monitoring.yml up -d
```
*   **Prometheus UI**: `http://<vps-ip>:9090`
*   **Grafana UI**: `http://<vps-ip>:4000` (default login: admin / admin)

---

## 📲 Frontend (Flutter) Client Setup

1.  Ensure you have the Flutter SDK installed.
2.  Open `frontend/lib/utils/auth_helper.dart` and verify the configured Google Client ID.
3.  Install dependencies and launch the app:
    ```bash
    cd frontend
    flutter pub get
    flutter run
    ```

---

## ⚡ API Documentation

All APIs are routed through the Gateway at `http://167.86.100.54:3000`.

### 🔑 Authentication (`identity-service`)
*   `POST /api/auth/register`: Register new user credentials.
*   `POST /api/auth/login`: Authenticate existing credentials and return JWT.
*   `POST /api/auth/google-login`: Sign in using Google OAuth 2.0 Identity Token.

### 📚 Blog Service (`blog-service`)
*   `GET /api/blogs`: Get all chronologically ordered blog posts.
*   `GET /api/blogs/:id`: Get a specific blog post details.
*   `POST /api/blogs`: Create a blog post (calculates reading time automatically).
*   `POST /api/blogs/upload`: Upload multipart blog cover images.

### 💳 Payment Service (`payment-service`)
*   `POST /api/payments/checkout`: Create a checkout invoice with 10% tax.
*   `POST /api/payments/authorize`: Authorize USSD PIN simulation.

---

## 👥 User Onboarding Guide

### 1. Welcome & Onboarding
New users undergo a 3-page slideshow introduction outlining skill discovery, peer interaction, and secure payments.

### 2. Role Selection
*   **Students**: Access standard dashboards to search courses, pay using Mobile Money, stream lessons, and message instructors.
*   **Tutors**: Gain writing privileges to the Knowledge Blog, metrics views, and can upload courses and Shorts.
*   **Admins**: Special roles with entry-moderation, verification checks, and backend settings toggle.
