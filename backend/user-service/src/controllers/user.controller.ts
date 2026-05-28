import { Request, Response } from "express";
import { UserService } from "../services/user.service";
import { AppDataSource } from "../data-source";
import { Follow } from "../entities/Follow";

export class UserController {
  static async followTutor(req: Request, res: Response) {
    try {
      const { followerId, tutorId } = req.body;
      if (!followerId || !tutorId) {
        return res.status(400).json({ error: "followerId and tutorId are required" });
      }
      const followRepo = AppDataSource.getRepository(Follow);
      const existing = await followRepo.findOneBy({ followerId, tutorId });
      if (existing) {
        return res.status(200).json({ success: true, message: "Already following", follow: existing });
      }
      const follow = followRepo.create({ followerId, tutorId });
      await followRepo.save(follow);
      res.status(201).json({ success: true, action: "followed", follow });
    } catch (err: any) {
      res.status(500).json({ error: err.message || "Failed to follow tutor" });
    }
  }

  static async unfollowTutor(req: Request, res: Response) {
    try {
      const { followerId, tutorId } = req.body;
      if (!followerId || !tutorId) {
        return res.status(400).json({ error: "followerId and tutorId are required" });
      }
      const followRepo = AppDataSource.getRepository(Follow);
      const existing = await followRepo.findOneBy({ followerId, tutorId });
      if (existing) {
        await followRepo.remove(existing);
      }
      res.status(200).json({ success: true, action: "unfollowed" });
    } catch (err: any) {
      res.status(500).json({ error: err.message || "Failed to unfollow tutor" });
    }
  }

  static async checkFollowStatus(req: Request, res: Response) {
    try {
      const { followerId, tutorId } = req.query;
      if (!followerId || !tutorId) {
        return res.status(400).json({ error: "followerId and tutorId are required" });
      }
      const followRepo = AppDataSource.getRepository(Follow);
      const existing = await followRepo.findOneBy({ 
        followerId: followerId as string, 
        tutorId: tutorId as string 
      });
      res.status(200).json({ isFollowing: !!existing });
    } catch (err: any) {
      res.status(500).json({ error: err.message || "Failed to check follow status" });
    }
  }

  static async getFollowers(req: Request, res: Response) {
    try {
      const { tutorId } = req.params;
      const followRepo = AppDataSource.getRepository(Follow);
      const follows = await followRepo.find({
        where: { tutorId },
        select: ["followerId"]
      });
      res.status(200).json(follows.map(f => f.followerId));
    } catch (err: any) {
      res.status(500).json({ error: err.message || "Failed to get followers" });
    }
  }

  static async getUsersBatch(req: Request, res: Response) {
    try {
      const { ids } = req.body;
      const users = await UserService.getUsersBatch(ids);
      res.status(200).json(users);
    } catch (err: any) {
      res.status(400).json({ error: err.message });
    }
  }

  static async updateUser(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const user = await UserService.updateUser(id, req.body);
      res.status(200).json(user);
    } catch (err: any) {
      res.status(400).json({ error: err.message });
    }
  }

  static async getUser(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const user = await UserService.getUserById(id);
      res.status(200).json(user);
    } catch (err: any) {
      res.status(404).json({ error: err.message });
    }
  }

  static async getAllUsers(req: Request, res: Response) {
    try {
      const users = await UserService.getAllUsers();
      res.status(200).json(users);
    } catch (err: any) {
      res.status(400).json({ error: err.message });
    }
  }

  static async createUser(req: Request, res: Response) {
    try {
      const user = await UserService.createUser(req.body);
      res.status(201).json(user);
    } catch (err: any) {
      res.status(400).json({ error: err.message });
    }
  }

  static async deleteUser(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const result = await UserService.deleteUser(id);
      res.status(200).json(result);
    } catch (err: any) {
      res.status(400).json({ error: err.message });
    }
  }
}
