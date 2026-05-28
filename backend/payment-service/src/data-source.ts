import "reflect-metadata";
import { DataSource } from "typeorm";
import { Payment } from "./entities/Payment";
import * as dotenv from "dotenv";

dotenv.config();

export const AppDataSource = new DataSource({
  type: "postgres",
  url: process.env.DATABASE_URL,
  synchronize: true,
  logging: false,
  entities: [Payment],
  migrations: [],
  subscribers: [],
});

export const initializeDatabase = async () => {
    try {
        await AppDataSource.initialize();
        console.log("Payment Service Data Source has been initialized!");
    } catch (err) {
        console.error("Error during Payment Service Data Source initialization", err);
        process.exit(1);
    }
};
