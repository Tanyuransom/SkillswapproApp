import { Request, Response } from "express";
import { AppDataSource } from "../data-source";
import { Enrollment } from "../entities/Enrollment";
import axios from "axios";

export class EnrollmentController {
  static async enrollCourse(req: Request, res: Response) {
    try {
      const { studentId, courseId, instructorId, studentName, courseTitle, instructorName, instructorAvatar } = req.body;
      const enrollmentRepository = AppDataSource.getRepository(Enrollment);
      
      const existing = await enrollmentRepository.findOneBy({ studentId, courseId });
      if (existing) {
        return res.status(400).json({ error: "Student already enrolled in this course" });
      }

      const enrollment = enrollmentRepository.create({
        studentId,
        courseId,
        instructorId: instructorId || "unknown",
      });

      await enrollmentRepository.save(enrollment);

      // Trigger Notification to Tutor
      try {
        await axios.post("http://notification-service:3007/notifications", {
          userId: instructorId,
          title: "New Student Enrollment!",
          message: `${studentName || 'A student'} has just enrolled in your course: ${courseTitle || 'Course'}.`,
          type: "enrollment"
        });
      } catch (notifyError) {
        console.error("Failed to trigger notification:", notifyError);
      }

      // Trigger Welcome Inbox Message to Student
      try {
        await axios.post("http://messaging-service:3006/", {
          senderId: instructorId || "system",
          receiverId: studentId,
          content: `Welcome to the course "${courseTitle || 'Course'}"! I am excited to have you in this course. Feel free to ask any questions here.`,
          senderName: instructorName || "Instructor",
          senderAvatarUrl: instructorAvatar || "",
          senderRole: "TUTOR"
        });
      } catch (welcomeError: any) {
        console.error("Failed to send welcome message:", welcomeError.message);
      }

      res.status(201).json(enrollment);
    } catch (error: any) {
      res.status(500).json({ error: error.message });
    }
  }

  static async getEnrolledStudents(req: Request, res: Response) {
    try {
      const { tutorId } = req.params;
      const enrollmentRepository = AppDataSource.getRepository(Enrollment);
      
      const enrollments = await enrollmentRepository.find({
        where: { instructorId: tutorId },
        order: { createdAt: "DESC" }
      });

      res.status(200).json(enrollments);
    } catch (error: any) {
      res.status(500).json({ error: error.message });
    }
  }

  static async getStudentEnrollments(req: Request, res: Response) {
    try {
      const { studentId } = req.params;
      const enrollmentRepository = AppDataSource.getRepository(Enrollment);
      
      const enrollments = await enrollmentRepository.find({
        where: { studentId },
        order: { createdAt: "DESC" }
      });

      res.status(200).json(enrollments);
    } catch (error: any) {
      res.status(500).json({ error: error.message });
    }
  }
}
