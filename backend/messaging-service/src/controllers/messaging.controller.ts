import { Request, Response } from "express";
import { AppDataSource } from "../data-source";
import { Message } from "../entities/Message";
import * as http from "http";

export class MessagingController {
  static async sendMessage(req: Request, res: Response) {
    try {
      const { senderId, receiverId, content, senderName, senderAvatarUrl, senderRole } = req.body;
      const messageRepository = AppDataSource.getRepository(Message);
      
      const message = messageRepository.create({
        senderId,
        receiverId,
        content,
        senderName,
        senderAvatarUrl,
        senderRole,
      });

      await messageRepository.save(message);

      // Trigger Notification
      this.triggerNotification(receiverId, senderName || "Someone", content);

      res.status(201).json(message);
    } catch (error: any) {
      res.status(500).json({ error: error.message });
    }
  }

  private static triggerNotification(userId: string, senderName: string, content: string) {
    const messageContent = content || "";
    const data = JSON.stringify({
      userId,
      title: `New Message from ${senderName}`,
      message: messageContent.length > 50 ? messageContent.substring(0, 47) + "..." : messageContent,
      type: "MESSAGE"
    });

    const options = {
      hostname: "notification-service",
      port: 3007,
      path: "/notifications",
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Content-Length": data.length,
      },
    };

    const req = http.request(options, (res) => {
      console.log(`Notification status: ${res.statusCode}`);
    });

    req.on("error", (error) => {
      console.error(`Notification error: ${error.message}`);
    });

    req.write(data);
    req.end();
  }

  static async getMessages(req: Request, res: Response) {
    try {
      const { userId } = req.params;
      const messageRepository = AppDataSource.getRepository(Message);
      
      const messages = await messageRepository.find({
        where: [
          { senderId: userId },
          { receiverId: userId }
        ],
        order: { createdAt: "DESC" }
      });

      res.status(200).json(messages);
    } catch (error: any) {
      res.status(500).json({ error: error.message });
    }
  }

  static async getConversations(req: Request, res: Response) {
    try {
      const { userId } = req.params;
      const messageRepository = AppDataSource.getRepository(Message);
      
      const messages = await messageRepository.find({
        where: [
          { senderId: userId },
          { receiverId: userId }
        ],
        order: { createdAt: "DESC" }
      });

      const conversationsMap: { [key: string]: any } = {};

      // First pass: collect latest message info per conversation
      for (const msg of messages) {
        const partnerId = msg.senderId === userId ? msg.receiverId : msg.senderId;
        if (!conversationsMap[partnerId]) {
          conversationsMap[partnerId] = {
            partnerId,
            latestMessage: msg.content,
            time: msg.createdAt,
            unreadCount: 0,
            partnerName: null,
            partnerAvatar: null,
            partnerRole: null,
          };
        }
        if (msg.receiverId === userId && !msg.isRead) {
          conversationsMap[partnerId].unreadCount++;
        }
      }

      // Second pass: fill in partner identity from any message they sent TO us
      for (const msg of messages) {
        if (msg.senderId === userId) continue; // skip our own messages
        const partnerId = msg.senderId;
        if (conversationsMap[partnerId]) {
          if (!conversationsMap[partnerId].partnerName && msg.senderName) {
            conversationsMap[partnerId].partnerName = msg.senderName;
          }
          if (!conversationsMap[partnerId].partnerAvatar && msg.senderAvatarUrl) {
            conversationsMap[partnerId].partnerAvatar = msg.senderAvatarUrl;
          }
          if (!conversationsMap[partnerId].partnerRole && msg.senderRole) {
            conversationsMap[partnerId].partnerRole = msg.senderRole;
          }
        }
      }

      // Final pass: ensure no conversation has a null partnerName (fallback)
      for (const conv of Object.values(conversationsMap) as any[]) {
        if (!conv.partnerName) conv.partnerName = "User";
      }

      res.status(200).json(Object.values(conversationsMap));
    } catch (error: any) {
      res.status(500).json({ error: error.message });
    }
  }

  static async getChatHistory(req: Request, res: Response) {
    try {
      const { userId, partnerId } = req.params;
      const limit = parseInt(req.query.limit as string) || 50;
      const offset = parseInt(req.query.offset as string) || 0;
      
      const messageRepository = AppDataSource.getRepository(Message);
      
      const [messages, total] = await messageRepository.findAndCount({
        where: [
          { senderId: userId, receiverId: partnerId },
          { senderId: partnerId, receiverId: userId }
        ],
        order: { createdAt: "DESC" },
        take: limit,
        skip: offset
      });

      res.status(200).json({
        messages: messages.reverse(),
        total,
        limit,
        offset
      });
    } catch (error: any) {
      res.status(500).json({ error: error.message });
    }
  }

  static async markAsRead(req: Request, res: Response) {
    try {
      const { userId, partnerId } = req.params;
      const messageRepository = AppDataSource.getRepository(Message);
      
      await messageRepository.update(
        { receiverId: userId, senderId: partnerId, isRead: false },
        { isRead: true, readAt: new Date() }
      );

      res.status(200).json({ success: true });
    } catch (error: any) {
      res.status(500).json({ error: error.message });
    }
  }
}
