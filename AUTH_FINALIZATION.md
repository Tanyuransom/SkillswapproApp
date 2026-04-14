# Google Authentication Finalization Guide

To "perfect" your Google Authentication, you need to link your local app to your Google Cloud project. Since I've already fixed the build errors, follow these steps to make Google Sign-In "live":

### 1. Get your SHA-1 Fingerprint
Run this exact command in your terminal (Command Prompt or PowerShell):
```powershell
keytool -list -v -keystore "C:\Users\Engr  CREEDO\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```
Look for the line that starts with `SHA1:`. Copy that long string of numbers and letters.

### 2. Register in Google Cloud Console
1.  Go to the [Google Cloud Console Credentials Page](https://console.cloud.google.com/apis/credentials).
2.  Click **Create Credentials** > **OAuth client ID**.
3.  Select **Android** as the application type.
4.  **Package Name**: `com.example.skill_swap_pro`
5.  **SHA-1 certificate fingerprint**: Paste the string you copied in Step 1.
6.  Click **Create**.

### 3. Get your Web Client ID
You also need a "Web Application" client ID for the backend to verify tokens:
1.  On the same Credentials page, click **Create Credentials** > **OAuth client ID**.
2.  Select **Web application**.
3.  Give it a name (e.g., "SkillProf Backend").
4.  Click **Create**.
5.  Copy the **Client ID** (it looks like `123456-abc.apps.googleusercontent.com`).

### 4. Update your Config
1.  **Frontend**: Open `c:\SkillSwapPrro\frontend\lib\screens\welcome\welcome_screen.dart` and replace `YOUR_GOOGLE_CLIENT_ID` with the Client ID you just copied.
2.  **Backend**: Open `c:\SkillSwapPrro\backend\auth-service\.env` and replace the placeholder in `GOOGLE_CLIENT_ID`.

---

> [!TIP]
> **I have already added Manual Sign Up!** 
> If you haven't done the steps above yet, you can still click "JOIN AS STUDENT/TUTOR" and select **"Join manually with Email"** to test the full platform experience immediately!
