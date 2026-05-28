import "reflect-metadata";
import { DataSource } from "typeorm";
import { Message } from "./entities/Message";
import * as dotenv from "dotenv";

dotenv.config();

export const AppDataSource = new DataSource({
  type: "postgres",
  url: process.env.DATABASE_URL,
  synchronize: true, // Only for development!
  logging: false,
  entities: [Message],
  migrations: [],
  subscribers: [],
});

export const initializeDatabase = async () => {
    try {
        await AppDataSource.initialize();
        console.log("Messaging Service Data Source has been initialized!");
    } catch (err) {
        console.error("Error during Messaging Service Data Source initialization", err);
        process.exit(1);
    }
};
