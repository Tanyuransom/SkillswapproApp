import express from "express";
import cors from "cors";
import helmet from "helmet";
import authRoutes from "./routes/auth.routes";

const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json());

// Health-check endpoint
app.get("/health", (req: express.Request, res: express.Response) => {
  res.status(200).json({ status: "UP (Identity)", timestamp: new Date() });
});

app.use("/", authRoutes);

export default app;
