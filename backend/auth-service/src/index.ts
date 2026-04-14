import express from "express";
import cors from "cors";
import helmet from "helmet";
import * as dotenv from "dotenv";
import { initializeDatabase } from "./data-source";
import authRoutes from "./routes/auth.routes";
import path from "path";
import fs from "fs";

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3001;

// Ensure uploads directory exists
const uploadDir = path.join(__dirname, "../uploads");
if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir, { recursive: true });
}

// Middleware for high scalability and security
app.use(helmet({
  crossOriginResourcePolicy: false, // Allow loading images from our own server
}));
app.use(cors());
app.use(express.json());
app.use("/uploads", express.static(uploadDir));

// Health-check endpoint for horizontal scaling
app.get("/health", (req: express.Request, res: express.Response) => {
  res.status(200).json({ status: "UP", timestamp: new Date() });
});

// Authentication routes
app.use("/api/auth", authRoutes);

const startServer = async () => {
    await initializeDatabase();
    app.listen(PORT, () => {
        console.log(`Auth Service is running on port ${PORT}`);
    });
};

startServer().catch(console.error);
