# SkillSwapPro - Decoupled Microservice Architecture

This document outlines the state-of-the-art decoupled architecture of the SkillSwapPro platform, featuring independent services and dedicated data persistence.

## 1. Detailed System Map (Hero View)

![SkillSwapPro Detailed System Map](detailed_SYSTEM_MAP.png)

## 2. Additional Architectural Diagrams

### 2.1. Deployment Diagram (VPS Node & Network Placement)

![Deployment Diagram (VPS Node & Network Placement)](../Architectural%20disigns/Deployment_Diagram_Premium.png)

### 2.2. System Architecture (Decoupled Logical Blueprint)

![System Architecture (Decoupled Logical Blueprint)](../Architectural%20disigns/System_Architecture_Premium.png)

## 3. Architectural Blueprint (Logical)

```mermaid
graph TD
    subgraph "Frontend Layer (Flutter Mobile)"
        FA["Flutter App"]
        VP["Video Player Plugin"]
        FP["File Picker Plugin"]
        UL["URL Launcher"]
        FA --- VP
        FA --- FP
        FA --- UL
    end

    subgraph "Gateway Layer"
        GW["API Gateway (Port 3000)"]
    end

    subgraph "Microservices Layer"
        AS["Identity Service"]
        US["User Service"]
        CS["Course Service"]
        ES["Enrollment Service"]
        SS["Shorts Service"]
        MS["Messaging Service"]
        NS["Notification Service"]
        Other["Other Services (Blog, Stat, etc.)"]
    end

    subgraph "Independent Data Layer"
        ADB[("Auth DB")]
        UDB[("User DB")]
        CDB[("Course DB")]
        EDB[("Enrollment DB")]
        COMDB[("Common DB")]
    end

    subgraph "Asset Storage"
        VolC["Course Uploads Vol"]
        VolS["Shorts Uploads Vol"]
        VolU["User Avatars Vol"]
    end

    %% Connections
    FA -- "HTTPS / REST" --> GW
    GW -- "/api/auth" --> AS
    GW -- "/api/users" --> US
    GW -- "/api/courses" --> CS
    GW -- "/api/enrollments" --> ES
    GW -- "/api/shorts" --> SS
    GW -- "/api/messaging" --> MS
    GW -- "/api/notifications" --> NS

    AS -- "Dedicated" --> ADB
    US -- "Dedicated" --> UDB
    CS -- "Dedicated" --> CDB
    ES -- "Dedicated" --> EDB
    SS -- "Shared Logical" --> COMDB
    MS -- "Shared Logical" --> COMDB
    NS -- "Shared Logical" --> COMDB
    Other -- "Shared Logical" --> COMDB

    CS -- "Local Persistence" --> VolC
    SS -- "Local Persistence" --> VolS
    US -- "Local Persistence" --> VolU

    %% Inter-service Sync
    AS -. "Sync Profile" .-> US
```

## 4. Key Architectural Improvements

### 4.1. Database Independence
Unlike traditional monoliths or tightly coupled microservices, SkillSwapPro now uses **separate Postgres instances** for its core domains:
- **Auth DB**: Isolated credentials and identity data.
- **User DB**: Dedicated storage for profiles and user preferences.
- **Course DB**: Independent management of courses, materials, and reviews.
- **Enrollment DB**: High-concurrency tracking of student participation.

### 4.2. Frontend Media Integration
The Flutter frontend has been enhanced with native capabilities:
- **`video_player`**: Direct in-app playback for course videos.
- **`file_picker`**: Seamless upload of course documents and materials.
- **`url_launcher`**: External handling for specialized files like PDFs.

### 4.3. Resilient Asset Routing
All media assets are proxied through the **API Gateway**, ensuring a consistent entry point for the mobile app while allowing services to manage their own storage volumes independently.

---

## 5. Service Visual Identity

Each microservice in the SkillSwapPro ecosystem is designed with a specific domain focus, represented by the following visual identity system:

![SkillSwapPro Service Icons](service_icons.png)

### Core Service Breakdown:
- **Shield**: Identity & Auth Service
- **Profile**: User Management Service
- **Book**: Course & Learning Service
- **Video**: Shorts & Content Service
- **Check**: Enrollment & Validation Service
- **Chat**: Messaging & Real-time Service
- **Bell**: Notification & Alert Service
- **Card**: Payment & Transaction Service

---

## 6. Technical Infrastructure (Docker Images)

The following Docker images power the SkillSwapPro infrastructure, ensuring lightweight and consistent deployment:

| Service | Docker Image / Context | Purpose |
|---------|-----------------------|---------|
| **API Gateway** | `backend-gateway-service` | Entry point & Proxy |
| **Identity Service** | `backend-identity-service` | JWT Auth & Roles |
| **User Service** | `backend-user-service` | Profiles & Avatars |
| **Course Service** | `backend-course-service` | Course Content & Reviews |
| **Enrollment Service** | `backend-enrollment-service` | Enrollment State |
| **Shorts Service** | `backend-shorts-service` | Short Video Content |
| **Databases** | `postgres:15-alpine` | High-performance SQL |
| **Cache** | `redis:7-alpine` | Real-time messaging |

---

## 7. Architectural Style Justification
*   **Decoupled Microservices**: Chosen to support the modular lifecycle of educational platform elements. Features like TikTok-style **Shorts** require heavy video handling and high throughput. Separating it into `shorts-service` ensures video load spikes do not interrupt core authentication (`identity-service`) or messaging flows.
*   **Database-per-Service Pattern**: Protects critical data. A security threat or performance bottleneck in a public review/comment service cannot affect the primary credential tables (`auth-db`).
*   **Event-Driven Sync**: Identity changes (registration/updates) are propagated from `identity-service` to `user-service` asynchronously, minimizing operational coupling.

## 8. Quality Attributes & Trade-offs
*   **Scalability vs. Network Complexity**:
    *   *Advantage*: Each service is containerized and runs independently, allowing selective scaling via Kubernetes.
    *   *Trade-off*: All client requests route through the API Gateway, introducing slight network latency overhead compared to a direct monolithic call.
*   **Data Isolation vs. Consistency**:
    *   *Advantage*: Absolute domain isolation; data changes are local and secure.
    *   *Trade-off*: Requires inter-service synchronization (e.g. sync between identity and user service) which operates on eventual consistency rather than ACID transactions.

## 9. Pros and Cons of Chosen Architecture
*   **Pros**:
    *   **Fault Isolation**: If the `shorts-service` crashes due to video encoding issues, students can still log in, read blogs, message tutors, and make payments.
    *   **Modular Tech Selection**: Services can use localized database schemas (SQL for identity, document store or search indices for courses).
    *   **Independent Deployability**: CI/CD (Jenkins) can redeploy updated services without bringing down other parts of the app.
*   **Cons**:
    *   **Deployment Overhead**: Requires orchestrating 22 separate database and service containers.
    *   **Difficult Local Debugging**: Mocking and testing integrations require significant tooling (resolved via Docker Compose profiles).

---
*Generated by Antigravity AI - 2026-06-05*
