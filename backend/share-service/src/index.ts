import express from "express";
import cors from "cors";
import morgan from "morgan";
import { initializeDatabase } from "./data-source";
import shareRoutes from "./routes/share.routes";

const app = express();
const PORT = process.env.PORT || 3016;

app.use(cors());
app.use(express.json());
app.use(morgan("dev"));

app.use("/", shareRoutes);

app.get("/health", (req, res) => {
  res.json({ status: "OK", service: "Share Service" });
});

initializeDatabase().then(() => {
  app.listen(PORT, () => {
    console.log(`Share Service running on port ${PORT}`);
  });
});
