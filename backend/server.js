import express from "express";
import cors from "cors";
import { config } from "dotenv";
import mongoose from "mongoose";
import pkg from "pg";
const { Pool } = pkg;

// Import Mongoose Model
import Movement from "./models/Movement.js";

config({ path: "./.env" });

const app = express();
app.use(express.json()); // Essential for POST requests
app.use(
  cors({
    origin: ["http://localhost:5173"],
    methods: ["GET", "POST", "PUT", "DELETE"],
  })
);

// --- 1. PostgreSQL Connection (Relational Data) ---
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});
pool.on('connect', () => console.log("PostgreSQL Connected 🐘"));

// --- 2. MongoDB Connection (GPS Tracking) ---
mongoose.connect(process.env.MONGO_URI)
  .then(() => console.log("MongoDB Connected 🍃"))
  .catch((err) => console.error("MongoDB Connection Error:", err));

// --- 3. Routes ---

// Home route
app.get("/", (req, res) => {
  res.send("Dromos API is running...");
});

// Student Verification & Persistence
app.get("/studentship/:id", async (req, res) => {
  const studentId = req.params.id;
  try {
    const du_response = await fetch(
      `https://academic.eis.du.ac.bd/en/studentship/${studentId}`
    );

    if (!du_response.ok) {
      return res.status(400).json({ message: `Failed to verify Student ID ${studentId}.` });
    }

    const studentData = await du_response.json();

    // PERSISTENCE: Save/Update verified student in PostgreSQL
    const query = `
      INSERT INTO users (full_name, registration_number, dept_name, verification_status)
      VALUES ($1, $2, $3, 'verified')
      ON CONFLICT (registration_number) 
      DO UPDATE SET verification_status = 'verified'
      RETURNING *;
    `;
    const values = [studentData.name, studentId, studentData.department];
    const dbResult = await pool.query(query, values);

    res.status(200).json({
      message: `Student ID ${studentId} verified and saved.`,
      user: dbResult.rows[0],
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "An error occurred during verification." });
  }
});

// Real-time GPS Tracking Route (NoSQL)
app.post("/track-movement", async (req, res) => {
  const { ride_id, user_id, latitude, longitude } = req.body;
  try {
    const newLog = await Movement.create({
      ride_id,
      user_id,
      location: {
        type: "Point",
        coordinates: [longitude, latitude], // MongoDB uses [lng, lat]
      },
    });
    res.status(201).json(newLog);
  } catch (error) {
    res.status(500).json({ error: "Failed to log movement." });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server is running on http://localhost:${PORT}`);
});