import { Request, Response } from "express";
import { AppDataSource } from "../data-source";
import { Short } from "../entities/Short";
import { Like } from "typeorm";
import fs from "fs";
import path from "path";
import axios from "axios";

export class ShortController {
  static async getAll(req: Request, res: Response) {
    try {
      const { userId, level, specialty, categoryId } = req.query;
      const shortRepository = AppDataSource.getRepository(Short);
      
      const levelFilter = level ? parseInt(level as string) : undefined;

      let shorts = await shortRepository.find({
        where: {
          ...(levelFilter ? { level: levelFilter } : {}),
          ...(specialty ? { specialty: Like(`%${specialty as string}%`) } : {}),
          ...(categoryId ? { categoryId: categoryId as string } : {})
        },
        order: { createdAt: "DESC" },
        take: 50
      });

      // Enrich with likes and comments from other services
      const enrichedShorts = await Promise.all(shorts.map(async (short) => {
        try {
          // Fetch likes count
          const likesRes = await axios.get(`http://skillprof-like-service:3014/count?targetId=${short.id}&targetType=short`).catch((err) => {
            console.error(`Like fetch failed for ${short.id}:`, err.message);
            return { data: { count: 0 } };
          });
          // Fetch comments count
          const commentsRes = await axios.get(`http://skillprof-comment-service:3015/?targetId=${short.id}&targetType=short`).catch((err) => {
            console.error(`Comment fetch failed for ${short.id}:`, err.message);
            return { data: [] };
          });
          
          let isLiked = false;
          if (userId) {
            try {
              const checkLike = await axios.get(`http://skillprof-like-service:3014/check?userId=${userId}&targetId=${short.id}&targetType=short`);
              isLiked = checkLike.data.isLiked;
            } catch (e) { /* ignore */ }
          }

          return {
            ...short,
            likes: likesRes.data?.count || 0,
            comments: Array.isArray(commentsRes.data) ? commentsRes.data.length : 0,
            isLiked
          };
        } catch (e) {
          return { ...short, likes: 0, comments: 0, isLiked: false };
        }
      }));

      res.json(enrichedShorts);
    } catch (error) {
      res.status(500).json({ error: "Failed to fetch shorts" });
    }
  }

  static async create(req: Request, res: Response) {
    try {
      const { tutorId, tutorName, courseName, description, videoUrl, tutorAvatarUrl, level, specialty, categoryId } = req.body;
      const shortRepository = AppDataSource.getRepository(Short);
      const short = shortRepository.create({
        tutorId,
        tutorName,
        courseName,
        description,
        videoUrl,
        tutorAvatarUrl,
        level: level || 1,
        specialty,
        categoryId,
      });
      await shortRepository.save(short);

      // Asynchronously notify followers
      try {
        axios.get(`http://user-service:3003/followers/${tutorId}`)
          .then(async (response) => {
            const followers = response.data; // array of user IDs
            if (Array.isArray(followers)) {
              for (const followerId of followers) {
                await axios.post(`http://notification-service:3007/`, {
                  userId: followerId,
                  title: "New Short uploaded!",
                  message: `${tutorName || 'Tutor'} uploaded a new short: ${courseName}`,
                  type: "new_short"
                }).catch((err) => {
                  console.error(`[ShortsService] Failed to notify follower ${followerId}:`, err.message);
                });
              }
            }
          })
          .catch((err) => {
            console.error(`[ShortsService] Failed to fetch followers:`, err.message);
          });
      } catch (notifyErr: any) {
        console.error(`[ShortsService] Notification dispatch error:`, notifyErr.message);
      }

      res.status(201).json(short);
    } catch (error) {
      console.error("[ShortsService] Create Error:", error);
      res.status(500).json({ error: "Failed to create short" });
    }
  }

  static async delete(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const shortRepository = AppDataSource.getRepository(Short);
      const short = await shortRepository.findOneBy({ id: id as any });

      if (!short) {
        return res.status(404).json({ error: "Short not found" });
      }

      // Try to delete the physical file if it exists in local uploads
      if (short.videoUrl && short.videoUrl.startsWith("/uploads/shorts/")) {
        try {
          const filename = short.videoUrl.replace("/uploads/shorts/", "");
          const filePath = path.join(__dirname, "../../uploads/shorts", filename);
          if (fs.existsSync(filePath)) {
            fs.unlinkSync(filePath);
          }
        } catch (fileError) {
          console.error("Error deleting video file:", fileError);
        }
      }

      await shortRepository.remove(short);
      res.json({ success: true, message: "Short deleted successfully" });
    } catch (error) {
      console.error("[ShortsService] Delete Error:", error);
      res.status(500).json({ error: "Failed to delete short" });
    }
  }

  static async deleteAll(req: Request, res: Response) {
    try {
      const shortRepository = AppDataSource.getRepository(Short);
      await shortRepository.delete({});
      res.json({ success: true, message: "All shorts deleted" });
    } catch (error) {
      res.status(500).json({ error: "Failed to delete all shorts" });
    }
  }

  static async updateTutorInfo(req: Request, res: Response) {
    try {
      const { tutorId } = req.params;
      const { fullName, avatarUrl } = req.body;
      const shortRepository = AppDataSource.getRepository(Short);

      const updateData: any = {};
      if (fullName !== undefined) updateData.tutorName = fullName;
      if (avatarUrl !== undefined) updateData.tutorAvatarUrl = avatarUrl;

      if (Object.keys(updateData).length === 0) {
        return res.status(400).json({ error: "No fields to update" });
      }

      await shortRepository.update({ tutorId }, updateData);
      res.json({ success: true, message: "Tutor info updated across all shorts" });
    } catch (error: any) {
      res.status(500).json({ error: error.message || "Failed to update tutor info" });
    }
  }
}
