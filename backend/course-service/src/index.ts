import express from "express";
import cors from "cors";
import helmet from "helmet";
import * as dotenv from "dotenv";
import path from "path";
import { initializeDatabase } from "./data-source";
import courseRoutes from "./routes/course.routes";
import categoryRoutes from "./routes/category.routes";
import shortRoutes from "./routes/short.routes";

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3002;

app.use(helmet({
  crossOriginResourcePolicy: false,
}));
app.use(cors());
app.use(express.json());
app.use("/uploads", express.static(path.join(__dirname, "../uploads")));

// Health-check endpoint
app.get("/health", (req: express.Request, res: express.Response) => {
  res.status(200).json({ status: "UP", timestamp: new Date() });
});

app.use("/api/courses", courseRoutes);
app.use("/api/categories", categoryRoutes);
app.use("/api/shorts", shortRoutes);

const startServer = async () => {
    await initializeDatabase();
    app.listen(PORT, () => {
        console.log(`Course Service is running on port ${PORT}`);
    });
};

startServer().catch(console.error);
