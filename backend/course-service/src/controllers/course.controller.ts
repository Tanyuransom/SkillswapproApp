import { Request, Response } from "express";
import { AppDataSource } from "../data-source";
import { Course } from "../entities/Course";
import { Enrollment } from "../entities/Enrollment";
import { Notification } from "../entities/Notification";
import { Message } from "../entities/Message";
import { ILike } from "typeorm";
import axios from "axios";

const AUTH_SERVICE_URL = process.env.AUTH_SERVICE_URL || "http://auth-service:3001";

export class CourseController {
  static async getAll(req: Request, res: Response) {
    try {
      const { categoryId, query } = req.query;
      const courseRepository = AppDataSource.getRepository(Course);
      
      const where: any = {};
      if (categoryId) {
        where.categoryId = categoryId;
      }
      if (query) {
        where.title = ILike(`%${query}%`);
      }
      
      const courses = await courseRepository.find({ where });
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
      const { title, description, price, instructorId, imageUrl, categoryId } = req.body;
      const courseRepository = AppDataSource.getRepository(Course);
      const course = courseRepository.create({
        title,
        description,
        price,
        instructorId,
        imageUrl,
        categoryId,
      });
      await courseRepository.save(course);
      res.status(201).json(course);
    } catch (error) {
      res.status(500).json({ error: "Failed to create course" });
    }
  }

  static async getStats(req: Request, res: Response) {
    try {
      const { tutorId } = req.query;
      const enrollmentRepository = AppDataSource.getRepository(Enrollment);
      
      let query = enrollmentRepository.createQueryBuilder("enrollment").select("DISTINCT(enrollment.studentId)");
      
      if (tutorId) {
        query = query.where("enrollment.instructorId = :tutorId", { tutorId });
      }
      
      const studentCount = await query.getCount();
      res.json({ activeStudents: studentCount });
    } catch (error) {
      res.status(500).json({ error: "Failed to fetch stats" });
    }
  }

  static async getTutorStudents(req: Request, res: Response) {
    try {
      const { tutorId } = req.params;
      const enrollmentRepository = AppDataSource.getRepository(Enrollment);
      const enrollments = await enrollmentRepository.find({
        where: { instructorId: tutorId },
        order: { createdAt: "DESC" }
      });

      if (enrollments.length === 0) {
        return res.json([]);
      }

      // Fetch student names from auth-service
      const studentIds = Array.from(new Set(enrollments.map(e => e.studentId)));
      try {
        const response = await axios.post(`${AUTH_SERVICE_URL}/auth/batch`, { ids: studentIds });
        const userMap = new Map<string, any>(response.data.map((u: any) => [u.id, { name: u.fullName, avatar: u.avatarUrl }]));
        
        const enrichedEnrollments = enrollments.map(e => {
          const u = userMap.get(e.studentId);
          return {
            ...e,
            studentName: u?.name || "Unknown Student",
            studentAvatar: u?.avatar
          };
        });
        
        return res.json(enrichedEnrollments);
      } catch (err) {
        console.error("Failed to fetch student names:", err);
        return res.json(enrollments);
      }
    } catch (error) {
      res.status(500).json({ error: "Failed to fetch enrolled students" });
    }
  }

  static async enroll(req: Request, res: Response) {
    try {
      const { courseId, studentId } = req.body;
      const courseRepository = AppDataSource.getRepository(Course);
      const enrollmentRepository = AppDataSource.getRepository(Enrollment);
      const notificationRepository = AppDataSource.getRepository(Notification);

      const course = await courseRepository.findOneBy({ id: courseId as any });
      if (!course) {
        return res.status(404).json({ error: "Course not found" });
      }

      const existing = await enrollmentRepository.findOneBy({ courseId, studentId } as any);
      if (existing) {
        return res.status(400).json({ error: "Already enrolled" });
      }

      const enrollment = enrollmentRepository.create({
        courseId,
        studentId,
        instructorId: course.instructorId,
      });

      await enrollmentRepository.save(enrollment);

      // Create notification for tutor
      const notification = notificationRepository.create({
        userId: course.instructorId,
        title: "New Student Enrolled!",
        message: `A new student has joined your course: ${course.title}`,
        type: "enrollment",
      });
      await notificationRepository.save(notification);

      res.status(201).json(enrollment);
    } catch (error) {
      res.status(500).json({ error: "Enrollment failed" });
    }
  }

  // Notification Methods
  static async getNotifications(req: Request, res: Response) {
    try {
      const { userId } = req.params;
      const notificationRepository = AppDataSource.getRepository(Notification);
      const notifications = await notificationRepository.find({
        where: { userId },
        order: { createdAt: "DESC" }
      });
      res.json(notifications);
    } catch (error) {
      res.status(500).json({ error: "Failed to fetch notifications" });
    }
  }

  static async markNotificationAsRead(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const notificationRepository = AppDataSource.getRepository(Notification);
      await notificationRepository.update(id, { isRead: true });
      res.json({ success: true });
    } catch (error) {
      res.status(500).json({ error: "Failed to update notification" });
    }
  }

  static async markAllNotificationsAsRead(req: Request, res: Response) {
    try {
      const { userId } = req.params;
      const notificationRepository = AppDataSource.getRepository(Notification);
      await notificationRepository.update({ userId }, { isRead: true });
      res.json({ success: true });
    } catch (error) {
      res.status(500).json({ error: "Failed to update notifications" });
    }
  }

  // Messaging Methods
  static async getMessages(req: Request, res: Response) {
    try {
      const { userId } = req.params;
      const messageRepository = AppDataSource.getRepository(Message);
      const messages = await messageRepository.find({
        where: [
          { senderId: userId },
          { receiverId: userId }
        ],
        order: { createdAt: "ASC" }
      });
      res.json(messages);
    } catch (error) {
      res.status(500).json({ error: "Failed to fetch messages" });
    }
  }

  static async sendMessage(req: Request, res: Response) {
    try {
      const { senderId, receiverId, content, senderName } = req.body;
      const messageRepository = AppDataSource.getRepository(Message);
      const notificationRepository = AppDataSource.getRepository(Notification);

      const message = messageRepository.create({ senderId, receiverId, content });
      await messageRepository.save(message);

      // Create notification for receiver
      const notification = notificationRepository.create({
        userId: receiverId,
        title: "New Message",
        message: `${senderName || 'Someone'} sent you a message: ${content.substring(0, 30)}...`,
        type: "message",
      });
      await notificationRepository.save(notification);

      res.status(201).json(message);
    } catch (error) {
      res.status(500).json({ error: "Failed to send message" });
    }
  }

  static async markMessageAsRead(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const messageRepository = AppDataSource.getRepository(Message);
      await messageRepository.update(id, { isRead: true });
      res.json({ success: true });
    } catch (error) {
      res.status(500).json({ error: "Failed to update message" });
    }
  }
}

