import "reflect-metadata";
import { DataSource } from "typeorm";
import { Notification } from "./entities/Notification";
import * as dotenv from "dotenv";

dotenv.config();

export const AppDataSource = new DataSource({
  type: "postgres",
  url: process.env.DATABASE_URL,
  synchronize: true, // Only for development!
  logging: false,
  entities: [Notification],
  migrations: [],
  subscribers: [],
});

export const initializeDatabase = async () => {
    try {
        await AppDataSource.initialize();
        console.log("Notification Service Data Source has been initialized!");
    } catch (err) {
        console.error("Error during Notification Service Data Source initialization", err);
        process.exit(1);
    }
};
