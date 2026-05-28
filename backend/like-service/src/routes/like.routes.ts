import { Router } from "express";
import { LikeController } from "../controllers/like.controller";

const router = Router();

router.post("/toggle", LikeController.toggleLike);
router.get("/count", LikeController.getLikesCount);
router.get("/check", LikeController.checkLike);

export default router;
