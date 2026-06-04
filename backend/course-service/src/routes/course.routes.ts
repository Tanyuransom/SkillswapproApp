import { Router } from "express";
import { CourseController } from "../controllers/course.controller";
import multer from "multer";
import path from "path";
import fs from "fs";

const router = Router();

// Multer Config
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = path.join(__dirname, "../../uploads/courses");
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
    cb(null, file.fieldname + "-" + uniqueSuffix + path.extname(file.originalname));
  },
});

const upload = multer({ 
  storage,
  limits: { fileSize: 500 * 1024 * 1024 } // 500MB
});

router.get("/", CourseController.getAll);
router.get("/trending", CourseController.getTrending);
router.get("/tutor/:tutorId/courses", CourseController.getTutorCourses);
router.get("/:id", CourseController.getById);

router.post("/upload", upload.single("file"), (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: "No file uploaded" });
  }
  const fileUrl = `/uploads/courses/${req.file.filename}`;
  res.status(200).json({ url: fileUrl });
});

router.post("/", CourseController.create);
router.put("/:id", CourseController.update);
router.put("/instructor/:instructorId", CourseController.updateInstructorInfo);
router.post("/:id/materials", CourseController.addMaterial);
router.delete("/:id/materials/:materialIndex", CourseController.deleteMaterial);
router.patch("/:id/view", CourseController.incrementViews);
router.delete("/all-courses", CourseController.deleteAll);
router.delete("/:id", CourseController.delete);
router.post("/:id/reviews", CourseController.addReview);
router.get("/:id/reviews", CourseController.getReviews);

export default router;
