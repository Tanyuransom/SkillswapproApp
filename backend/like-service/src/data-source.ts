import "reflect-metadata";
import { DataSource } from "typeorm";
import { Like } from "./entities/Like";
import * as dotenv from "dotenv";

dotenv.config();

export const AppDataSource = new DataSource({
  type: "postgres",
  url: process.env.DATABASE_URL,
  synchronize: true,
  logging: false,
  entities: [Like],
  migrations: [],
  subscribers: [],
});

export const initializeDatabase = async () => {
    try {
        await AppDataSource.initialize();
        console.log("Like Service Data Source has been initialized!");
    } catch (err) {
        console.error("Error during Like Service Data Source initialization", err);
        process.exit(1);
    }
};
