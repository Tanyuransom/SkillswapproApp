import * as dotenv from "dotenv";
dotenv.config();

import express from "express";
import cors from "cors";
import helmet from "helmet";
import { initializeDatabase, AppDataSource } from "./data-source";
import { Verification } from "./entities/Verification";

const app = express();
const PORT = process.env.PORT || 3010;

app.use(helmet({
  crossOriginResourcePolicy: false,
}));
app.use(cors());
app.use(express.json());

interface Question {
  id: string;
  question: string;
  options: string[];
  correctAnswer: string;
}

const EXAMS_DB: Record<string, Question[]> = {
  SEN: [
    {
      id: "sen_1",
      question: "What does the 'S' in SOLID design principles stand for?",
      options: ["Single Responsibility", "State Management", "System Integration", "Service Oriented"],
      correctAnswer: "Single Responsibility"
    },
    {
      id: "sen_2",
      question: "Which design pattern is used to decouple an abstraction from its implementation?",
      options: ["Adapter Pattern", "Bridge Pattern", "Composite Pattern", "Facade Pattern"],
      correctAnswer: "Bridge Pattern"
    },
    {
      id: "sen_3",
      question: "What is the main goal of Clean Architecture?",
      options: ["Minimizing line counts", "Separation of concerns and independence of frameworks", "Maximizing server speed", "Using SQL databases exclusively"],
      correctAnswer: "Separation of concerns and independence of frameworks"
    },
    {
      id: "sen_4",
      question: "In UML class diagrams, what does a hollow diamond shape represent?",
      options: ["Composition", "Generalization", "Aggregation", "Dependency"],
      correctAnswer: "Aggregation"
    },
    {
      id: "sen_5",
      question: "Which architectural pattern uses a dispatcher to broadcast events to multiple stores?",
      options: ["MVC", "MVVM", "Flux/Redux", "Layered Architecture"],
      correctAnswer: "Flux/Redux"
    }
  ],
  CS: [
    {
      id: "cs_1",
      question: "What is the time complexity of searching a sorted array using binary search?",
      options: ["O(n)", "O(n log n)", "O(log n)", "O(1)"],
      correctAnswer: "O(log n)"
    },
    {
      id: "cs_2",
      question: "Which data structure operates on a Last-In, First-Out (LIFO) basis?",
      options: ["Queue", "Stack", "Heap", "Binary Tree"],
      correctAnswer: "Stack"
    },
    {
      id: "cs_3",
      question: "What is the primary purpose of a compiler?",
      options: ["Execute code line-by-line", "Translate source code to machine code", "Format code indentation", "Manage memory dynamically"],
      correctAnswer: "Translate source code to machine code"
    },
    {
      id: "cs_4",
      question: "What does the term 'thread safety' refer to?",
      options: ["Preventing access to physical ports", "Ensuring code executes correctly in concurrent/multithreaded environments", "Using SSL certificates", "Encrypting database backups"],
      correctAnswer: "Ensuring code executes correctly in concurrent/multithreaded environments"
    },
    {
      id: "cs_5",
      question: "Which algorithm is commonly used to find the shortest path in a graph?",
      options: ["Dijkstra's Algorithm", "Kruskal's Algorithm", "Binary Search", "Quicksort"],
      correctAnswer: "Dijkstra's Algorithm"
    }
  ],
  CYS: [
    {
      id: "cys_1",
      question: "What does HTTPS use to secure data in transit?",
      options: ["AES-128 strictly", "TLS/SSL", "MD5 hashing", "Rot13"],
      correctAnswer: "TLS/SSL"
    },
    {
      id: "cys_2",
      question: "What is a 'SQL Injection' attack?",
      options: ["Injecting malicious SQL queries into input fields to bypass database constraints", "Bypassing router firewalls", "Cracking server passwords", "DOS attack using ICMP requests"],
      correctAnswer: "Injecting malicious SQL queries into input fields to bypass database constraints"
    },
    {
      id: "cys_3",
      question: "What is the primary purpose of a firewall?",
      options: ["Preventing CPU from overheating", "Filtering incoming and outgoing network traffic based on security rules", "Encrypting saved passwords", "Anti-virus execution"],
      correctAnswer: "Filtering incoming and outgoing network traffic based on security rules"
    },
    {
      id: "cys_4",
      question: "In cryptography, what is a 'salt' used for?",
      options: ["Increasing network transmission speeds", "Adding random data to password hashes to prevent rainbow table attacks", "Compressing backup files", "Key exchanges"],
      correctAnswer: "Adding random data to password hashes to prevent rainbow table attacks"
    },
    {
      id: "cys_5",
      question: "What does the term 'phishing' refer to?",
      options: ["Brute-forcing admin accounts", "Social engineering attacks designed to trick users into revealing sensitive data", "Scanning open ports", "Packet sniffing"],
      correctAnswer: "Social engineering attacks designed to trick users into revealing sensitive data"
    }
  ],
  ICT: [
    {
      id: "ict_1",
      question: "What does IP stand for in network terminology?",
      options: ["Information Protocol", "Internet Protocol", "Internal Process", "Intranet Port"],
      correctAnswer: "Internet Protocol"
    },
    {
      id: "ict_2",
      question: "Which port is typically used for secure SSH connections?",
      options: ["Port 80", "Port 443", "Port 22", "Port 21"],
      correctAnswer: "Port 22"
    },
    {
      id: "ict_3",
      question: "What is the primary function of a DNS server?",
      options: ["Assigning IP addresses to local machines", "Translating domain names into IP addresses", "Routing packets across countries", "Hosting web assets"],
      correctAnswer: "Translating domain names into IP addresses"
    },
    {
      id: "ict_4",
      question: "Which OSI model layer is responsible for routing packets across networks?",
      options: ["Physical Layer", "Network Layer", "Transport Layer", "Application Layer"],
      correctAnswer: "Network Layer"
    },
    {
      id: "ict_5",
      question: "What does DHCP stand for?",
      options: ["Data Handling Host Protocol", "Dynamic Host Configuration Protocol", "Domain Hosting Communication Port", "Direct Host Connection Protocol"],
      correctAnswer: "Dynamic Host Configuration Protocol"
    }
  ],
  ISN: [
    {
      id: "isn_1",
      question: "What does IP stand for in network terminology?",
      options: ["Information Protocol", "Internet Protocol", "Internal Process", "Intranet Port"],
      correctAnswer: "Internet Protocol"
    },
    {
      id: "isn_2",
      question: "Which port is typically used for secure SSH connections?",
      options: ["Port 80", "Port 443", "Port 22", "Port 21"],
      correctAnswer: "Port 22"
    },
    {
      id: "isn_3",
      question: "What is the primary function of a DNS server?",
      options: ["Assigning IP addresses to local machines", "Translating domain names into IP addresses", "Routing packets across countries", "Hosting web assets"],
      correctAnswer: "Translating domain names into IP addresses"
    },
    {
      id: "isn_4",
      question: "Which OSI model layer is responsible for routing packets across networks?",
      options: ["Physical Layer", "Network Layer", "Transport Layer", "Application Layer"],
      correctAnswer: "Network Layer"
    },
    {
      id: "isn_5",
      question: "What does DHCP stand for?",
      options: ["Data Handling Host Protocol", "Dynamic Host Configuration Protocol", "Domain Hosting Communication Port", "Direct Host Connection Protocol"],
      correctAnswer: "Dynamic Host Configuration Protocol"
    }
  ]
};

