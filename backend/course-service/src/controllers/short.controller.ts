import { Request, Response } from "express";
import { AppDataSource } from "../data-source";
import { Short } from "../entities/Short";

export class ShortController {
  static async getAll(req: Request, res: Response) {
    try {
      const shortRepository = AppDataSource.getRepository(Short);
      
      // Get all real shorts ordered by newest
      let shorts = await shortRepository.find({
        order: { createdAt: "DESC" },
        take: 50
      });

      // If we have very few real shorts, add some curated placeholders to keep the feed alive
      if (shorts.length < 5) {
        const placeholders = [
          {
            id: 'p1',
            tutorName: 'SkillProf Admin',
            courseName: 'Welcome Guide',
            description: 'Learn how to master new skills with SkillSwap Pro! 🚀',
            videoUrl: 'https://assets.mixkit.co/videos/preview/mixkit-software-developer-working-on-code-screen-close-up-34449-large.mp4',
            tutorAvatarUrl: 'https://images.unsplash.com/photo-1544717305-27a734ef1904',
            likes: 1240,
            comments: 89,
            createdAt: new Date()
          },
          {
            id: 'p2',
            tutorName: 'James Chen',
            courseName: 'UI Design 101',
            description: 'Quick tip on color theory for modern web apps. #design #tutorial',
            videoUrl: 'https://assets.mixkit.co/videos/preview/mixkit-man-working-on-his-laptop-3480-large.mp4',
            tutorAvatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d',
            likes: 852,
            comments: 42,
            createdAt: new Date()
          },
          {
            id: 'p3',
            tutorName: 'Sarah Smith',
            courseName: 'Public Speaking',
            description: 'How to overcome stage fright in 60 seconds. 🎤',
            videoUrl: 'https://assets.mixkit.co/videos/preview/mixkit-young-woman-talking-on-the-phone-while-working-34532-large.mp4',
            tutorAvatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330',
            likes: 2105,
            comments: 156,
            createdAt: new Date()
          }
        ];
        // Combine real shorts with placeholders (real shorts first)
        shorts = [...shorts, ...(placeholders as any)];
      }

      res.json(shorts);
    } catch (error) {
      res.status(500).json({ error: "Failed to fetch shorts" });
    }
  }

  static async create(req: Request, res: Response) {
    try {
      const { tutorId, tutorName, courseName, description, videoUrl, tutorAvatarUrl } = req.body;
      const shortRepository = AppDataSource.getRepository(Short);
      const short = shortRepository.create({
        tutorId,
        tutorName,
        courseName,
        description,
        videoUrl,
        tutorAvatarUrl,
      });
      await shortRepository.save(short);
      res.status(201).json(short);
    } catch (error) {
      res.status(500).json({ error: "Failed to create short" });
    }
  }
}
