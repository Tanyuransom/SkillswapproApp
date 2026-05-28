import { Request, Response } from "express";
import { AppDataSource } from "../data-source";
import { Course } from "../entities/Course";
import { CourseReview } from "../entities/CourseReview";
import { ILike, Like } from "typeorm";
import axios from "axios";

export class CourseController {
  static async getAll(req: Request, res: Response) {
    try {
      const { categoryId, query, level, specialty } = req.query;
      console.log(`Searching courses with query: "${query}", categoryId: "${categoryId}", level: "${level}", specialty: "${specialty}"`);
      const courseRepository = AppDataSource.getRepository(Course);
      
      const levelFilter = level ? parseInt(level as string) : undefined;
      
      const where: any = query ? [
        { title: ILike(`%${query}%`), ...(categoryId ? { categoryId } : {}), ...(levelFilter ? { level: levelFilter } : {}), ...(specialty ? { specialty: ILike(`%${specialty as string}%`) } : {}) },
        { description: ILike(`%${query}%`), ...(categoryId ? { categoryId } : {}), ...(levelFilter ? { level: levelFilter } : {}), ...(specialty ? { specialty: ILike(`%${specialty as string}%`) } : {}) }
      ] : { 
        ...(categoryId ? { categoryId } : {}), 
        ...(levelFilter ? { level: levelFilter } : {}),
        ...(specialty ? { specialty: ILike(`%${specialty as string}%`) } : {})
      };
      
      // If there is a query, rank by popularity and rating
      const order: any = query ? {
        averageRating: "DESC",
        reviewCount: "DESC",
        viewsCount: "DESC"
      } : { createdAt: "DESC" };

      const courses = await courseRepository.find({ where, order });
      console.log(`Found ${courses.length} courses`);
      res.json(courses);
    } catch (error) {
      res.status(500).json({ error: "Failed to fetch courses" });
    }
  }

  static async getById(req: Request, res: Response) {
    try {
      const id = req.params.id;
      const courseRepository = AppDataSource.getRepository(Course);
      const course = await courseRepository.findOneBy({ id: id as any });
      if (!course) {
        return res.status(404).json({ error: "Course not found" });
      }
      res.json(course);
    } catch (error) {
      res.status(500).json({ error: "Failed to fetch course" });
    }
  }

