import "reflect-metadata";
import { DataSource } from "typeorm";
import { Course } from "./entities/Course";
import { Category } from "./entities/Category";
import { Enrollment } from "./entities/Enrollment";
import { Short } from "./entities/Short";
import { Notification } from "./entities/Notification";
import { Message } from "./entities/Message";
import * as dotenv from "dotenv";

dotenv.config();

export const AppDataSource = new DataSource({
  type: "postgres",
  url: process.env.DATABASE_URL,
  synchronize: true, // Only for development!
  logging: false,
  entities: [Course, Category, Enrollment, Short, Notification, Message],
  migrations: [],
  subscribers: [],
});

export const initializeDatabase = async () => {
    try {
        await AppDataSource.initialize();
        console.log("Course Service Data Source has been initialized!");
    } catch (err) {
        console.error("Error during Course Service Data Source initialization", err);
        process.exit(1);
    }
};
