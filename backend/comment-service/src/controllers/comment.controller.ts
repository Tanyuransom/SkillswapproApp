import { Request, Response } from "express";
import { AppDataSource } from "../data-source";
import { Comment } from "../entities/Comment";

export class CommentController {
  static async addComment(req: Request, res: Response) {
    try {
      const { userId, userName, targetId, targetType, text } = req.body;
      const commentRepo = AppDataSource.getRepository(Comment);
      
      const newComment = commentRepo.create({ userId, userName, targetId, targetType, text });
      await commentRepo.save(newComment);
      
      res.status(201).json(newComment);
    } catch (error) {
      console.error(error);
      res.status(500).json({ error: "Failed to add comment" });
    }
  }

  static async getComments(req: Request, res: Response) {
    try {
      const { targetId, targetType } = req.query;
      const commentRepo = AppDataSource.getRepository(Comment);
      
      const comments = await commentRepo.find({ 
        where: { targetId: targetId as string, targetType: targetType as string },
        order: { createdAt: "DESC" }
      });
      res.json(comments);
    } catch (error) {
      res.status(500).json({ error: "Failed to fetch comments" });
    }
  }

  static async deleteComment(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const commentRepo = AppDataSource.getRepository(Comment);
      const comment = await commentRepo.findOneBy({ id: id as any });
      if (!comment) return res.status(404).json({ error: "Comment not found" });

      await commentRepo.remove(comment);
      res.json({ success: true });
    } catch (error) {
      res.status(500).json({ error: "Failed to delete comment" });
    }
  }
}
