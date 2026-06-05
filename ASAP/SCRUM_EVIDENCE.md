# SkillSwap Pro - Application of Scrum (Section 2 Deliverables)

This document provides the formal evidence of the Scrum framework applied during the development of SkillSwap Pro. It is structured to align with the course specifications for **SEN3244: Software Architecture** final exam deliverables.

---

## 📋 1. Comparative Methodology Review

To select the optimal lifecycle model for SkillSwap Pro, we evaluated several software development methodologies based on our team structure, constraints (6-week timeline), and technical complexity (12 microservices).

| Methodology | Flexbility | Customer/User Involvement | Risk Management | Suitable for SkillSwap Pro? |
| :--- | :--- | :--- | :--- | :--- |
| **Waterfall** | Very Low (Sequential phases) | Low (Only at start & end) | Poor (Risks discovered late) | **No** (Rigid requirements do not fit dynamic feature development). |
| **Kanban** | High (Continuous flow) | Medium (Continuous feedback) | Good (Bottleneck detection) | **No** (Lacks time-boxed sprints, making hard exam deadlines difficult to coordinate). |
| **Spiral** | Medium (Iterative risk focus) | Medium (At review stages) | Excellent (Risk-driven) | **No** (Overly bureaucratic and slow for a small 2-member team). |
| **Agile (Scrum)** | **Very High (Adaptive)** | **High (Sprint reviews)** | **Excellent (Early verification)** | **Yes** (Provides time-boxed focus, clear role boundaries, and rapid iteration). |

### Reason for Choosing Scrum
1. **Time-Boxed Sprints**: A 6-week timeframe naturally fits three 2-week sprints, ensuring incremental progress validation.
2. **Incremental Risk Mitigation**: Splitting complex microservice elements (Auth, Payment, Messaging) into separate sprints ensured early detection of system integration bottlenecks.
3. **Role Decoupling**: Having a designated Product Owner (Malaika) and Scrum Master (Tanyu) streamlined prioritization and removed execution roadblocks without administrative friction.

---

## 👥 2. Scrum Team Organization & Roles

SkillSwap Pro was executed by a cross-functional two-person Scrum team:

*   **Tanyu Ransom (Scrum Master / CTO)**
    *   *Responsibilities*: Facilitates daily stand-ups, removes project blockers (e.g. Android Emulator network routing), manages Docker-compose files, configures Jenkins pipelines, and oversees database decoupling.
*   **Malaika Feze (Product Owner / Developer)**
    *   *Responsibilities*: Defines and prioritizes product backlog items, maintains user story acceptance criteria, manages UI/UX mockups in Figma, develops the Flutter application, and reviews functional outcomes.
*   **Shared Responsibilities**:
    *   Participation in Sprint Planning and Estimations.
    *   Code reviews and Git branch merging (pull requests).
    *   Writing Jest unit tests for service endpoints.

### Conflict Resolution Strategy
*   **Technical Disagreements**: Resolved by the Scrum Master facilitating a feasibility analysis, running rapid prototypes in the scratch directory, or selecting the solution that minimizes module dependency.
*   **Feature Prioritization**: The Product Owner holds final authority on backlog sequencing based on core learning flow criticality (P0 vs P1).

---

## 🔄 3. Sprint Structure & Workflow Management

Development was structured into 3 distinct Sprints, each with dedicated sprint goals and acceptance criteria.

```
+-------------------------------------------------------+
|                     6-Week Lifecycle                 |
+--------------------------+----------------------------+
| Sprint 1: Auth & Setup   | Days 1 - 10 (Weeks 1-2)    |
| Sprint 2: Core Learning  | Days 11 - 20 (Weeks 3-4)   |
| Sprint 3: Transactions   | Days 21 - 30 (Weeks 5-6)   |
+--------------------------+----------------------------+
```

### Sprint Ceremonies
*   **Sprint Planning**: Conducted on Day 1 of each sprint to select stories from the Product Backlog, estimate effort using story points (Fibonacci sequence), and map user stories to task cards on Trello.
*   **Daily Stand-ups**: Time-boxed to 15 minutes at 9:00 AM. Team addressed:
    1. *What did I complete yesterday?*
    2. *What will I work on today?*
    3. *What blockers are in my way?*
*   **Sprint Reviews**: Held on Day 10 of each sprint. Included running the app on a physical device, testing emulator backend endpoints, and comparing results with acceptance criteria.
*   **Sprint Retrospectives**: Documented using the *Start-Stop-Continue* framework to continuously improve team efficiency.

