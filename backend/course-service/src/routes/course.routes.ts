import { Router } from "express";
import { CourseController } from "../controllers/course.controller";

const router = Router();

router.get("/", CourseController.getAll);
router.get("/stats", CourseController.getStats);
router.get("/tutor/:tutorId/students", CourseController.getTutorStudents);
router.get("/tutor/:tutorId/courses", CourseController.getTutorCourses);
router.get("/notifications/:userId", CourseController.getNotifications);
router.get("/messages/:userId", CourseController.getMessages);
router.post("/messages", CourseController.sendMessage);
router.get("/:id", CourseController.getById);
router.post("/", CourseController.create);
router.post("/enroll", CourseController.enroll);
router.put("/notifications/:id/read", CourseController.markNotificationAsRead);
router.put("/notifications/user/:userId/read-all", CourseController.markAllNotificationsAsRead);
router.put("/messages/:id/read", CourseController.markMessageAsRead);

export default router;
