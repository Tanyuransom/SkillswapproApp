import * as dotenv from "dotenv";
dotenv.config();

import express from "express";
import cors from "cors";
import helmet from "helmet";
import path from "path";
import { initializeDatabase } from "./data-source";
import messagingRoutes from "./routes/messaging.routes";

const app = express();
const PORT = process.env.PORT || 3006;

app.use(helmet({
  crossOriginResourcePolicy: false,
}));
app.use(cors());
app.use(express.json());
app.use("/uploads", express.static(path.join(__dirname, "../uploads")));

// Health-check endpoint
app.get("/health", (req: express.Request, res: express.Response) => {
  res.status(200).json({ status: "UP (Messaging)", timestamp: new Date() });
});

app.use("/", messagingRoutes);

const startServer = async () => {
    await initializeDatabase();
    app.listen(PORT, () => {
        console.log(`Messaging Service is running on port ${PORT}`);
    });
};

startServer().catch(console.error);
