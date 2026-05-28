import * as dotenv from "dotenv";
dotenv.config();

import express from "express";
import cors from "cors";
import helmet from "helmet";
import { initializeDatabase } from "./data-source";
import authRoutes from "./routes/auth.routes";

const app = express();
const PORT = process.env.PORT || 3001;

app.use(helmet());
app.use(cors());
app.use(express.json());

// Health-check endpoint
app.get("/health", (req: express.Request, res: express.Response) => {
  res.status(200).json({ status: "UP (Identity)", timestamp: new Date() });
});

app.use("/", authRoutes);

const startServer = async () => {
    await initializeDatabase();
    app.listen(PORT, () => {
        console.log(`Identity Service is running on port ${PORT}`);
    });
};

startServer().catch(console.error);
