import "reflect-metadata";
import * as dotenv from "dotenv";
dotenv.config();

import express from "express";
import cors from "cors";
import helmet from "helmet";
import fs from "fs";
import path from "path";
import { initializeDatabase } from "./data-source";
import courseRoutes from "./routes/course.routes";

const app = express();
const PORT = process.env.PORT || 3002;

// Ensure uploads directory exists
const uploadDir = path.join(__dirname, "../uploads");
if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir, { recursive: true });
}

app.use(helmet({
  crossOriginResourcePolicy: false,
}));
app.use(cors());
app.use(express.json());
app.use((req, res, next) => {
  console.log(`[CourseService] ${req.method} ${req.url}`);
  next();
});
app.use("/uploads", express.static(uploadDir));

// Health-check endpoint
app.get("/health", (req: express.Request, res: express.Response) => {
  res.status(200).json({ status: "UP", timestamp: new Date() });
});

app.use("/", courseRoutes);

const startServer = async () => {
    await initializeDatabase();
    app.listen(PORT, () => {
        console.log(`Course Service is running on port ${PORT}`);
    });
};

startServer().catch(console.error);
