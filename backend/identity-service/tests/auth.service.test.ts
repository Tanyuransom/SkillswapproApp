import { AppDataSource } from "../src/data-source";
import { AuthService } from "../src/services/auth.service";
import { User } from "../src/entities/User";
import * as bcrypt from "bcryptjs";
import * as jwt from "jsonwebtoken";
import http from "http";

jest.mock("../src/data-source", () => ({
  AppDataSource: {
    getRepository: jest.fn()
  }
}));

jest.mock("http", () => ({
  request: jest.fn().mockReturnValue({
    on: jest.fn(),
    write: jest.fn(),
    end: jest.fn()
  })
}));

describe("AuthService Unit Tests", () => {
  let mockRepository: any;

  beforeEach(() => {
    jest.clearAllMocks();
    mockRepository = {
      findOneBy: jest.fn(),
      create: jest.fn(),
      save: jest.fn(),
      update: jest.fn(),
      delete: jest.fn()
    };
    (AppDataSource.getRepository as jest.Mock).mockReturnValue(mockRepository);
  });

  describe("register", () => {
    it("should successfully register a new student user", async () => {
      mockRepository.findOneBy.mockResolvedValue(null); // No existing user
      const mockUser = {
        id: "user-id-123",
        email: "student@example.com",
        fullName: "Student User",
        role: "student",
        specialization: "CS"
      };
      mockRepository.create.mockReturnValue(mockUser);
      mockRepository.save.mockResolvedValue(mockUser);

      const result = await AuthService.register({
        email: "student@example.com",
        password: "password123",
        fullName: "Student User",
        role: "student",
        specialization: "CS"
      });

      expect(result).toHaveProperty("token");
      expect(result.user).toHaveProperty("id", "user-id-123");
      expect(mockRepository.findOneBy).toHaveBeenCalledWith({ email: "student@example.com" });
      expect(mockRepository.create).toHaveBeenCalled();
      expect(mockRepository.save).toHaveBeenCalled();
    });

    it("should auto-assign admin role if email ends with @admin@skillswapprro", async () => {
      mockRepository.findOneBy.mockResolvedValue(null);
      const mockUser = {
        id: "admin-id",
        email: "john@admin@skillswapprro",
        fullName: "john",
        role: "admin"
      };
      mockRepository.create.mockReturnValue(mockUser);
      mockRepository.save.mockResolvedValue(mockUser);

      const result = await AuthService.register({
        email: "john@admin@skillswapprro",
        password: "adminpassword",
        fullName: "john"
      });

      expect(result.user.role).toEqual("admin");
    });

    it("should throw error if user already exists", async () => {
      mockRepository.findOneBy.mockResolvedValue({ id: "existing" });

      await expect(
        AuthService.register({
          email: "student@example.com",
          password: "password123",
          fullName: "Student User"
        })
      ).rejects.toThrow("User already exists");
    });
  });

  describe("login", () => {
    it("should successfully login existing user with correct password", async () => {
      const hashedPassword = await bcrypt.hash("password123", 12);
      const mockUser = {
        id: "user-id-123",
        email: "student@example.com",
        password: hashedPassword,
        fullName: "Student User",
        role: "student"
      };
      mockRepository.findOneBy.mockResolvedValue(mockUser);

      const result = await AuthService.login({
        email: "student@example.com",
        password: "password123"
      });

      expect(result).toHaveProperty("token");
      expect(result.user.id).toEqual("user-id-123");
    });

    it("should auto-register admin if admin email is not found", async () => {
      mockRepository.findOneBy.mockResolvedValue(null);
      const mockUser = {
        id: "admin-id",
        email: "john@admin@skillswapprro",
        fullName: "john",
        role: "admin",
        password: "hashedpassword"
      };
      mockRepository.create.mockReturnValue(mockUser);
      mockRepository.save.mockResolvedValue(mockUser);

      const result = await AuthService.login({
        email: "john@admin@skillswapprro",
        password: "adminpassword"
      });

      expect(result.user.role).toEqual("admin");
    });

    it("should throw error if invalid credentials", async () => {
      mockRepository.findOneBy.mockResolvedValue(null); // User not found

      await expect(
        AuthService.login({
          email: "student@example.com",
          password: "password123"
        })
      ).rejects.toThrow("Invalid credentials");
    });

    it("should throw error if password does not match", async () => {
      const hashedPassword = await bcrypt.hash("password123", 12);
      const mockUser = {
        id: "user-id-123",
        email: "student@example.com",
        password: hashedPassword,
        fullName: "Student User"
      };
      mockRepository.findOneBy.mockResolvedValue(mockUser);

      await expect(
        AuthService.login({
          email: "student@example.com",
          password: "wrongpassword"
        })
      ).rejects.toThrow("Invalid credentials");
    });
  });

  describe("forgotPassword", () => {
    it("should return success when email is registered", async () => {
      mockRepository.findOneBy.mockResolvedValue({ id: "user-id" });

      const result = await AuthService.forgotPassword("student@example.com");
      expect(result).toEqual({ success: true, message: "Email identified" });
    });

    it("should throw error if email is not found", async () => {
      mockRepository.findOneBy.mockResolvedValue(null);

      await expect(
        AuthService.forgotPassword("unknown@example.com")
      ).rejects.toThrow("User with this email does not exist");
    });
  });

  describe("resetPassword", () => {
    it("should update password for registered user", async () => {
      const mockUser = {
        id: "user-id",
        email: "student@example.com",
        password: "oldpassword"
      };
      mockRepository.findOneBy.mockResolvedValue(mockUser);
      mockRepository.save.mockResolvedValue(mockUser);

      const result = await AuthService.resetPassword({
        email: "student@example.com",
        newPassword: "newpassword123"
      });

      expect(result).toEqual({ success: true, message: "Password updated successfully" });
      expect(mockRepository.save).toHaveBeenCalled();
    });

    it("should throw error if user not found during reset", async () => {
      mockRepository.findOneBy.mockResolvedValue(null);

      await expect(
        AuthService.resetPassword({
          email: "unknown@example.com",
          newPassword: "newpassword123"
        })
      ).rejects.toThrow("User not found");
    });
  });
});
