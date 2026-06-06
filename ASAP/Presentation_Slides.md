# 🎓 Presentation Slides Outline: SkillSwap Pro (SEN3244)
This file contains the slide-by-slide structure and content outline for your 20-slide PowerPoint presentation submission.

---

### Slide 1: Title & Presentation Introduction
*   **Slide Title**: SkillSwap Pro: A Peer-to-Peer Educational Exchange Microservices Platform
*   **Subtitle**: Final Project Presentation — Course Code: SEN3244 (Software Architecture)
*   **Presenter Team (Group 13)**:
    *   Tanyu Ransom Tuwa (Scrum Master / CTO)
    *   Feze Halimatou Seidi Malaika (Product Owner / Developer)
*   **Institution**: The ICT University, Spring 2026

---

### Slide 2: Problem Statement
*   **Header**: The Problem in Modern E-Learning
*   **Bullet Points**:
    *   **Monolithic Vulnerabilities**: Standard platforms fail entirely when minor services crash.
    *   **Rigid User Roles**: Systems typically restrict accounts to being either a Student or Tutor, preventing mutual knowledge exchange.
    *   **Quality Assurance Gaps**: Unverified credentials lead to poor learning quality.
    *   **Localization Obstacles**: Standard payment systems do not natively integrate local mobile money interfaces.

---

### Slide 3: Aim & Objectives
*   **Header**: Project Aim and Key Objectives
*   **Bullet Points**:
    *   **Aim**: Design, implement, and deploy a secure, scale-resilient P2P skill exchange platform using microservices.
    *   **Objectives**:
        1. **Loose Decoupling**: Separate service domains with isolated databases.
        2. **Dual-Role Capabilities**: Seamless UI/UX toggle.
        3. **Automated CI/CD**: Build, test, and deploy with Jenkins.
        4. **Container Orchestration**: Deploy workloads on K3s Kubernetes.
        5. **Continuous Monitoring**: Track health via Prometheus & Grafana.

---

### Slide 4: Literature Review: Methodology Comparison
*   **Header**: Evaluating Development Methodologies
*   **Bullet Points**:
    *   **Waterfall**: Linear, low flexibility, risks discovered late. Not suitable.
    *   **Spiral**: Iterative, risk-driven but slow and bureaucratic for a 2-member team.
    *   **Kanban**: Continuous flow, lacks time-boxing required for strict exam schedules.
    *   **Scrum (Agile)**: Chosen for its **2-week time-boxed Sprints**, regular standups, and clear boundary roles.

---

### Slide 5: Agile Execution & Scrum Artifacts
*   **Header**: Scrum Roles and Progress Tracking
*   **Bullet Points**:
    *   **Team Roles**:
        *   *Product Owner*: Malaika Feze (User Stories, UI Figma mockup priority).
        *   *Scrum Master*: Tanyu Ransom (DevOps, CI/CD pipelines, K3s routing).
    *   **Sprints Outline**:
        *   *Sprint 1*: Authentication, Database Setup, welcome layout.
        *   *Sprint 2*: Dashboard, Search, filters, Course outlined cards.
        *   *Sprint 3*: Payments checkout, Messaging service, video uploads.
    *   **Scrum Visuals**: Trello workflow cards & daily sprint burndown tracking.

---

### Slide 6: High-Level Architecture (HLD)
*   **Header**: SkillSwap Pro System HLD Topology
*   **Diagram Reference**: (Refer to Chapter 3.3 HLD Diagram in report)
*   **Bullet Points**:
    *   **Client Tier**: Flutter Mobile Client communicating via HTTPS.
    *   **Ingress Tier**: Express.js API Gateway (Port 3000) routing all traffic.
    *   **Service Tier**: Six containerized services (`identity`, `user`, `course`, `shorts`, `payment`, `messaging`).
    *   **Persistence Tier**: Independent PostgreSQL databases (`auth-db`, `user-db`, `course-db`, `common-db`).

