import { Router } from "express";
import { EnrollmentController } from "../controllers/enrollment.controller";

const router = Router();

router.post("/", EnrollmentController.enrollCourse);
router.get("/tutor/:tutorId/students", EnrollmentController.getEnrolledStudents);
router.get("/student/:studentId", EnrollmentController.getStudentEnrollments);

export default router;
