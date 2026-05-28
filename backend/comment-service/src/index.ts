import express from "express";
import cors from "cors";
import morgan from "morgan";
import { initializeDatabase } from "./data-source";
import commentRoutes from "./routes/comment.routes";

const app = express();
const PORT = process.env.PORT || 3015;

app.use(cors());
app.use(express.json());
app.use(morgan("dev"));

app.use("/", commentRoutes);

app.get("/health", (req, res) => {
  res.json({ status: "OK", service: "Comment Service" });
});

initializeDatabase().then(() => {
  app.listen(PORT, () => {
    console.log(`Comment Service running on port ${PORT}`);
  });
});
