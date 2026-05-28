import { Router } from "express";
import { NotificationController } from "../controllers/notification.controller";

const router = Router();

router.get("/:userId", NotificationController.getNotifications);
router.put("/:id/read", NotificationController.markAsRead);
router.post("/", NotificationController.createNotification);

export default router;
