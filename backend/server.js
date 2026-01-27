import express from "express";
import cors from "cors";
import { config } from "dotenv";
import mongoose from "mongoose";
import pkg from "pg";
import crypto from "crypto"; // For generating unique QR codes
const { Pool } = pkg;

// Import Mongoose Model
import Movement from "./models/Movement.js";

config({ path: "./.env" });

const app = express();
app.use(express.json());
app.use(
  cors({
    origin: ["http://localhost:5173"],
    methods: ["GET", "POST", "PUT", "DELETE"],
  })
);

// --- 1. Database Connections ---
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

mongoose.connect(process.env.MONGO_URI)
  .then(() => console.log("MongoDB Connected 🍃"))
  .catch((err) => console.error("MongoDB Error:", err));

// --- 2. Identity & Verification Route ---
app.get("/studentship/:id", async (req, res) => {
  const studentId = req.params.id;
  try {
    const du_response = await fetch(`https://academic.eis.du.ac.bd/en/studentship/${studentId}`);
    if (!du_response.ok) return res.status(400).json({ message: "Verification failed." });

    const studentData = await du_response.json();

    const query = `
      INSERT INTO users (full_name, registration_number, dept_name, verification_status)
      VALUES ($1, $2, $3, 'verified')
      ON CONFLICT (registration_number) DO UPDATE SET verification_status = 'verified'
      RETURNING *;
    `;
    const dbResult = await pool.query(query, [studentData.name, studentId, studentData.department]);

    res.status(200).json(dbResult.rows[0]);
  } catch (error) {
    res.status(500).json({ message: "Server error." });
  }
});

// --- 3. Ride Creation Route (PostgreSQL) ---
// This generates the QR and OTP for the handshake
app.post("/create-ride", async (req, res) => {
  const { initiator_id, start_location, start_lat, start_lng, destination, dest_lat, dest_lng, max_seats } = req.body;

  try {
    // Generate handshake tokens
    const qrCode = crypto.randomBytes(16).toString("hex");
    const otp = Math.floor(100000 + Math.random() * 900000).toString();

    // Start Transaction: Create ride and add initiator to participants
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      const rideQuery = `
        INSERT INTO rides (initiator_id, start_location, start_coords, destination_name, destination_coords, trip_qr_code, trip_otp, max_seats)
        VALUES ($1, $2, ST_MakePoint($3, $4), $5, ST_MakePoint($6, $7), $8, $9, $10)
        RETURNING *;
      `;
      const rideResult = await client.query(rideQuery, [
        initiator_id, start_location, start_lng, start_lat, destination, dest_lng, dest_lat, qrCode, otp, max_seats
      ]);

      const rideId = rideResult.rows[0].ride_id;

      // Add Initiator as the first participant (auto-verified presence)
      await client.query(
        `INSERT INTO ride_participants (ride_id, user_id, has_met, met_at) VALUES ($1, $2, TRUE, NOW())`,
        [rideId, initiator_id]
      );

      await client.query('COMMIT');
      res.status(201).json(rideResult.rows[0]);
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Could not create ride." });
  }
});

// --- 4. GPS Tracking Route (MongoDB) ---
app.post("/track-movement", async (req, res) => {
  const { ride_id, user_id, latitude, longitude } = req.body;
  try {
    const log = await Movement.create({
      ride_id,
      user_id,
      location: { type: "Point", coordinates: [longitude, latitude] },
    });
    res.status(201).json(log);
  } catch (error) {
    res.status(500).json({ error: "Tracking failed." });
  }
});
// --- 5. Join Ride & Handshake Route (PostgreSQL) ---
// This handles the QR Scan/OTP verification for passengers
app.post("/verify-handshake", async (req, res) => {
  const { ride_id, user_id, scanned_qr_code, current_lat, current_lng } = req.body;

  try {
    // 1. Verify if the QR code matches the Ride ID
    const rideCheck = await pool.query(
      "SELECT trip_qr_code, status FROM rides WHERE ride_id = $1",
      [ride_id]
    );

    if (rideCheck.rows.length === 0) {
      return res.status(404).json({ message: "Ride not found." });
    }

    const ride = rideCheck.rows[0];

    if (ride.trip_qr_code !== scanned_qr_code) {
      return res.status(401).json({ message: "Invalid QR Code. Presence not verified." });
    }

    // 2. Proximity Check (Optional but Recommended)
    // Checks if user is within 100 meters of their assigned meeting_coords
    const proximityQuery = `
      SELECT ST_DWithin(
        meeting_coords, 
        ST_MakePoint($1, $2)::geography, 
        100
      ) as is_nearby 
      FROM ride_participants 
      WHERE ride_id = $3 AND user_id = $4;
    `;
    const proximityResult = await pool.query(proximityQuery, [current_lng, current_lat, ride_id, user_id]);

    if (proximityResult.rows.length > 0 && !proximityResult.rows[0].is_nearby) {
      return res.status(400).json({ message: "You are too far from the meeting point." });
    }

    // 3. Update Participant Status to 'has_met'
    const updateQuery = `
      UPDATE ride_participants 
      SET has_met = TRUE, met_at = NOW() 
      WHERE ride_id = $1 AND user_id = $2 
      RETURNING *;
    `;
    const result = await pool.query(updateQuery, [ride_id, user_id]);

    if (result.rowCount === 0) {
      return res.status(404).json({ message: "Student not registered for this ride." });
    }

    // 4. Auto-Start Ride if everyone has met (Optional logic)
    // If all joined participants have has_met = true, update ride status to 'in_progress'
    await pool.query(`
      UPDATE rides 
      SET status = 'in_progress' 
      WHERE ride_id = $1 
      AND NOT EXISTS (
        SELECT 1 FROM ride_participants WHERE ride_id = $1 AND has_met = FALSE
      );
    `, [ride_id]);

    res.status(200).json({
      message: "Handshake successful! You are now part of the active trip.",
      participant: result.rows[0]
    });

  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Handshake verification failed." });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Dromos Backend on port ${PORT}`));