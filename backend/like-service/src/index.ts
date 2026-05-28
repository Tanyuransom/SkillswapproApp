import express from "express";
import cors from "cors";
import morgan from "morgan";
import { initializeDatabase } from "./data-source";
import likeRoutes from "./routes/like.routes";

const app = express();
const PORT = process.env.PORT || 3014;

app.use(cors());
app.use(express.json());
app.use(morgan("dev"));

app.use("/", likeRoutes);

app.get("/health", (req, res) => {
  res.json({ status: "OK", service: "Like Service" });
});

initializeDatabase().then(() => {
  app.listen(PORT, () => {
    console.log(`Like Service running on port ${PORT}`);
  });
});
