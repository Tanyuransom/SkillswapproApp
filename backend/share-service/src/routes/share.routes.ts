import { Router } from "express";
import { ShareController } from "../controllers/share.controller";

const router = Router();

router.post("/", ShareController.addShare);
router.get("/count", ShareController.getSharesCount);

export default router;
