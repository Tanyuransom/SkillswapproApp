import { AppDataSource } from "../data-source";
import { User } from "../entities/User";

export class UserService {
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
      let user = await userRepository.findOneBy({ id });
      
      if (!user) {
        // Create user if they don't exist yet (resiliency for missing sync)
        user = userRepository.create({
          id,
          fullName: data.fullName || "User",
          role: data.role || "student",
          email: data.email,
          avatarUrl: data.avatarUrl,
        });
      }

      if (data.fullName) user.fullName = data.fullName;
      if (data.email) user.email = data.email;
      if (data.role) user.role = data.role;
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

  static async getAllUsers() {
    try {
      const userRepository = AppDataSource.getRepository(User);
      const users = await userRepository.find({
        select: ["id", "email", "fullName", "role", "specialization", "avatarUrl", "createdAt"]
      });
      return users;
    } catch (err) {
      throw new Error("Failed to fetch all users");
    }
  }

  static async createUser(data: any) {
    try {
      const userRepository = AppDataSource.getRepository(User);
      const user = userRepository.create({
        id: data.id || Math.random().toString(36).substring(2, 15),
        email: data.email,
        fullName: data.fullName,
        role: data.role || "student",
        specialization: data.specialization,
        avatarUrl: data.avatarUrl,
      });
      await userRepository.save(user);
      return user;
    } catch (err: any) {
      throw new Error(err.message || "Failed to create user");
    }
  }

  static async deleteUser(id: string) {
    try {
      const userRepository = AppDataSource.getRepository(User);
      const user = await userRepository.findOneBy({ id });
      if (!user) {
        throw new Error("User not found");
      }
      await userRepository.remove(user);
      return { success: true };
    } catch (err: any) {
      throw new Error(err.message || "Failed to delete user");
    }
  }
}