---

## 📈 4. Sprint Burndown Charts (Sprints 1 & 2)

The team tracked remaining effort daily. Story points were burnt down as features met the "Definition of Done" (code compiled, Jest tests passed with >80% coverage, and UI matched Figma mockups).

### Sprint 1: Onboarding & Auth (13 Story Points)
*   **Ideal Line**: Linear progression from 13 to 0 story points over 10 days.
*   **Actual Line**: Drops on days when authentication handlers and role checks were integrated.
*   **Burndown Chart**: [sprint_1_burndown.png](../Architectural%20disigns/sprint_1_burndown.png)

### Sprint 2: Core Learning Experience (21 Story Points)
*   **Ideal Line**: Linear progression from 21 to 0 story points.
*   **Actual Line**: Flat during early database schema creation, then sharp drops as dashboards and filters were completed.
*   **Burndown Chart**: [sprint_2_burndown.png](../Architectural%20disigns/sprint_2_burndown.png)

---

## 🗂️ 5. Scrum Artifacts (Backlogs)

### 5.1 Product Backlog (Prioritized)

| Priority | User Story | Story Points | Target Sprint | Primary Screen |
| :---: | :--- | :---: | :---: | :--- |
| **P0** | Onboarding flow (Introduction cards with skip navigation) | 3 | Sprint 1 | Welcome 1-3 |
| **P0** | Account type selection (Toggle Student vs Tutor roles) | 2 | Sprint 1 | Choose Account |
| **P0** | Sign Up & Sign In (JWT auth, token persistence) | 5 | Sprint 1 | Register / Login |
| **P0** | Password recovery (Reset email and OTP verification) | 3 | Sprint 1 | Forgot Password |
| **P0** | Main Dashboard (Learn/Teach categories & trending courses) | 8 | Sprint 2 | Dashboard / Home |
| **P0** | Skill Discovery (Search courses with text/voice input) | 5 | Sprint 2 | Explore / Search |
| **P0** | Course details (Syllabus outline, tutor bio, enrollment) | 5 | Sprint 2 | Course Detail |
| **P1** | Payment Integration (MTN & Orange Money billing gateways) | 8 | Sprint 3 | Checkout |
| **P1** | Real-Time Messaging (Direct inbox chat via Firestore listeners) | 8 | Sprint 3 | Chat Inbox |
| **P1** | Profile management (Edit avatar, update skills, view history) | 5 | Sprint 3 | Profile Screen |
| **P1** | Content upload (Verified tutors uploading PDF & Video material) | 5 | Sprint 3 | Upload Form |
| **P2** | Notification Settings (Mute payment, messaging, cashback alerts) | 3 | Sprint 3 | Settings |
| **P2** | Blog Discovery (Read educational articles and updates) | 3 | Sprint 3 | Blog List |
| **P2** | Advanced Search Filters (Sort by price, rating, category) | 3 | Sprint 2 | Filter Panel |

---

## 🛠️ 6. Challenges Encountered & Resolution

1.  **Challenge: Payment Gateway Network Timeouts**
    *   *Symptom*: Mobile money callback APIs timed out when testing from local emulators.
    *   *Resolution*: Implemented asynchronous webhook queues with automatic retries on the gateway level, returning an immediate "Pending" state to the client while processing callbacks in the background.
2.  **Challenge: Database Consistency in Decoupled Schema**
    *   *Symptom*: Identity updates in `identity-service` did not reflect immediately in `user-service`.
    *   *Resolution*: Introduced event-driven sync triggers. When user data changes, an event is emitted and processed asynchronously, ensuring eventual consistency within milliseconds.
3.  **Challenge: Large Video File Uploads for Shorts**
    *   *Symptom*: Uploading high-resolution videos caused memory spikes and request termination on the API gateway.
    *   *Resolution*: Configured chunked multipart form-data parser inside the gateway to stream files directly to the target storage volumes instead of buffering them in memory.

---

## 📊 7. Visual Workspace & Trello Tracking

*   **Project Board URL**: [Trello Project Board](https://trello.com/w/projectmanagementskillprof/home)
*   **Evidence Screen**: A screenshot of our active sprint board tracking `Todo`, `In Progress`, `Code Review`, and `Done` states can be viewed below:

![Trello Active Workspace Board](../WhatsApp%20Image%202026-06-05%20at%207.00.42%20AM.jpeg)
