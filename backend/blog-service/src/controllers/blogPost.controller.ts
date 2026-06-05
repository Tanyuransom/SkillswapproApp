import { Request, Response } from "express";
import { AppDataSource } from "../data-source";
import { BlogPost } from "../entities/BlogPost";

export class BlogPostController {
  static async getAll(req: Request, res: Response) {
    try {
      const blogRepo = AppDataSource.getRepository(BlogPost);
      const posts = await blogRepo.find({
        order: { createdAt: "DESC" }
      });
      res.status(200).json(posts);
    } catch (error) {
      console.error("[BlogController] Error in getAll:", error);
      res.status(500).json({ error: "Failed to fetch blog posts" });
    }
  }

  static async getById(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const blogRepo = AppDataSource.getRepository(BlogPost);
      const post = await blogRepo.findOneBy({ id });
      
      if (!post) {
        return res.status(404).json({ error: "Blog post not found" });
      }
      
      res.status(200).json(post);
    } catch (error) {
      console.error("[BlogController] Error in getById:", error);
      res.status(500).json({ error: "Failed to fetch blog post" });
    }
  }

  static async create(req: Request, res: Response) {
    try {
      const { title, content, authorId, authorName, authorAvatarUrl, imageUrl, category, readTime } = req.body;
      
      if (!title || !content || !authorId) {
        return res.status(400).json({ error: "Title, content, and authorId are required fields" });
      }

      // Calculate read time if not provided
      let calculatedReadTime = readTime;
      if (!calculatedReadTime) {
        const wordCount = content.trim().split(/\s+/).length;
        const minutes = Math.max(1, Math.ceil(wordCount / 200));
        calculatedReadTime = `${minutes} min read`;
      }

      const blogRepo = AppDataSource.getRepository(BlogPost);
      const newPost = blogRepo.create({
        title,
        content,
        authorId,
        authorName: authorName || "Anonymous",
        authorAvatarUrl,
        imageUrl,
        category: category || "General",
        readTime: calculatedReadTime
      });

      await blogRepo.save(newPost);
      res.status(201).json(newPost);
    } catch (error) {
      console.error("[BlogController] Error in create:", error);
      res.status(500).json({ error: "Failed to create blog post" });
    }
  }

  static async delete(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const blogRepo = AppDataSource.getRepository(BlogPost);
      const post = await blogRepo.findOneBy({ id });
      
      if (!post) {
        return res.status(404).json({ error: "Blog post not found" });
      }

      await blogRepo.remove(post);
      res.status(200).json({ success: true, message: "Blog post deleted successfully" });
    } catch (error) {
      console.error("[BlogController] Error in delete:", error);
      res.status(500).json({ error: "Failed to delete blog post" });
    }
  }
}