  // Internal Endpoint: Fetch for other services (e.g., Enrollment Service)
  static async getByIdInternal(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const courseRepository = AppDataSource.getRepository(Course);
      const course = await courseRepository.findOneBy({ id: id as any });
      if (!course) {
        return res.status(404).json({ error: "Course not found" });
      }
      res.json(course);
    } catch (error) {
      res.status(500).json({ error: "Internal course fetch failed" });
    }
  }

  static async getTutorCourses(req: Request, res: Response) {
    try {
      const { tutorId } = req.params;
      const courseRepository = AppDataSource.getRepository(Course);
      const courses = await courseRepository.find({
        where: { instructorId: tutorId },
        order: { createdAt: "DESC" }
      });
      res.json(courses);
    } catch (error) {
      res.status(500).json({ error: "Failed to fetch tutor courses" });
    }
  }

  static async create(req: Request, res: Response) {
    try {
      const { 
        title, 
        description, 
        price, 
        instructorId, 
        imageUrl, 
        categoryId,
        level,
        instructorName,
        instructorAvatarUrl,
        specialty,
        semester 
      } = req.body;
      
      const courseRepository = AppDataSource.getRepository(Course);
      const course = courseRepository.create({
        title,
        description,
        price,
        instructorId,
        imageUrl,
        categoryId,
        level: level || 1,
        specialty,
        instructorName,
        instructorAvatarUrl,
        semester,
      });
      await courseRepository.save(course);

      // Asynchronously notify followers
      try {
        axios.get(`http://user-service:3003/followers/${instructorId}`)
          .then(async (response) => {
            const followers = response.data; // array of user IDs
            if (Array.isArray(followers)) {
              for (const followerId of followers) {
                await axios.post(`http://notification-service:3007/`, {
                  userId: followerId,
                  title: "New Course uploaded!",
                  message: `${instructorName || 'Tutor'} uploaded a new course: ${title}`,
                  type: "new_course"
                }).catch((err) => {
                  console.error(`[CourseService] Failed to notify follower ${followerId}:`, err.message);
                });
              }
            }
          })
          .catch((err) => {
            console.error(`[CourseService] Failed to fetch followers:`, err.message);
          });
      } catch (notifyErr: any) {
        console.error(`[CourseService] Notification dispatch error:`, notifyErr.message);
      }

      res.status(201).json(course);
    } catch (error) {
      res.status(500).json({ error: "Failed to create course" });
    }
  }

  static async getTrending(req: Request, res: Response) {
    try {
      const { level, specialty } = req.query;
      const courseRepository = AppDataSource.getRepository(Course);
      const levelFilter = level ? parseInt(level as string) : undefined;

      const trending = await courseRepository.find({
        where: {
          ...(levelFilter ? { level: levelFilter } : {}),
          ...(specialty ? { specialty: Like(`%${specialty as string}%`) } : {})
        },
        order: { viewsCount: "DESC" },
        take: 10
      });
      res.json(trending);
    } catch (error) {
      res.status(500).json({ error: "Failed to fetch trending courses" });
    }
  }

  static async incrementViews(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const courseRepository = AppDataSource.getRepository(Course);
      const course = await courseRepository.findOneBy({ id: id as any });
      
      if (!course) {
        return res.status(404).json({ error: "Course not found" });
      }

      course.viewsCount = (course.viewsCount || 0) + 1;
      await courseRepository.save(course);
      
      res.json({ success: true, viewsCount: course.viewsCount });
    } catch (error) {
      res.status(500).json({ error: "Failed to increment views" });
    }
  }

  static async addMaterial(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const { title, url, type } = req.body;
      const courseRepository = AppDataSource.getRepository(Course);
      
      const course = await courseRepository.findOneBy({ id: id as any });
      if (!course) {
        return res.status(404).json({ error: "Course not found" });
      }

      const newMaterial = { title, url, type, addedAt: new Date().toISOString() };
      
      if (!course.materials) {
        course.materials = [];
      }
      
      course.materials.push(newMaterial);
      await courseRepository.save(course);

      res.status(200).json({ success: true, course });
    } catch (error) {
      res.status(500).json({ error: "Failed to add course material", details: error });
    }
  }
  static async delete(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const courseRepository = AppDataSource.getRepository(Course);
      const course = await courseRepository.findOneBy({ id: id as any });
      
      if (!course) {
        return res.status(404).json({ error: "Course not found" });
      }

      await courseRepository.remove(course);
      res.json({ success: true, message: "Course deleted successfully" });
    } catch (error) {
      res.status(500).json({ error: "Failed to delete course" });
    }
  }

  static async addReview(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const { userId, userName, rating, comment } = req.body;
      
      const courseRepository = AppDataSource.getRepository(Course);
      const reviewRepository = AppDataSource.getRepository(CourseReview);
      
      const course = await courseRepository.findOneBy({ id: id as any });
      if (!course) {
        return res.status(404).json({ error: "Course not found" });
      }

      const review = reviewRepository.create({
        courseId: course.id,
        userId,
        userName,
        rating,
        comment
      });
      await reviewRepository.save(review);

      // Recalculate average rating
      const allReviews = await reviewRepository.find({ where: { courseId: course.id } });
      const totalRating = allReviews.reduce((sum, r) => sum + r.rating, 0);
      course.averageRating = totalRating / allReviews.length;
      course.reviewCount = allReviews.length;
      
      await courseRepository.save(course);

      res.status(201).json(review);
    } catch (error) {
      res.status(500).json({ error: "Failed to add review" });
    }
  }

  static async getReviews(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const reviewRepository = AppDataSource.getRepository(CourseReview);
      
      const reviews = await reviewRepository.find({
        where: { courseId: id },
        order: { createdAt: "DESC" }
      });
      
      res.json(reviews);
    } catch (error) {
      res.status(500).json({ error: "Failed to fetch reviews" });
    }
  }

  static async deleteAll(req: Request, res: Response) {
    try {
      const courseRepository = AppDataSource.getRepository(Course);
      await courseRepository.delete({});
      res.json({ success: true, message: "All courses deleted" });
    } catch (error) {
      res.status(500).json({ error: "Failed to delete all courses" });
    }
  }

  static async update(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const { title, description, price, categoryId, level, specialty, semester } = req.body;
      const courseRepository = AppDataSource.getRepository(Course);
      const course = await courseRepository.findOneBy({ id: id as any });
      if (!course) {
        return res.status(404).json({ error: "Course not found" });
      }

      if (title !== undefined) course.title = title;
      if (description !== undefined) course.description = description;
      if (price !== undefined) course.price = parseFloat(price);
      if (categoryId !== undefined) course.categoryId = categoryId;
      if (level !== undefined) course.level = parseInt(level);
      if (specialty !== undefined) course.specialty = specialty;
      if (semester !== undefined) course.semester = semester;

      await courseRepository.save(course);
      res.json(course);
    } catch (error) {
      res.status(500).json({ error: "Failed to update course" });
    }
  }
}
