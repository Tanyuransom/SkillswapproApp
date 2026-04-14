# SkillProf (SkillSwap) Development Roadmap

This roadmap outlines the step-by-step implementation plan for the SkillProf peer-to-peer skill exchange platform, based on the provided requirements and microservices architecture. The mobile app will be built using Dart (Flutter) and powered by an event-driven Firebase backend.

## Proposed Changes

We will approach this using a phased development lifecycle following Scrum principles mentioned in the document. 

### Phase 1: Project Setup and Architecture Foundation
- **Initialize Flutter App:** Set up the Dart project structure using Clean Architecture principles, defining layers for Repositories, Singletons, and UI.
- **Theme & Styles:** Configure consistent coloring (Purple `#7B61FF`, Orange, Yellow) and typography.
- **Firebase Initialization:** Setup Firebase project and environment variables.
- **Setup API Gateway:** Establish foundational Cloud Functions to handle simple requests.

### Phase 2: Onboarding & Authentication
- **Onboarding Views:** Build 3 Welcome screens with smooth navigation.
- **Authentication Flows:** Sign up (Student/Tutor logic), Sign in, and password recovery.
- **Backend Service:** Integrate Firebase Authentication (JWT) and User Profile Service (Firestore).

### Phase 3: Core Dashboard & Skill Discovery
- **Dashboard UI:** Displays Learn/Teach categories, trending offers, and targeted recommendations.
- **Skill Discovery Service:** Implement search with voice input, filtering capabilities, and category-based browsing.
- **Course Detail Cards:** Showcase course outlines, pricing schemas (100,000fr - 150,000fr), and "Pay to learn" functionality.

### Phase 4: Content Creation & Verification
- **AI Skill Exam Flow:** Implement the flow where tutors take AI-generated examinations for practical knowledge verification.
- **Content Management Service:** Build capabilities for verified tutors to upload PDF/Video lessons to Firebase Cloud Storage, handle gallery/folder selections.

### Phase 5: Transactions & Communications
- **Payment Service:** Integrate Mobile money payments (MTN/Orange) with checkout and tax calculation mechanisms.
- **Messaging Service:** Build real-time inbox messaging via Firestore listeners for direct student-tutor communication.
- **Quality Systems:** Develop the rating/review mechanisms and connect to user profiles.

### Phase 6: Polish, Notifications & Blogging
- **Notification Service:** Setup Firebase Cloud Messaging for payment alerts, offers, and app notifications.
- **Blog Section:** Develop the discovery dashboard with featured articles.
### Phase 7: Advanced User Roles & Management
- **Role-Based Navigation:** Implement `UserRole` enum and `SessionService` to toggle interfaces dynamically.
- **Tutor Center:** Build a specialized dashboard for verified tutors to upload lessons and track student participation.
- **Admin Control Panel:** Develop a secure management interface for entry moderation (Accept/Delete) and certificate issuance.

### Final Checks
- **Comprehensive Testing:** UI/UX verification across all three user roles using emulator and Edge.
- **Production Readiness:** Final performance audits and 0-issue analysis. 
