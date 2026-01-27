/**
 * Ride Request Controller
 * Handles ride join requests and approvals
 */

const pool = require('../db/db');
const { v4: uuidv4 } = require('uuid');

// @desc    Request to join a ride
// @route   POST /api/rides/:ride_id/requests
// @access  Private
const createRideRequest = async (req, res) => {
  const { ride_id } = req.params;
  const { requester_id } = req.body;

  const requestId = uuidv4();
  const notificationId = uuidv4();

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Check if ride is still open
    const rideCheck = await client.query(
      `SELECT r.*, u.full_name as requester_name
       FROM rides r, users u
       WHERE r.ride_id = $1 AND u.user_id = $2 AND r.status = 'open'`,
      [ride_id, requester_id]
    );

    if (rideCheck.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(400).json({ 
        success: false, 
        message: "Ride not available or user not found." 
      });
    }

    const ride = rideCheck.rows[0];

    // Insert request
    const requestResult = await client.query(
      `INSERT INTO ride_requests (request_id, ride_id, requester_id, status)
       VALUES ($1, $2, $3, 'pending')
       RETURNING *`,
      [requestId, ride_id, requester_id]
    );

    // Notify ride initiator
    const notificationMessage = `${ride.requester_name} has requested to join your ride to ${ride.destination_name}.`;
    await client.query(
      `INSERT INTO notifications (notification_id, user_id, ride_id, message)
       VALUES ($1, $2, $3, $4)`,
      [notificationId, ride.initiator_id, ride_id, notificationMessage]
    );

    await client.query('COMMIT');
    res.status(201).json({ 
      success: true, 
      data: requestResult.rows[0] 
    });
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
};

// @desc    Accept or reject ride request
// @route   PUT /api/rides/:ride_id/requests/:request_id
// @access  Private
const updateRideRequest = async (req, res) => {
  const { ride_id, request_id } = req.params;
  const { action, meeting_lat, meeting_lng } = req.body;

  const participantId = uuidv4();
  const notificationId = uuidv4();

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Get request details
    const requestCheck = await client.query(
      `SELECT rr.*, r.destination_name, u.full_name as requester_name
       FROM ride_requests rr
       JOIN rides r ON rr.ride_id = r.ride_id
       JOIN users u ON rr.requester_id = u.user_id
       WHERE rr.request_id = $1 AND rr.ride_id = $2 AND rr.status = 'pending'`,
      [request_id, ride_id]
    );

    if (requestCheck.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ 
        success: false, 
        message: "Request not found or already processed." 
      });
    }

    const request = requestCheck.rows[0];

    if (action === 'accept') {
      // Update request status
      await client.query(
        `UPDATE ride_requests SET status = 'accepted' WHERE request_id = $1`,
        [request_id]
      );

      // Add to ride participants
      await client.query(
        `INSERT INTO ride_participants (participant_id, ride_id, user_id, meeting_lat, meeting_lng, has_met)
         VALUES ($1, $2, $3, $4, $5, FALSE)`,
        [participantId, ride_id, request.requester_id, meeting_lat, meeting_lng]
      );

      // Notify requester
      const notificationMessage = `Your request to join the ride to ${request.destination_name} has been accepted!`;
      await client.query(
        `INSERT INTO notifications (notification_id, user_id, ride_id, message)
         VALUES ($1, $2, $3, $4)`,
        [notificationId, request.requester_id, ride_id, notificationMessage]
      );
    } else if (action === 'reject') {
      await client.query(
        `UPDATE ride_requests SET status = 'rejected' WHERE request_id = $1`,
        [request_id]
      );

      const notificationMessage = `Your request to join the ride to ${request.destination_name} was not accepted.`;
      await client.query(
        `INSERT INTO notifications (notification_id, user_id, ride_id, message)
         VALUES ($1, $2, $3, $4)`,
        [notificationId, request.requester_id, ride_id, notificationMessage]
      );
    }

    await client.query('COMMIT');
    res.status(200).json({ 
      success: true, 
      message: `Request ${action}ed successfully.` 
    });
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
};

module.exports = {
  createRideRequest,
  updateRideRequest
};
