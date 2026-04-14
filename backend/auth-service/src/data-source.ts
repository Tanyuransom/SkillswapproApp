import "reflect-metadata";
import { DataSource } from "typeorm";
import { User } from "./entities/User";
import * as dotenv from "dotenv";

dotenv.config();

export const AppDataSource = new DataSource({
  type: "postgres",
  url: process.env.DATABASE_URL,
  synchronize: true, // Only for development! In production, use migrations.
  logging: false,
  entities: [User],
  migrations: [],
  subscribers: [],
});

export const initializeDatabase = async () => {
    try {
        await AppDataSource.initialize();
        console.log("Data Source has been initialized!");
    } catch (err) {
        console.error("Error during Data Source initialization", err);
        process.exit(1);
    }
};
