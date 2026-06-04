# Google Authentication Finalization Guide

To finalize your Google Authentication, you must register your app in your Google Cloud Console using your local machine's security credentials.

Follow these step-by-step instructions:

### 1. Your Extracted Fingerprints
I have successfully extracted the certificate fingerprints of your local machine's Android debug keystore:
* **SHA-1 Fingerprint**: `A5:A9:14:9E:15:09:1A:8E:88:6F:2D:86:4D:A8:74:AE:7B:60:8F:63`
* **SHA-256 Fingerprint**: `13:F7:87:A8:5D:52:3D:3A:46:14:3C:D7:F9:36:4E:6D:B3:B4:AE:8C:D3:FC:3F:41:B7:35:37:B6:3A:AF:D9:61`

---

### 2. Register in Google Cloud Console
1. Open the [Google Cloud Console Credentials Page](https://console.cloud.google.com/apis/credentials).
2. Click **Create Credentials** > **OAuth client ID**.
3. Select **Android** as the Application type.
4. Fill in:
   - **Package Name**: `com.example.skill_swap_pro`
   - **SHA-1 Certificate Fingerprint**: `A5:A9:14:9E:15:09:1A:8E:88:6F:2D:86:4D:A8:74:AE:7B:60:8F:63`
5. Click **Create**.

---

### 3. Get your Web Client ID (for Backend Verification)
1. On the same Credentials page, click **Create Credentials** > **OAuth client ID**.
2. Select **Web application** (this is used by Flutter to authenticate with your Node.js backend).
3. Name it (e.g. `SkillProf Backend`).
4. Click **Create**.
5. Copy the generated **Client ID** (it looks like `103593137684-xxxx.apps.googleusercontent.com`).

---

### 4. Update the Config Files
If you create a new client ID, make sure to update these two files in your project with the new Client ID:
1. **Frontend**: [auth_helper.dart](file:///c:/SkillSwapPrro/frontend/lib/utils/auth_helper.dart#L10) (inside the `serverClientId` field).
2. **Backend**: [identity-service/.env](file:///c:/SkillSwapPrro/backend/identity-service/.env#L4) (inside the `GOOGLE_CLIENT_ID` field).

---

> [!TIP]
> **Manual Sign-Up works!**
> While configuring Google Auth, users can sign up and sign in using **"Join manually with Email"** to test all features (including courses and lessons) immediately!
