import { AppDataSource } from "../data-source";
import { User } from "../entities/User";
import * as bcrypt from "bcryptjs";
import * as jwt from "jsonwebtoken";
import { OAuth2Client } from "google-auth-library";

const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

export class AuthService {
  static async register(data: any) {
    const { email, password, fullName, role, specialization } = data;
    const userRepository = AppDataSource.getRepository(User);

    // Check if user already exists
    const existingUser = await userRepository.findOneBy({ email });
    if (existingUser) {
      throw new Error("User already exists");
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 12);

    // Create and save user
    const user = userRepository.create({
      email,
      password: hashedPassword,
      fullName,
      role: role || "student",
      specialization,
    });

    await userRepository.save(user);
    
    // Generate token
    const token = jwt.sign(
      { id: user.id, email: user.email, role: user.role },
      process.env.JWT_SECRET || "yoursecret",
      { expiresIn: "7d" }
    );

    return { user, token };
  }

  static async login(data: any) {
    const { email, password } = data;
    const userRepository = AppDataSource.getRepository(User);

    // Find user
    const user = await userRepository.findOneBy({ email });
    if (!user) {
       throw new Error("Invalid credentials");
    }

    // Check password
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
       throw new Error("Invalid credentials");
    }

    // Generate token
    const token = jwt.sign(
      { id: user.id, email: user.email, role: user.role },
      process.env.JWT_SECRET || "yoursecret",
      { expiresIn: "7d" }
    );

    return { user, token };
  }

  static async forgotPassword(email: string) {
    const userRepository = AppDataSource.getRepository(User);
    const user = await userRepository.findOneBy({ email });
    if (!user) {
      throw new Error("User with this email does not exist");
    }
    // In a real app, send email/code here. For now, just return success.
    return { success: true, message: "Email identified" };
  }

  static async resetPassword(data: any) {
    const { email, newPassword } = data;
    const userRepository = AppDataSource.getRepository(User);

    const user = await userRepository.findOneBy({ email });
    if (!user) {
      throw new Error("User not found");
    }

    // Hash new password
    const hashedPassword = await bcrypt.hash(newPassword, 12);
    user.password = hashedPassword;

    await userRepository.save(user);
    return { success: true, message: "Password updated successfully" };
  }

  static async getUsersBatch(ids: string[]) {
    try {
      const userRepository = AppDataSource.getRepository(User);
      const users = await userRepository.createQueryBuilder("user")
        .where("user.id IN (:...ids)", { ids })
        .select(["user.id", "user.fullName", "user.email", "user.role", "user.avatarUrl"])
        .getMany();
      return users;
    } catch (err) {
      throw new Error("Failed to fetch users");
    }
  }

  static async updateUser(id: string, data: any) {
    try {
      const userRepository = AppDataSource.getRepository(User);
      const user = await userRepository.findOneBy({ id });
      if (!user) {
        throw new Error("User not found");
      }

      if (data.fullName) user.fullName = data.fullName;
      if (data.specialization) user.specialization = data.specialization;
      if (data.avatarUrl) user.avatarUrl = data.avatarUrl;

      await userRepository.save(user);
      return user;
    } catch (err: any) {
      throw new Error(err.message || "Failed to update user");
    }
  }

  static async getUserById(id: string) {
    try {
      const userRepository = AppDataSource.getRepository(User);
      const user = await userRepository.findOne({
        where: { id },
        select: ["id", "email", "fullName", "role", "specialization", "avatarUrl", "createdAt"]
      });
      if (!user) {
        throw new Error("User not found");
      }
      return user;
    } catch (err: any) {
      throw new Error(err.message || "Failed to fetch user");
    }
  }

  static async googleLogin(idToken: string, role?: string) {
    try {
      if (!process.env.GOOGLE_CLIENT_ID || process.env.GOOGLE_CLIENT_ID.includes('placeholder')) {
        console.warn("GOOGLE_CLIENT_ID is not configured in .env");
      }

      const ticket = await client.verifyIdToken({
        idToken,
        audience: process.env.GOOGLE_CLIENT_ID,
      });

      const payload = ticket.getPayload();
      if (!payload || !payload.email) {
        throw new Error("Invalid Google token");
      }

      const { email, name, picture } = payload;
      const userRepository = AppDataSource.getRepository(User);

      let user = await userRepository.findOneBy({ email });

      if (!user) {
        // If user is new and no role provided, we need them to pick one
        if (!role) {
          return { requireRole: true, email, name, picture };
        }

        // Create new user with selected role
        user = userRepository.create({
          email,
          fullName: name || "Google User",
          avatarUrl: picture,
          role: role,
          password: await bcrypt.hash(Math.random().toString(36).slice(-10), 12), // Placeholder password
        });

        await userRepository.save(user);
      }

      // Generate token
      const token = jwt.sign(
        { id: user.id, email: user.email, role: user.role },
        process.env.JWT_SECRET || "yoursecret",
        { expiresIn: "7d" }
      );

      return { user, token };
    } catch (err: any) {
      throw new Error(err.message || "Google Authentication failed");
    }
  }
}
