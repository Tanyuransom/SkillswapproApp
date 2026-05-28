import "reflect-metadata";
import { DataSource } from "typeorm";
import { Short } from "./entities/Short";
import { ShortComment } from "./entities/ShortComment";
import * as dotenv from "dotenv";

dotenv.config();

export const AppDataSource = new DataSource({
  type: "postgres",
  url: process.env.DATABASE_URL,
  synchronize: true, // Only for development!
  logging: false,
  entities: [Short, ShortComment],
  migrations: [],
  subscribers: [],
});

export const initializeDatabase = async () => {
    try {
        await AppDataSource.initialize();
        console.log("Shorts Service Data Source has been initialized!");
    } catch (err) {
        console.error("Error during Shorts Service Data Source initialization", err);
        process.exit(1);
    }
};
