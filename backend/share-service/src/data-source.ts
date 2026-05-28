import "reflect-metadata";
import { DataSource } from "typeorm";
import { Share } from "./entities/Share";
import * as dotenv from "dotenv";

dotenv.config();

export const AppDataSource = new DataSource({
  type: "postgres",
  url: process.env.DATABASE_URL,
  synchronize: true,
  logging: false,
  entities: [Share],
  migrations: [],
  subscribers: [],
});

export const initializeDatabase = async () => {
    try {
        await AppDataSource.initialize();
        console.log("Share Service Data Source has been initialized!");
    } catch (err) {
        console.error("Error during Share Service Data Source initialization", err);
        process.exit(1);
    }
};
