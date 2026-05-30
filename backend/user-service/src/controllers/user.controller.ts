import { Request, Response } from "express";
import { UserService } from "../services/user.service";
import { AppDataSource } from "../data-source";
import { Follow } from "../entities/Follow";
import axios from "axios";

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
      
      const { fullName, avatarUrl } = req.body;
      if (fullName !== undefined || avatarUrl !== undefined) {
        // Asynchronously propagate profile updates to other services
        axios.put(`http://course-service:3002/instructor/${id}`, { fullName, avatarUrl })
          .catch(err => console.error("Failed to propagate profile updates to course-service:", err.message));
        axios.put(`http://shorts-service:3005/tutor/${id}`, { fullName, avatarUrl })
          .catch(err => console.error("Failed to propagate profile updates to shorts-service:", err.message));
      }

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

  static async addAppReview(req: Request, res: Response) {
    try {
      const { userId, rating, comment } = req.body;
      if (!rating) {
        return res.status(400).json({ error: "Rating is required" });
      }

      const path = require("path");
      const fs = require("fs");
      const feedbackDir = path.join(__dirname, "../../uploads");
      if (!fs.existsSync(feedbackDir)) {
        fs.mkdirSync(feedbackDir, { recursive: true });
      }
      const feedbackPath = path.join(feedbackDir, "feedback.json");

      let reviews: any[] = [];
      if (fs.existsSync(feedbackPath)) {
        try {
          const content = fs.readFileSync(feedbackPath, "utf-8");
          reviews = JSON.parse(content);
        } catch (e) {
          console.error("Error reading feedback.json", e);
        }
      }

      reviews.push({
        userId: userId || "anonymous",
        rating,
        comment: comment || "",
        createdAt: new Date()
      });

      fs.writeFileSync(feedbackPath, JSON.stringify(reviews, null, 2), "utf-8");
      res.status(201).json({ success: true, message: "Feedback submitted successfully" });
    } catch (err: any) {
      res.status(500).json({ error: err.message || "Failed to save feedback" });
    }
  }
}
