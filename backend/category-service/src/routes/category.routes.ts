import { Router } from "express";
import { CategoryController } from "../controllers/category.controller";

const router = Router();

router.get("/", CategoryController.getAll);
router.post("/", CategoryController.create);
router.delete("/all", CategoryController.deleteAll);

export default router;
