import request from "supertest";
import app from "../src/app";
import { AuthService } from "../src/services/auth.service";

// Mock the AuthService completely
jest.mock("../src/services/auth.service");

describe("Auth Controller & Routes", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe("GET /health", () => {
    it("should return 200 and status UP", async () => {
      const res = await request(app).get("/health");
      expect(res.statusCode).toEqual(200);
      expect(res.body).toHaveProperty("status", "UP (Identity)");
    });
  });

  describe("POST /register", () => {
    it("should register a new user successfully", async () => {
      const mockResult = {
        user: { id: "123", email: "test@example.com", fullName: "Test User", role: "student" },
        token: "mock-jwt-token"
      };
      (AuthService.register as jest.Mock).mockResolvedValue(mockResult);

      const res = await request(app)
        .post("/register")
        .send({ email: "test@example.com", password: "password123", fullName: "Test User", role: "student" });

      expect(res.statusCode).toEqual(201);
      expect(res.body).toHaveProperty("token", "mock-jwt-token");
      expect(res.body.user).toHaveProperty("id", "123");
      expect(AuthService.register).toHaveBeenCalledTimes(1);
    });

    it("should return 400 on service error", async () => {
      (AuthService.register as jest.Mock).mockRejectedValue(new Error("User already exists"));

      const res = await request(app)
        .post("/register")
        .send({ email: "test@example.com", password: "password123", fullName: "Test User" });

      expect(res.statusCode).toEqual(400);
      expect(res.body).toHaveProperty("error", "User already exists");
    });
  });

  describe("POST /login", () => {
    it("should login successfully with correct credentials", async () => {
      const mockResult = {
        user: { id: "123", email: "test@example.com", fullName: "Test User", role: "student" },
        token: "mock-jwt-token"
      };
      (AuthService.login as jest.Mock).mockResolvedValue(mockResult);

      const res = await request(app)
        .post("/login")
        .send({ email: "test@example.com", password: "password123" });

      expect(res.statusCode).toEqual(200);
      expect(res.body).toHaveProperty("token", "mock-jwt-token");
      expect(AuthService.login).toHaveBeenCalledTimes(1);
    });

    it("should return 401 on invalid credentials", async () => {
      (AuthService.login as jest.Mock).mockRejectedValue(new Error("Invalid credentials"));

      const res = await request(app)
        .post("/login")
        .send({ email: "test@example.com", password: "wrongpassword" });

      expect(res.statusCode).toEqual(401);
      expect(res.body).toHaveProperty("error", "Invalid credentials");
    });
  });

  describe("POST /forgot-password", () => {
    it("should verify email registration", async () => {
      (AuthService.forgotPassword as jest.Mock).mockResolvedValue({ success: true, message: "Email identified" });

      const res = await request(app)
        .post("/forgot-password")
        .send({ email: "test@example.com" });

      expect(res.statusCode).toEqual(200);
      expect(res.body).toHaveProperty("success", true);
      expect(AuthService.forgotPassword).toHaveBeenCalledTimes(1);
    });
  });

  describe("POST /reset-password", () => {
    it("should reset password successfully", async () => {
      (AuthService.resetPassword as jest.Mock).mockResolvedValue({ success: true, message: "Password updated successfully" });

      const res = await request(app)
        .post("/reset-password")
        .send({ email: "test@example.com", newPassword: "newpassword123" });

      expect(res.statusCode).toEqual(200);
      expect(res.body).toHaveProperty("success", true);
      expect(AuthService.resetPassword).toHaveBeenCalledTimes(1);
    });
  });

  describe("POST /google-login", () => {
    it("should login with google token successfully", async () => {
      const mockResult = {
        user: { id: "google-123", email: "google@example.com", fullName: "Google User", role: "tutor" },
        token: "mock-jwt-token"
      };
      (AuthService.googleLogin as jest.Mock).mockResolvedValue(mockResult);

      const res = await request(app)
        .post("/google-login")
        .send({ idToken: "test-google-token", role: "tutor" });

      expect(res.statusCode).toEqual(200);
      expect(res.body).toHaveProperty("token", "mock-jwt-token");
      expect(AuthService.googleLogin).toHaveBeenCalledTimes(1);
    });
  });
});