---

### Slide 7: Microservices Decoupled Design
*   **Header**: The Decoupled Domain Architecture
*   **Bullet Points**:
    *   **Gateway Service**: Unified entry-point preventing client-side port mapping. Serves static files and routes proxy requests.
    *   **Identity Service**: Generates JWT, validates session tokens.
    *   **User Service**: Handles profiles, preferences, and avatar updates.
    *   **Course Service**: Manages syllabus details, review inputs, and files list.
    *   **Event-Driven Sync**: Identity updates trigger async callbacks across services to maintain database schemas.

---

### Slide 8: UML Modelling - Use Case & Class Diagram
*   **Header**: Use Case and Data Model Design
*   **Bullet Points**:
    *   **Actors**: Students (Browse, Enroll, Pay, Stream), Tutors (Publish Courses, Upload Shorts, Verify Competency), and Admin (Moderate).
    *   **Class Entities**:
        *   *User*: email, roles, verification checks.
        *   *Course*: title, fee, outline files list.
        *   *Payment*: base amount, 10% tax addition, status (PAID/PENDING).
        *   *Short*: vertical video stream references.

---

### Slide 9: UML Modelling - Sequence Diagrams
*   **Header**: Core Sequence Interactions
*   **Bullet Points**:
    *   **Auth (Sign In)**:
        1. Client posts credentials -> Gateway proxies -> Identity Service checks DB.
        2. Password validated -> Return signed JWT token to client.
    *   **Course Checkout (Mobile Money)**:
        1. Student selects Course -> Payment service calculates invoice + 10% tax.
        2. Invoice saved as PENDING -> User receives USSD auth callback.
        3. User verifies PIN -> DB marked PAID -> Enrollment triggers sync logs.

---

### Slide 10: Infrastructure Setup & VPS Networking
*   **Header**: Production Cloud VPS Configuration
*   **Bullet Points**:
    *   **Server Host**: Single-node instance (Contabo VPS `167.86.100.54`).
    *   **Kubernetes Cluster**: Lightweight Rancher K3s (`v1.35.5+k3s1`).
    *   **Networking Configuration**:
        *   All microservices communicate internally on cluster IPs.
        *   Public entry is mapped to K3s NodePort `30000` forwarding to API Gateway port `3000`.
        *   Secure VPS firewall rules isolate database ports `5432` from public WAN.

---

### Slide 11: CI/CD Pipeline with Jenkins
*   **Header**: Continuous Integration and Automated Deployment
*   **Bullet Points**:
    *   **Trigger**: Push event on Github `main` branch.
    *   **Automated Stages**:
        1. *SCM Checkout*: Pull latest code on Jenkins.
        2. *Pull Code on Host*: SSH-agents pull changes to VPS `/opt/skillprof`.
        3. *Install & Test*: Runs dependency tree and Jest tests on the host.
        4. *Docker Build*: Creates tagged service Docker images.
        5. *Push Images*: Logs in to Docker Hub and pushes registry builds.
        6. *K3s Rolling Update*: Restarts deployments to load fresh images.

---

### Slide 12: Infrastructure as Code (IaC) with Ansible
*   **Header**: Server Configuration Automation
*   **Bullet Points**:
    *   **Purpose**: Eliminates manual server configuration errors.
    *   **Playbooks Executed**:
        1. **`install_dependencies.yml`**: Automates installations of Docker, system repository configurations, and configures daemon permissions.
        2. **`deploy_app.yml`**: Clones workspace files, creates persistent upload directories, and synchronizes docker runtime variables.

---

### Slide 13: Containerization & Orchestration Results
*   **Header**: Kubernetes (K3s) Pod Deployment Status
*   **Bullet Points**:
    *   **Deployments Status**: Verified all pods are healthy and running:
        *   `course-service` & `course-db` (Running, 1/1)
        *   `identity-service` & `identity-db` (Running, 1/1)
        *   `user-service` & `user-db` (Running, 1/1)
        *   `gateway-service` (Running, 2/2 replica pods)
    *   **Resource Constraints**: Microservice pods restricted to `cpu: "500m"` and `memory: "512Mi"` to protect node performance.

