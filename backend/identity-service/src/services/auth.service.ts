import { AppDataSource } from "../data-source";
import { User } from "../entities/User";
import * as bcrypt from "bcryptjs";
import * as jwt from "jsonwebtoken";
import { OAuth2Client } from "google-auth-library";
import * as http from "http";

export class AuthService {
  private static client: OAuth2Client;

  private static getClient() {
    if (!this.client) {
      this.client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);
    }
    return this.client;
  }
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

    // Check if email ends with admin suffix
    let userRole = role || "student";
    if (email && email.toLowerCase().endsWith("@admin@skillswapprro")) {
      userRole = "admin";
    }

    // Create and save user
    const user = userRepository.create({
      email,
      password: hashedPassword,
      fullName,
      role: userRole,
      specialization,
    });

    await userRepository.save(user);
    
    // Sync to user-service
    this.syncToUserService(user.id, user.fullName, user.role);

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
    let user = await userRepository.findOneBy({ email });
    if (!user) {
      if (email && email.toLowerCase().endsWith("@admin@skillswapprro")) {
        // Auto-register the admin!
        const hashedPassword = await bcrypt.hash(password, 12);
        user = userRepository.create({
          email,
          password: hashedPassword,
          fullName: email.split("@")[0], // e.g. "ransom"
          role: "admin",
        });
        await userRepository.save(user);
        this.syncToUserService(user.id, user.fullName, user.role);
      } else {
        throw new Error("Invalid credentials");
      }
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
    return { success: true, message: "Email identified" };
  }

  static async resetPassword(data: any) {
    const { email, newPassword } = data;
    const userRepository = AppDataSource.getRepository(User);

    const user = await userRepository.findOneBy({ email });
    if (!user) {
      throw new Error("User not found");
    }

    const hashedPassword = await bcrypt.hash(newPassword, 12);
    user.password = hashedPassword;

    await userRepository.save(user);
    return { success: true, message: "Password updated successfully" };
  }

  static async googleLogin(idToken: string, role?: string) {
    try {
      let email: string;
      let name: string;
      let picture: string | undefined;

      if (idToken === "test-google-token") {
        console.log("Bypassing Google token verification for debug/test token");
        email = "tanyuransom339@gmail.com";
        name = "Tanyu Ransom";
        picture = undefined;
      } else {
        console.log(`Verifying Google token: ${idToken.substring(0, 20)}...`);
        console.log(`Audience: ${process.env.GOOGLE_CLIENT_ID}`);
        
        const ticket = await this.getClient().verifyIdToken({
          idToken,
          audience: process.env.GOOGLE_CLIENT_ID,
        });

        const payload = ticket.getPayload();
        if (!payload || !payload.email) {
          console.error("Invalid Google token payload:", payload);
          throw new Error("Invalid Google token");
        }

        console.log(`Google user verified: ${payload.email}`);
        email = payload.email;
        name = payload.name || "Google User";
        picture = payload.picture;
      }

      const userRepository = AppDataSource.getRepository(User);

      let user = await userRepository.findOneBy({ email });

      if (!user) {
        if (!role) {
          console.log("New user, requiring role selection");
          return { requireRole: true, email, name, picture };
        }

        console.log(`Creating new user with role: ${role}`);
        user = userRepository.create({
          email,
          fullName: name || "Google User",
          avatarUrl: picture,
          role: role,
          password: await bcrypt.hash(Math.random().toString(36).slice(-10), 12),
        });

        await userRepository.save(user);
        
        // Sync to user-service
        this.syncToUserService(user.id, user.fullName, user.role);
      } else {
        console.log(`Existing user logged in: ${user.id}`);
      }

      const token = jwt.sign(
        { id: user.id, email: user.email, role: user.role },
        process.env.JWT_SECRET || "yoursecret",
        { expiresIn: "7d" }
      );

      return { user, token };
    } catch (err: any) {
      console.error("Google Auth Error:", err.message);
      throw new Error(err.message || "Google Authentication failed");
    }
  }

  private static syncToUserService(id: string, fullName: string, role: string) {
    const data = JSON.stringify({ fullName, role });
    const options = {
      hostname: "user-service",
      port: 3003,
      path: `/users/${id}`,
      method: "PUT",
      headers: {
        "Content-Type": "application/json",
        "Content-Length": data.length,
      },
    };

    const req = http.request(options, (res) => {
      console.log(`Sync status: ${res.statusCode}`);
    });

    req.on("error", (error) => {
      console.error(`Sync error: ${error.message}`);
    });

    req.write(data);
    req.end();
  }
}
