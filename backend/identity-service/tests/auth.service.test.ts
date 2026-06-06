import { AppDataSource } from "../src/data-source";
import { AuthService } from "../src/services/auth.service";
import { User } from "../src/entities/User";
import * as bcrypt from "bcryptjs";
import * as jwt from "jsonwebtoken";
import * as http from "http";

const mockHash = jest.fn();
const mockCompare = jest.fn();

jest.mock("../src/data-source", () => ({
  AppDataSource: {
    getRepository: jest.fn()
  }
}));

jest.mock("bcryptjs", () => ({
  __esModule: true,
  hash: (pwd: string, salt: any) => mockHash(pwd, salt),
  compare: (pwd: string, hash: string) => mockCompare(pwd, hash),
  default: {
    hash: (pwd: string, salt: any) => mockHash(pwd, salt),
    compare: (pwd: string, hash: string) => mockCompare(pwd, hash)
  }
}));

jest.mock("google-auth-library", () => {
  const mockTicket = {
    getPayload: jest.fn().mockReturnValue({
      email: "tanyuransom339@gmail.com",
      name: "Tanyu Ransom",
      picture: "http://example.com/avatar.jpg"
    })
  };
  const mockClient = {
    verifyIdToken: jest.fn().mockImplementation(async ({ idToken }) => {
      if (idToken === "invalid-real-token") {
        throw new Error("Invalid Google token");
      }
      return mockTicket;
    })
  };
  return {
    OAuth2Client: jest.fn().mockImplementation(() => mockClient)
  };
});

jest.mock("http", () => {
  const mockReq = {
    on: jest.fn(),
    write: jest.fn(),
    end: jest.fn()
  };
  return {
    __esModule: true,
    request: jest.fn().mockReturnValue(mockReq),
    default: {
      request: jest.fn().mockReturnValue(mockReq)
    }
  };
});

describe("AuthService Unit Tests", () => {
  let mockRepository: any;

  beforeEach(() => {
    jest.clearAllMocks();
    mockHash.mockImplementation(async (pwd: string) => `hash-${pwd}`);
    mockCompare.mockImplementation(async (pwd: string, hash: string) => pwd !== "wrongpassword");
    mockRepository = {
      findOneBy: jest.fn(),
      create: jest.fn(),
      save: jest.fn(),
      update: jest.fn(),
      delete: jest.fn()
    };
    (AppDataSource.getRepository as jest.Mock).mockReturnValue(mockRepository);

    // Set up http.request mock return value before each test
    const mockReq = {
      on: jest.fn(),
      write: jest.fn(),
      end: jest.fn()
    };
    (http.request as jest.Mock).mockReturnValue(mockReq);
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
      const hashedPassword = await bcrypt.hash("adminpassword", 12);
      const mockUser = {
        id: "admin-id",
        email: "john@admin@skillswapprro",
        fullName: "john",
        role: "admin",
        password: hashedPassword
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

  describe("googleLogin", () => {
    it("should login existing google user successfully", async () => {
      const mockUser = {
        id: "google-user-123",
        email: "tanyuransom339@gmail.com",
        fullName: "Tanyu Ransom",
        role: "student"
      };
      mockRepository.findOneBy.mockResolvedValue(mockUser);

      const result = await AuthService.googleLogin("test-google-token");
      expect(result).toHaveProperty("token");
      expect(result.user.id).toEqual("google-user-123");
    });

    it("should return requireRole true if google user is new and no role is provided", async () => {
      mockRepository.findOneBy.mockResolvedValue(null);

      const result = await AuthService.googleLogin("test-google-token");
      expect(result).toHaveProperty("requireRole", true);
      expect(result).toHaveProperty("email", "tanyuransom339@gmail.com");
    });

    it("should auto-register and login new google user if role is provided", async () => {
      mockRepository.findOneBy.mockResolvedValue(null);
      const mockUser = {
        id: "new-google-user",
        email: "tanyuransom339@gmail.com",
        fullName: "Tanyu Ransom",
        role: "tutor"
      };
      mockRepository.create.mockReturnValue(mockUser);
      mockRepository.save.mockResolvedValue(mockUser);

      const result = await AuthService.googleLogin("test-google-token", "tutor");
      expect(result).toHaveProperty("token");
      expect(result.user.role).toEqual("tutor");
      expect(mockRepository.create).toHaveBeenCalled();
      expect(mockRepository.save).toHaveBeenCalled();
    });

    it("should throw error if google verification fails", async () => {
      await expect(
        AuthService.googleLogin("invalid-real-token")
      ).rejects.toThrow();
    });
  });
});