---

### Slide 14: Continuous Monitoring: Prometheus & Grafana
*   **Header**: System Metrics and Dashboard Visualizations
*   **Bullet Points**:
    *   **Prometheus UI**: Port `9090` (scrapes health stats every 15 seconds).
    *   **Grafana UI**: Port `4000` (maps graphs, database queries, and CPU spikes).
    *   **Metrics Tracked**:
        *   `http_requests_total`: Tracks Gateway entry traffic volumes.
        *   `process_resident_memory_bytes`: Identifies microservice memory leaks.
        *   `pg_stat_database_numbackends`: Monitors active SQL client links.

---

### Slide 15: Robust Code Testing
*   **Header**: Test Automation and Code Coverage
*   **Bullet Points**:
    *   **Test Framework**: Jest with TypeScript (`ts-jest`).
    *   **Coverage Target**: Course specification requires >80% code coverage.
    *   **Results**:
        *   All 23 authentication and route test cases **PASSED**.
        *   Achieved **88.23%** total statement coverage.
        *   Mocks utilized for Google OAuth APIs to isolate network errors.

---

### Slide 16: Project Innovation: Competency Verification
*   **Header**: Tutor Competency Exams
*   **Bullet Points**:
    *   **The Problem**: Restricting trash/spam content from unverified tutors.
    *   **The Innovation**: An automated test verification engine.
    *   **Logic Flow**:
        *   Tutor account requests publication activation.
        *   Identity Service generates a randomized competency exam sheet.
        *   Tutor must submit and pass the test before paid upload privileges are enabled.

---

### Slide 17: Project Innovation: Local Mobile Money
*   **Header**: MTN MoMo and Orange Money Checkout
*   **Bullet Points**:
    *   **The Problem**: Lack of credit cards among students in Cameroon.
    *   **The Innovation**: Native USSD push simulation.
    *   **Logic Flow**:
        *   Student initiates checkout. Payment service appends the local 10% VAT.
        *   Payment status is set to PENDING; USSD transaction prompt is pushed.
        *   Upon PIN input verification, webhook updates status to PAID, automatically updating enrollment records.

---

### Slide 18: Project Documentation & API Assets
*   **Header**: Deliverables, README, and Postman API Documentation
*   **Bullet Points**:
    *   **Complete Workspace Documentation**: Markdown `README.md` covers port registries, IaC, and Kubernetes execution steps.
    *   **Postman Collection**: `ASAP/SkillSwap_Pro.postman_collection.json` maps all microservice REST APIs, headers, and request bodies.
    *   **User Manual**: Step-by-step onboarding slideshow and tutor/student portal manuals integrated.

---

### Slide 19: Recommendations for Future Study
*   **Header**: Scale and Traceability Extensions
*   **Bullet Points**:
    *   **Message Broker Integration**: Introduce RabbitMQ or Apache Kafka to transition service synchronization from REST callbacks to asynchronous event queues.
    *   **Distributed Tracing**: Integrate Jaeger or OpenTelemetry to trace cross-service query times.
    *   **Centralized Logging**: Set up an ELK Stack (Elasticsearch, Logstash, Kibana) or Loki server to aggregate logs from all containerized services.

---

### Slide 20: Summary & Conclusion
*   **Header**: Project Achievements & Final Summary
*   **Bullet Points**:
    *   **Success**: Migration from monolith/Firebase to secure microservices completed.
    *   **Quality**: Met and exceeded performance, scale, IaC, CI/CD, testing, and monitoring requirements.
    *   **Preparedness**: Fully prepared for submission matching SEN3244 course exam guidelines.
*   **Thank You!** (Questions and Answers)