const DEFAULT_EXAM: Question[] = [
  {
    id: "def_1",
    question: "What is the basic unit of digital information?",
    options: ["Bit", "Byte", "Pixel", "Kilobyte"],
    correctAnswer: "Bit"
  },
  {
    id: "def_2",
    question: "What is the primary purpose of an Operating System?",
    options: ["Host database files", "Manage hardware resources and provide common services for programs", "Create graphics", "Compile source code"],
    correctAnswer: "Manage hardware resources and provide common services for programs"
  },
  {
    id: "def_3",
    question: "What does CPU stand for?",
    options: ["Computer Processing Unit", "Central Processing Unit", "Core Power Utility", "Control Program Unit"],
    correctAnswer: "Central Processing Unit"
  },
  {
    id: "def_4",
    question: "What type of software tool is Git?",
    options: ["Database Engine", "Integrated Development Environment", "Distributed Version Control System", "Operating System"],
    correctAnswer: "Distributed Version Control System"
  },
  {
    id: "def_5",
    question: "Which programming language is primarily used as the programming language for Flutter mobile development?",
    options: ["Swift", "Kotlin", "Dart", "TypeScript"],
    correctAnswer: "Dart"
  }
];

// Health-check endpoint
app.get("/health", (req: express.Request, res: express.Response) => {
  res.status(200).json({ status: "UP (Verification)", timestamp: new Date() });
});

