import { Router } from "express";
import { UserController } from "../controllers/user.controller";
import multer from "multer";
import path from "path";
import fs from "fs";

const router = Router();

// Configure multer for profile picture uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = path.join(__dirname, "../../uploads");
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

const upload = multer({ storage: storage });

router.get("/", UserController.getAllUsers);
router.post("/", UserController.createUser);
router.post("/batch", UserController.getUsersBatch);
router.put("/:id", UserController.updateUser);
router.post("/follow", UserController.followTutor);
router.post("/unfollow", UserController.unfollowTutor);
router.get("/follow/check", UserController.checkFollowStatus);
router.get("/followers/:tutorId", UserController.getFollowers);
router.get("/:id", UserController.getUser);
router.delete("/:id", UserController.deleteUser);
router.post("/app-reviews", UserController.addAppReview);

// Avatar upload endpoint (Moved from Identity to User service)
router.post("/avatar", (req, res, next) => {
  upload.single("avatar")(req, res, (err) => {
    if (err) {
      console.error("[UserService] Avatar Multer Error:", err);
      return res.status(500).json({ error: "File upload failed" });
    }
    next();
  });
}, (req: any, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: "No file uploaded" });
    }
    const fileUrl = `/uploads/${req.file.filename}`;
    res.status(200).json({ url: fileUrl });
  } catch (err) {
    console.error("[UserService] Avatar Success Handler Error:", err);
    res.status(500).json({ error: "Avatar processing failed" });
  }
});

export default router;
