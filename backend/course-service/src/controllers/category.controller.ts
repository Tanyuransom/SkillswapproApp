import { Request, Response } from "express";
import { AppDataSource } from "../data-source";
import { Category } from "../entities/Category";

export class CategoryController {
  static async getAll(req: Request, res: Response) {
    try {
      const categoryRepository = AppDataSource.getRepository(Category);
      const categories = await categoryRepository.find({
        order: { name: "ASC" }
      });
      res.json(categories);
    } catch (error) {
      res.status(500).json({ error: "Failed to fetch categories" });
    }
  }

  static async create(req: Request, res: Response) {
    try {
      const { name, description } = req.body;
      const categoryRepository = AppDataSource.getRepository(Category);
      
      // Check if exists
      const existing = await categoryRepository.findOneBy({ name });
      if (existing) {
        return res.status(200).json(existing); // Return existing instead of error to simplify frontend
      }

      const category = categoryRepository.create({
        name,
        description,
      });
      await categoryRepository.save(category);
      res.status(201).json(category);
    } catch (error) {
      res.status(500).json({ error: "Failed to create category" });
    }
  }
}