// GET Verification Status
app.get("/status/:tutorId", async (req, res) => {
  const { tutorId } = req.params;
  try {
    const repo = AppDataSource.getRepository(Verification);
    const passedAttempt = await repo.findOneBy({ tutorId, status: "passed" });
    if (passedAttempt) {
      return res.json({ verified: true, status: "passed", verification: passedAttempt });
    }
    
    const latestAttempt = await repo.findOne({
      where: { tutorId },
      order: { createdAt: "DESC" }
    });
    
    return res.json({ 
      verified: false, 
      status: latestAttempt ? latestAttempt.status : "none",
      verification: latestAttempt || null
    });
  } catch (err: any) {
    return res.status(500).json({ error: err.message || "Database error" });
  }
});

// POST Generate Exam
app.post("/exam/generate", (req, res) => {
  const { specialization } = req.body;
  const spec = (specialization || "DEFAULT").toUpperCase();
  const questions = EXAMS_DB[spec] || DEFAULT_EXAM;
  const clientQuestions = questions.map(q => ({
    id: q.id,
    question: q.question,
    options: q.options
  }));
  return res.json(clientQuestions);
});

// POST Submit Exam
app.post("/exam/submit", async (req, res) => {
  const { tutorId, specialization, answers } = req.body;
  if (!tutorId) {
    return res.status(400).json({ error: "Missing tutorId" });
  }
  const spec = (specialization || "DEFAULT").toUpperCase();
  const questions = EXAMS_DB[spec] || DEFAULT_EXAM;
  
  let score = 0;
  const gradingDetails: Record<string, boolean> = {};
  const correctAnswers: Record<string, string> = {};
  
  questions.forEach(q => {
    correctAnswers[q.id] = q.correctAnswer;
    const tutorAns = answers[q.id];
    if (tutorAns === q.correctAnswer) {
      score++;
      gradingDetails[q.id] = true;
    } else {
      gradingDetails[q.id] = false;
    }
  });
  
  const passed = score >= 3;
  const status = passed ? "passed" : "failed";
  
  try {
    const repo = AppDataSource.getRepository(Verification);
    const attempt = repo.create({
      tutorId,
      specialization: spec,
      status,
      score,
      totalQuestions: questions.length,
      idNumber: "exam_result"
    });
    await repo.save(attempt);
    
    return res.status(201).json({
      passed,
      score,
      total: questions.length,
      correctAnswers,
      gradingDetails
    });
  } catch (err: any) {
    return res.status(500).json({ error: err.message || "Failed to save verification" });
  }
});

// GET Admin Audit Verifications
app.get("/admin/all", async (req, res) => {
  try {
    const repo = AppDataSource.getRepository(Verification);
    const verifications = await repo.find({
      order: { createdAt: "DESC" }
    });
    return res.json(verifications);
  } catch (err: any) {
    return res.status(500).json({ error: err.message || "Database error" });
  }
});

const startServer = async () => {
    await initializeDatabase();
    app.listen(PORT, () => {
        console.log(`Verification Service is running on port ${PORT}`);
    });
};

startServer().catch(console.error);
