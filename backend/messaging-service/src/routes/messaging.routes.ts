import { Router } from "express";
import { MessagingController } from "../controllers/messaging.controller";

const router = Router();

router.post("/", MessagingController.sendMessage);
router.get("/conversations/:userId", MessagingController.getConversations);
router.get("/history/:userId/:partnerId", MessagingController.getChatHistory);
router.patch("/read/:userId/:partnerId", MessagingController.markAsRead);
router.get("/:userId", MessagingController.getMessages);

export default router;
