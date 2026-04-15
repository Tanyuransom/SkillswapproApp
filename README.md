<h1 align="center">
  <br>
  SkillSwap Pro
  <br>
</h1>

<h4 align="center">A peer-to-peer, dual-role educational platform empowering users to teach, learn, and grow.</h4>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#tech-stack">Tech Stack</a> •
  <a href="#architecture">Architecture</a> •
  <a href="#getting-started">Getting Started</a>
</p>

---

## 📖 Overview

**SkillSwap Pro** is an innovative educational ecosystem built to bridge the gap between eager learners and skilled professionals. Unlike traditional learning management systems, SkillSwap Pro actively promotes micro-learning through dynamic **Shorts**, direct peer-to-peer **Mentorship Messaging**, and comprehensive **Tutor Command Centers**.

Users can seamlessly swap between learning new skills and monetizing their own expertise—all wrapped in a beautifully designed, premium mobile interface.

## ✨ Features

*   **Dual-Role Authentication:** Users can selectively onboard as **Students** (to browse and enroll in courses) or **Tutors** (to upload content, teach, and track their monetization stats).
*   **Micro-learning "Shorts" Feed:** A dedicated TikTok-style chronological feed where tutors upload short, engaging video tips.
*   **Real-Time Direct Messaging:** Integrated chat infrastructure allowing direct communication and mentorship between students and their enrolled tutors.
*   **Live Notification Center:** Application-wide notification badges alerting users to new enrollments, unread messages, and platform updates.
*   **Media Processing:** Seamless native video streaming optimized for mobile via Android ExoPlayer.
*   **Secure API Layer:** JSON Web Token (JWT) authenticated microservices ensuring secure data distribution across users.

## 🛠 Tech Stack

**Client Application (Frontend)**
*   **Framework:** Flutter (Dart)
*   **State & Networking:** Standard `http` package, robust custom Session Management
*   **Media:** `video_player`, `image_picker`
*   **Architecture:** Feature-first Screen routing

**Microservices Building Blocks (Backend)**
*   **Runtime:** Node.js (TypeScript)
*   **Framework:** Express.js
*   **Database:** PostgreSQL 15
*   **ORM:** TypeORM
*   **Authentication:** JWT, Google OAuth 2.0 Integration
*   **Containerization:** Docker & Docker Compose

## 🏗 Architecture 

The backend infrastructure is split into microservices for modular scalability:

1.  **Auth Service (Port 3001):** Responsible for registration, JWT generation, user roles, profile data, and physical avatar uploads.
2.  **Course Service (Port 3002):** Responsible for fetching discovery catalogs, handling direct messaging arrays, notification read-states, and serving heavy media chunks for the Shorts video feed.
3.  **Database Layer (Postgres:5432):** Shared database accessed by both services strictly localized via Docker volumes.

*Note: The frontend Flutter application utilizes a dynamic `UrlHelper` to reliably map internal relative paths (`/uploads/shorts/...`) from both independent backend service ports to the host's physical IP address.*

## 🚀 Getting Started

### Prerequisites
*   [Flutter SDK](https://docs.flutter.dev/get-started/install)
*   [Docker Desktop](https://www.docker.com/products/docker-desktop/)
*   Node.js & npm (for local backend debugging)

### 1. Launch the Backend Infrastructure
Navigate into the backend project folder and utilize `docker-compose` to spin up the PostgreSQL database and both microservices simultaneously.
```bash
cd backend
docker-compose up -d --build
```
*The Auth Service will run on `http://localhost:3001` and the Course Service on `http://localhost:3002`.*

### 2. Configure the Frontend IP
Since Flutter physical devices cannot resolve `localhost`, you must point the app to your computer's local network IP address.
*   Open `frontend/lib/services/api_service.dart`.
*   Update `hostIp` to your active IPv4 Address:
```dart
static const String hostIp = '192.168.1.XXX'; 
```

### 3. Run the Mobile Application
Ensure you have an emulator running or a physical device connected with developer debugging enabled.
```bash
cd frontend
flutter run
```

## 🔒 Security Notes
*   **Cleartext Traffic:** For local development, Android native instances (specifically `video_player`) prohibit unencrypted HTTP streaming. We have explicitly enabled `usesCleartextTraffic="true"` inside `AndroidManifest.xml` to allow raw local testing. Before deploying to production, secure the backend endpoints with SSL/HTTPS and disable this flag.
