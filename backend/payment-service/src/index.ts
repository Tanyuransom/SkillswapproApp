import * as dotenv from "dotenv";
dotenv.config();

import express from "express";
import cors from "cors";
import helmet from "helmet";
import { initializeDatabase, AppDataSource } from "./data-source";
import { Payment } from "./entities/Payment";

const app = express();
const PORT = process.env.PORT || 3009;

app.use(helmet({
  crossOriginResourcePolicy: false,
}));
app.use(cors());
app.use(express.json());

// Health-check endpoint
app.get("/health", (req: express.Request, res: express.Response) => {
  res.status(200).json({ status: "UP (Payment)", timestamp: new Date() });
});

// POST Checkout
app.post("/checkout", async (req, res) => {
  const { userId, courseId, amount, method, phoneNumber } = req.body;
  if (!userId || !courseId || amount === undefined) {
    return res.status(400).json({ error: "Missing required checkout fields" });
  }

  const rawAmount = parseFloat(amount);
  const tax = Math.round(rawAmount * 0.1 * 100) / 100; // 10% tax
  const total = rawAmount + tax;

  try {
    const repo = AppDataSource.getRepository(Payment);
    const payment = repo.create({
      userId,
      courseId,
      amount: rawAmount,
      method: method || "MTN",
      tax,
      total,
      phoneNumber: phoneNumber || "",
      status: "pending"
    });
    
    await repo.save(payment);

    return res.status(201).json({
      success: true,
      paymentId: payment.id,
      status: "pending",
      amount: rawAmount,
      tax,
      total,
      message: "USSD push notification sent. Please enter your PIN to authorize payment."
    });
  } catch (err: any) {
    return res.status(500).json({ error: err.message || "Failed to initiate payment" });
  }
});

// POST Authorize
app.post("/authorize", async (req, res) => {
  const { paymentId, pin } = req.body;
  if (!paymentId || !pin) {
    return res.status(400).json({ error: "Missing paymentId or PIN" });
  }

  if (pin.length !== 4 || isNaN(Number(pin))) {
    return res.status(400).json({ error: "Invalid PIN. Must be 4 digits." });
  }

  try {
    const repo = AppDataSource.getRepository(Payment);
    const payment = await repo.findOneBy({ id: paymentId });
    if (!payment) {
      return res.status(404).json({ error: "Payment record not found" });
    }

    payment.status = "completed";
    await repo.save(payment);

    return res.json({
      success: true,
      status: "completed",
      message: "Payment authorized and completed successfully!"
    });
  } catch (err: any) {
    return res.status(500).json({ error: err.message || "Authorization failed" });
  }
});

// GET User Payments
app.get("/user/:userId", async (req, res) => {
  const { userId } = req.params;
  try {
    const repo = AppDataSource.getRepository(Payment);
    const payments = await repo.find({
      where: { userId, status: "completed" },
      order: { createdAt: "DESC" }
    });
    return res.json(payments);
  } catch (err: any) {
    return res.status(500).json({ error: err.message || "Database error" });
  }
});

const startServer = async () => {
    await initializeDatabase();
    app.listen(PORT, () => {
        console.log(`Payment Service is running on port ${PORT}`);
    });
};

startServer().catch(console.error);
