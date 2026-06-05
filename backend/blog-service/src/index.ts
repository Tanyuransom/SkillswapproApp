import * as dotenv from "dotenv";
dotenv.config();

import express from "express";
import cors from "cors";
import helmet from "helmet";
import path from "path";
import fs from "fs";
import { initializeDatabase } from "./data-source";
import blogPostRoutes from "./routes/blogPost.routes";

const app = express();
const PORT = process.env.PORT || 3011;

// Ensure upload directory exists
const uploadsBlogDir = path.join(__dirname, "../uploads/blogs");
if (!fs.existsSync(uploadsBlogDir)) {
  fs.mkdirSync(uploadsBlogDir, { recursive: true });
}

app.use(helmet({
  crossOriginResourcePolicy: false,
}));
app.use(cors());
app.use(express.json());

app.use("/uploads", express.static(path.join(__dirname, "../uploads")));

// Health-check endpoint
app.get("/health", (req: express.Request, res: express.Response) => {
  res.status(200).json({ status: "UP (Blog)", timestamp: new Date() });
});

// Register Blog routes
app.use("/", blogPostRoutes);

const startServer = async () => {
    await initializeDatabase();
    app.listen(PORT, () => {
        console.log(`Blog Service is running on port ${PORT}`);
    });
};

startServer().catch(console.error);
