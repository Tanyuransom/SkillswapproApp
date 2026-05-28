import * as dotenv from "dotenv";
dotenv.config();

import express from "express";
import cors from "cors";
import helmet from "helmet";
import path from "path";
import { initializeDatabase } from "./data-source";

const app = express();
const PORT = process.env.PORT || 3009;

app.use(helmet({
  crossOriginResourcePolicy: false,
}));
app.use(cors());
app.use(express.json());

// Health-check endpoint
app.get("/health", (req: express.Request, res: express.Response) => {
  res.status(200).json({ status: "UP (Payment)", timestamp: new Date() });
});

// Basic Payment routes placeholder
app.post("/", (req, res) => {
    res.status(201).json({ message: "Mock Payment Processed", data: req.body });
});

const startServer = async () => {
    await initializeDatabase();
    app.listen(PORT, () => {
        console.log(`Payment Service is running on port ${PORT}`);
    });
};

startServer().catch(console.error);
