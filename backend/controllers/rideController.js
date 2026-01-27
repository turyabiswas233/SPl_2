/**
 * Ride Controller
 * Handles ride creation, browsing, and management
 */

const pool = require('../db/db');
const crypto = require('crypto');
const { v4: uuidv4 } = require('uuid');

// @desc    Create a new ride
// @route   POST /api/rides
// @access  Private
const createRide = async (req, res) => {
  const { initiator_id, start_location, start_lat, start_lng, destination, dest_lat, dest_lng, max_seats } = req.body;

  const qrCode = crypto.randomBytes(16).toString("hex");
  const otp = Math.floor(100000 + Math.random() * 900000).toString();
  
  const rideId = uuidv4();
  const participantId = uuidv4();
  const notificationId = uuidv4();

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Insert RIDE
    const rideQuery = `
      INSERT INTO rides (ride_id, initiator_id, start_location, start_lat, start_lng, destination_name, dest_lat, dest_lng, trip_qr_code, trip_otp, max_seats)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
      RETURNING *;
    `;
    const rideResult = await client.query(rideQuery, [
      rideId, initiator_id, start_location, start_lat, start_lng, destination, dest_lat, dest_lng, qrCode, otp, max_seats
    ]);

    // Insert PARTICIPANT
    await client.query(
      `INSERT INTO ride_participants (participant_id, ride_id, user_id, has_met, met_at) VALUES ($1, $2, $3, TRUE, NOW())`,
      [participantId, rideId, initiator_id]
    );

    // Create notification
    const notificationMessage = `Your ride from ${start_location} to ${destination} has been created successfully.`;
    await client.query(
      `INSERT INTO notifications (notification_id, user_id, ride_id, message) VALUES ($1, $2, $3, $4)`,
      [notificationId, initiator_id, rideId, notificationMessage]
    );

    await client.query('COMMIT');
    res.status(201).json({ 
      success: true, 
      data: rideResult.rows[0] 
    });
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
};

// @desc    Browse available rides
// @route   GET /api/rides
// @access  Public
const getRides = async (req, res) => {
  const { gender_filter, min_seats, destination } = req.query;
  
  let query = `
    SELECT r.*, u.full_name as initiator_name, 
           (SELECT COUNT(*) FROM ride_participants WHERE ride_id = r.ride_id) as current_passengers
    FROM rides r
    JOIN users u ON r.initiator_id = u.user_id
    WHERE r.status = 'open'
  `;
  const params = [];
  let paramCount = 1;

  if (gender_filter && gender_filter !== 'any') {
    query += ` AND r.preferred_gender IN ($${paramCount}, 'any')`;
    params.push(gender_filter);
    paramCount++;
  }

  if (min_seats) {
    query += ` AND r.max_seats >= $${paramCount}`;
    params.push(min_seats);
    paramCount++;
  }

  if (destination) {
    query += ` AND r.destination_name ILIKE $${paramCount}`;
    params.push(`%${destination}%`);
    paramCount++;
  }

  query += ` ORDER BY r.created_at DESC`;

  const result = await pool.query(query, params);
  res.status(200).json({ 
    success: true, 
    count: result.rows.length,
    data: result.rows 
  });
};

// @desc    Get specific ride details
// @route   GET /api/rides/:ride_id
// @access  Public
const getRideById = async (req, res) => {
  const { ride_id } = req.params;
  
  const rideResult = await pool.query(
    `SELECT r.*, u.full_name as initiator_name, u.phone_number as initiator_phone
     FROM rides r
     JOIN users u ON r.initiator_id = u.user_id
     WHERE r.ride_id = $1`,
    [ride_id]
  );

  if (rideResult.rows.length === 0) {
    return res.status(404).json({ 
      success: false, 
      message: "Ride not found." 
    });
  }

  const participantsResult = await pool.query(
    `SELECT rp.*, u.full_name, u.phone_number
     FROM ride_participants rp
     JOIN users u ON rp.user_id = u.user_id
     WHERE rp.ride_id = $1`,
    [ride_id]
  );

  res.status(200).json({
    success: true,
    data: {
      ride: rideResult.rows[0],
      participants: participantsResult.rows
    }
  });
};

// @desc    Complete a trip
// @route   POST /api/rides/:ride_id/complete
// @access  Private
const completeRide = async (req, res) => {
  const { ride_id } = req.params;
  const { initiator_id, total_fare } = req.body;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Verify initiator
    const rideCheck = await pool.query(
      `SELECT * FROM rides WHERE ride_id = $1 AND initiator_id = $2`,
      [ride_id, initiator_id]
    );

    if (rideCheck.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(403).json({ 
        success: false, 
        message: "Only the initiator can complete the ride." 
      });
    }

    // Update ride status
    await client.query(
      `UPDATE rides SET status = 'completed' WHERE ride_id = $1`,
      [ride_id]
    );

    // Calculate split fare if provided
    if (total_fare) {
      const participantsResult = await client.query(
        `SELECT user_id FROM ride_participants WHERE ride_id = $1`,
        [ride_id]
      );

      const splitAmount = (total_fare / participantsResult.rows.length).toFixed(2);

      for (const participant of participantsResult.rows) {
        const fareId = uuidv4();
        await client.query(
          `INSERT INTO fares (fare_id, ride_id, user_id, amount)
           VALUES ($1, $2, $3, $4)`,
          [fareId, ride_id, participant.user_id, splitAmount]
        );
      }
    }

    // Notify all participants
    const participantsResult = await client.query(
      `SELECT user_id FROM ride_participants WHERE ride_id = $1`,
      [ride_id]
    );

    for (const participant of participantsResult.rows) {
      const notificationId = uuidv4();
      const notificationMessage = total_fare 
        ? `Trip completed! Your share: $${(total_fare / participantsResult.rows.length).toFixed(2)}. Please rate your co-passengers.`
        : `Trip completed! Please rate your co-passengers.`;
      
      await client.query(
        `INSERT INTO notifications (notification_id, user_id, ride_id, message)
         VALUES ($1, $2, $3, $4)`,
        [notificationId, participant.user_id, ride_id, notificationMessage]
      );
    }

    await client.query('COMMIT');
    res.status(200).json({ 
      success: true, 
      message: "Trip completed successfully." 
    });
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
};

module.exports = {
  createRide,
  getRides,
  getRideById,
  completeRide
};
