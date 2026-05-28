import "reflect-metadata";
import express from "express";
import cors from "cors";
import helmet from "helmet";
import { AppDataSource } from "./data-source";
import { Level } from "./entities/Level";
import { UserLevel } from "./entities/UserLevel";

const app = express();
app.use(cors());
app.use(helmet());
app.use(express.json());

const PORT = process.env.PORT || 3017;

// Seed levels if they don't exist
const seedLevels = async () => {
  const levelRepo = AppDataSource.getRepository(Level);
  const count = await levelRepo.count();
  if (count === 0) {
    const levels = [
      { id: 1, name: "Level 1", description: "First Year University" },
      { id: 2, name: "Level 2", description: "Second Year University" },
      { id: 3, name: "Level 3", description: "Third Year University" },
      { id: 4, name: "Level 4", description: "Final Year University" },
    ];
    await levelRepo.save(levels);
    console.log("Levels seeded");
  }
};

app.get("/api/levels", async (req, res) => {
  const levels = await AppDataSource.getRepository(Level).find({ order: { id: "ASC" } });
  res.json(levels);
});

app.get("/api/levels/user/:userId", async (req, res) => {
  const { userId } = req.params;
  let userLevel = await AppDataSource.getRepository(UserLevel).findOneBy({ userId });
  if (!userLevel) {
    // Default to Level 1
    userLevel = await AppDataSource.getRepository(UserLevel).save({ userId, levelId: 1 });
  }
  res.json(userLevel);
});

app.post("/api/levels/move", async (req, res) => {
  const { userId, levelId } = req.body;
  if (!userId || !levelId) return res.status(400).json({ error: "Missing fields" });

  let userLevel = await AppDataSource.getRepository(UserLevel).findOneBy({ userId });
  if (userLevel) {
    userLevel.levelId = levelId;
    await AppDataSource.getRepository(UserLevel).save(userLevel);
  } else {
    userLevel = await AppDataSource.getRepository(UserLevel).save({ userId, levelId });
  }
  res.json(userLevel);
});

AppDataSource.initialize()
  .then(async () => {
    console.log("Level Service Data Source initialized");
    await seedLevels();
    app.listen(PORT, () => {
      console.log(`Level Service running on port ${PORT}`);
    });
  })
  .catch((error) => console.log(error));
