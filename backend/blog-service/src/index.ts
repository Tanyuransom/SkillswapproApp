import * as dotenv from "dotenv";
dotenv.config();

import express from "express";
import cors from "cors";
import helmet from "helmet";
import path from "path";
import { initializeDatabase } from "./data-source";

const app = express();
const PORT = process.env.PORT || 3011;

app.use(helmet({
  crossOriginResourcePolicy: false,
}));
app.use(cors());
app.use(express.json());

// Health-check endpoint
app.get("/health", (req: express.Request, res: express.Response) => {
  res.status(200).json({ status: "UP (Blog)", timestamp: new Date() });
});

// Basic Blog routes placeholder
app.get("/", (req, res) => {
    res.status(200).json([]);
});

const startServer = async () => {
    await initializeDatabase();
    app.listen(PORT, () => {
        console.log(`Blog Service is running on port ${PORT}`);
    });
};

startServer().catch(console.error);
