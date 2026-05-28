import { Request, Response } from "express";
import { AppDataSource } from "../data-source";
import { Like } from "../entities/Like";

export class LikeController {
  static async toggleLike(req: Request, res: Response) {
    try {
      const { userId, targetId, targetType } = req.body;
      const likeRepo = AppDataSource.getRepository(Like);
      
      const existingLike = await likeRepo.findOneBy({ userId, targetId, targetType });
      
      if (existingLike) {
        await likeRepo.remove(existingLike);
        const count = await likeRepo.count({ where: { targetId, targetType } });
        return res.json({ success: true, action: 'removed', likesCount: count });
      } else {
        const newLike = likeRepo.create({ userId, targetId, targetType });
        await likeRepo.save(newLike);
        const count = await likeRepo.count({ where: { targetId, targetType } });
        return res.json({ success: true, action: 'added', likesCount: count });
      }
    } catch (error) {
      console.error(error);
      res.status(500).json({ error: "Failed to toggle like" });
    }
  }

  static async getLikesCount(req: Request, res: Response) {
    try {
      const { targetId, targetType } = req.query;
      const likeRepo = AppDataSource.getRepository(Like);
      const count = await likeRepo.count({ where: { targetId: targetId as string, targetType: targetType as string } });
      res.json({ targetId, targetType, count });
    } catch (error) {
      res.status(500).json({ error: "Failed to fetch likes count" });
    }
  }

  static async checkLike(req: Request, res: Response) {
    try {
      const { userId, targetId, targetType } = req.query;
      const likeRepo = AppDataSource.getRepository(Like);
      const existingLike = await likeRepo.findOneBy({ 
        userId: userId as string, 
        targetId: targetId as string, 
        targetType: targetType as string 
      });
      res.json({ isLiked: !!existingLike });
    } catch (error) {
      res.status(500).json({ error: "Failed to check like status" });
    }
  }
}
