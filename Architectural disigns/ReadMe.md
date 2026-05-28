# SkillSwapPro Architectural Designs

This folder contains the visual architectural and deployment designs for the SkillSwapPro 12-microservice ecosystem. 

**Note: "Fast" versions are recommended for quick viewing, while "Premium" and "Human" versions provide higher fidelity/sketched aesthetics.**

## 🏙️ System Architecture

- **[Web-Optimized (Fast Loading)](./System_Architecture_Fast.png)**
- **[Human-Like Whiteboard Sketch](./System_Architecture_Human.png)**
- **[Premium Technical Visual](./System_Architecture_Premium.png)**

## 🚀 Deployment Topology

- **[Web-Optimized (Fast Loading)](./Deployment_Diagram_Fast.png)**
- **[Human-Like Whiteboard Sketch](./Deployment_Diagram_Human.png)**
- **[Premium Technical Visual](./Deployment_Diagram_Premium.png)**

---

## Technical Schematics (Mermaid)

### Architecture
```mermaid
flowchart TB
    Client["📱 Flutter Mobile App"]
    
    subgraph Infrastructure ["Infrastructure Layer"]
        Gateway["🚦 API Gateway"]
    end
    
    subgraph Microservices ["Microservice Layer"]
        direction LR
        Identity["Identity Service"]
        User["User Service"]
        Course["Course Service"]
        Category["Category Service"]
        Shorts["Shorts Service"]
        Messaging["Messaging Service"]
        Notifications["Notification Service"]
        Enrollment["Enrollment Service"]
        Payment["Payment Service"]
        Verification["Verification Service"]
        Blog["Blog Service"]
        Stat["Stat Service"]
    end
    
    subgraph Database ["Persistence Layer"]
        DB[("🐘 Single PostgreSQL Container")]
    end

    Client -- "HTTP/REST API" --> Gateway
    Gateway --> Identity & User & Course & Category & Shorts & Messaging & Notifications & Enrollment & Payment & Verification & Blog & Stat
    Identity & User & Course & Category & Shorts & Messaging & Notifications & Enrollment & Payment & Verification & Blog & Stat -.-> DB
```
