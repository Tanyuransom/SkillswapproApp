import "reflect-metadata";
import { DataSource } from "typeorm";
import { Level } from "./entities/Level";
import { UserLevel } from "./entities/UserLevel";
import * as dotenv from "dotenv";

dotenv.config();

export const AppDataSource = new DataSource({
  type: "postgres",
  url: process.env.DATABASE_URL,
  synchronize: true,
  logging: false,
  entities: [Level, UserLevel],
  migrations: [],
  subscribers: [],
});
