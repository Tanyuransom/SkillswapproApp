import * as dotenv from "dotenv";
dotenv.config();

import express from "express";
import cors from "cors";
import helmet from "helmet";
import path from "path";
import fs from "fs";
import { initializeDatabase } from "./data-source";
import userRoutes from "./routes/user.routes";

const app = express();
const PORT = process.env.PORT || 3003;

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
app.use("/uploads", express.static(uploadDir));

// Health-check endpoint
app.get("/health", (req: express.Request, res: express.Response) => {
  res.status(200).json({ status: "UP (User)", timestamp: new Date() });
});

app.use("/", userRoutes); 

const startServer = async () => {
    await initializeDatabase();
    app.listen(PORT, () => {
        console.log(`User Service is running on port ${PORT}`);
    });
};

startServer().catch(console.error);
