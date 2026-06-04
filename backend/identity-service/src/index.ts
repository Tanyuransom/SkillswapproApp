import "reflect-metadata";
import * as dotenv from "dotenv";
dotenv.config();

import app from "./app";
import { initializeDatabase } from "./data-source";

const PORT = process.env.PORT || 3001;

const startServer = async () => {
    await initializeDatabase();
    app.listen(PORT, () => {
        console.log(`Identity Service is running on port ${PORT}`);
    });
};

startServer().catch(console.error);
