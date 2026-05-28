import { Router } from "express";
import { CommentController } from "../controllers/comment.controller";

const router = Router();

router.post("/", CommentController.addComment);
router.get("/", CommentController.getComments);
router.delete("/:id", CommentController.deleteComment);

export default router;
