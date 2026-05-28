import * as dotenv from "dotenv";
dotenv.config();

import express from "express";
import cors from "cors";
import helmet from "helmet";
import { initializeDatabase } from "./data-source";

const app = express();
const PORT = process.env.PORT || 3012;

app.use(helmet({
  crossOriginResourcePolicy: false,
}));
app.use(cors());
app.use(express.json());

// Health-check endpoint
app.get("/health", (req: express.Request, res: express.Response) => {
  res.status(200).json({ status: "UP (Stat)", timestamp: new Date() });
});

// Admin stats
app.get("/admin", async (req, res) => {
  try {
    const usersRes = await fetch("http://user-service:3003/").then(r => r.json() as Promise<any[]>);
    const coursesRes = await fetch("http://course-service:3002/").then(r => r.json() as Promise<any[]>);

    let activeStudents = 0;
    let totalTutors = 0;
    for (const u of usersRes) {
      if (u.role === "tutor") totalTutors++;
      else if (u.role === "student") activeStudents++;
    }

    res.status(200).json({
      activeStudents,
      totalTutors,
      totalCourses: coursesRes.length,
      totalEnrollments: activeStudents,
    });
  } catch (error: any) {
    console.error("Failed to fetch admin stats:", error.message);
    res.status(200).json({ activeStudents: 0, totalTutors: 0, totalCourses: 0, totalEnrollments: 0 });
  }
});

// Tutor stats
app.get("/tutor/:tutorId", async (req, res) => {
  try {
    const { tutorId } = req.params;
    const enrollments = await fetch(`http://enrollment-service:3008/tutor/${tutorId}/students`).then(r => r.json() as Promise<any[]>);
    const courses = await fetch(`http://course-service:3002/courses/tutor/${tutorId}/courses`).then(r => r.json() as Promise<any[]>);

    const activeStudents = enrollments.length;
    const totalEarnings = activeStudents * 15000;

    res.status(200).json({
      totalEarnings,
      activeStudents,
      newEnrollments: activeStudents,
      totalCourses: courses.length,
    });
  } catch (error: any) {
    console.error("Failed to fetch tutor stats:", error.message);
    res.status(200).json({ totalEarnings: 0, activeStudents: 0, newEnrollments: 0 });
  }
});

// Basic Stat routes placeholder
app.get("/", async (req, res) => {
  try {
    const usersRes = await fetch("http://user-service:3003/").then(r => r.json() as Promise<any[]>);
    res.status(200).json({ activeUsers: usersRes.length, totalEnrollments: usersRes.filter(u => u.role === "student").length });
  } catch (error) {
    res.status(200).json({ activeUsers: 0, totalEnrollments: 0 });
  }
});

const startServer = async () => {
    await initializeDatabase();
    app.listen(PORT, () => {
        console.log(`Stat Service is running on port ${PORT}`);
    });
};

startServer().catch(console.error);

