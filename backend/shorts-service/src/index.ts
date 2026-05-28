import "reflect-metadata";
import * as dotenv from "dotenv";
dotenv.config();

import express from "express";
import cors from "cors";
import helmet from "helmet";
import fs from "fs";
import path from "path";
import { initializeDatabase } from "./data-source";
import shortRoutes from "./routes/short.routes";

const app = express();
const PORT = process.env.PORT || 3005;

// Ensure uploads and shorts directory exists
const uploadDir = path.join(__dirname, "../uploads");
const shortsDir = path.join(uploadDir, "shorts");
[uploadDir, shortsDir].forEach(dir => {
    if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
    }
});

app.use(helmet({
  crossOriginResourcePolicy: false,
}));
app.use(cors());
app.use(express.json());

// Serving static files with support for Range requests (essential for video)
app.use("/uploads", express.static(uploadDir, {
    setHeaders: (res) => {
        res.set("Access-Control-Allow-Origin", "*");
        res.set("Accept-Ranges", "bytes");
    }
}));

// Health-check endpoint
app.get("/health", (req: express.Request, res: express.Response) => {
  res.status(200).json({ status: "UP", timestamp: new Date() });
});

app.use("/", shortRoutes);

const startServer = async () => {
    await initializeDatabase();
    app.listen(PORT, () => {
        console.log(`Shorts Service is running on port ${PORT}`);
    });
};

startServer().catch(console.error);
