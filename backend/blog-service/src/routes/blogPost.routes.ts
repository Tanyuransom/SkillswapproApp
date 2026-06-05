import { Router } from "express";
import { BlogPostController } from "../controllers/blogPost.controller";
import multer from "multer";
import path from "path";
import fs from "fs";

const router = Router();

// Multer Storage Configuration for Blog Cover Images
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = path.join(__dirname, "../../uploads/blogs");
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
  limits: { fileSize: 50 * 1024 * 1024 } // 50MB limits for images
});

// Blog routes mapping
router.get("/", BlogPostController.getAll);
router.get("/:id", BlogPostController.getById);
router.post("/", BlogPostController.create);
router.delete("/:id", BlogPostController.delete);

// Image upload route
router.post("/upload", upload.single("image"), (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: "No image file uploaded" });
  }
  const fileUrl = `/uploads/blogs/${req.file.filename}`;
  res.status(200).json({ url: fileUrl });
});

export default router;
