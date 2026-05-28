import { Request, Response } from "express";
import { AppDataSource } from "../data-source";
import { Share } from "../entities/Share";

export class ShareController {
  static async addShare(req: Request, res: Response) {
    try {
      const { userId, targetId, targetType } = req.body;
      const shareRepo = AppDataSource.getRepository(Share);
      
      const newShare = shareRepo.create({ userId, targetId, targetType });
      await shareRepo.save(newShare);
      
      const count = await shareRepo.count({ where: { targetId, targetType } });
      res.status(201).json({ success: true, shareCount: count });
    } catch (error) {
      console.error(error);
      res.status(500).json({ error: "Failed to add share" });
    }
  }

  static async getSharesCount(req: Request, res: Response) {
    try {
      const { targetId, targetType } = req.query;
      const shareRepo = AppDataSource.getRepository(Share);
      const count = await shareRepo.count({ where: { targetId: targetId as string, targetType: targetType as string } });
      res.json({ targetId, targetType, count });
    } catch (error) {
      res.status(500).json({ error: "Failed to fetch shares count" });
    }
  }
}
