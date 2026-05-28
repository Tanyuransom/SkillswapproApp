import { Request, Response } from "express";
import { AppDataSource } from "../data-source";
import { Notification } from "../entities/Notification";

export class NotificationController {
  static async getNotifications(req: Request, res: Response) {
    try {
      const { userId } = req.params;
      const notificationRepository = AppDataSource.getRepository(Notification);
      
      const notifications = await notificationRepository.find({
        where: { userId },
        order: { createdAt: "DESC" }
      });

      res.status(200).json(notifications);
    } catch (error: any) {
      res.status(500).json({ error: error.message });
    }
  }

  static async markAsRead(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const notificationRepository = AppDataSource.getRepository(Notification);
      
      const notification = await notificationRepository.findOneBy({ id });
      if (!notification) {
        return res.status(404).json({ error: "Notification not found" });
      }

      notification.isRead = true;
      await notificationRepository.save(notification);
      
      res.status(200).json(notification);
    } catch (error: any) {
      res.status(500).json({ error: error.message });
    }
  }

  static async createNotification(req: Request, res: Response) {
      try {
        const { userId, title, message, type } = req.body;
        const notificationRepository = AppDataSource.getRepository(Notification);
        
        const notification = notificationRepository.create({
          userId,
          title,
          message,
          type
        });

        await notificationRepository.save(notification);
        res.status(201).json(notification);
      } catch (error: any) {
        res.status(500).json({ error: error.message });
      }
  }
}
