import "reflect-metadata";
import { DataSource } from "typeorm";
import { Category } from "./entities/Category";
import * as dotenv from "dotenv";

dotenv.config();

export const AppDataSource = new DataSource({
  type: "postgres",
  url: process.env.DATABASE_URL,
  synchronize: true, // Only for development!
  logging: false,
  entities: [Category],
  migrations: [],
  subscribers: [],
});

export const initializeDatabase = async () => {
    try {
        await AppDataSource.initialize();
        console.log("Category Service Data Source has been initialized!");
    } catch (err) {
        console.error("Error during Category Service Data Source initialization", err);
        process.exit(1);
    }
};
