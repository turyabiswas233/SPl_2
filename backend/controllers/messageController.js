/**
 * Message Controller
 * Handles in-ride chat messages
 */

const pool = require('../db/db');
const { v4: uuidv4 } = require('uuid');

// @desc    Send message in ride chat
// @route   POST /api/rides/:ride_id/messages
// @access  Private
const sendMessage = async (req, res) => {
  const { ride_id } = req.params;
  const { sender_id, message_text } = req.body;

  const messageId = uuidv4();

  // Verify sender is part of the ride
  const participantCheck = await pool.query(
    `SELECT * FROM ride_participants WHERE ride_id = $1 AND user_id = $2`,
    [ride_id, sender_id]
  );

  if (participantCheck.rows.length === 0) {
    return res.status(403).json({ 
      success: false, 
      message: "You are not part of this ride." 
    });
  }

  const result = await pool.query(
    `INSERT INTO messages (message_id, ride_id, sender_id, message_text)
     VALUES ($1, $2, $3, $4)
     RETURNING *`,
    [messageId, ride_id, sender_id, message_text]
  );

  res.status(201).json({ 
    success: true, 
    data: result.rows[0] 
  });
};

// @desc    Get ride messages
// @route   GET /api/rides/:ride_id/messages
// @access  Private
const getMessages = async (req, res) => {
  const { ride_id } = req.params;
  
  const result = await pool.query(
    `SELECT m.*, u.full_name as sender_name
     FROM messages m
     JOIN users u ON m.sender_id = u.user_id
     WHERE m.ride_id = $1
     ORDER BY m.created_at ASC`,
    [ride_id]
  );

  res.status(200).json({ 
    success: true, 
    count: result.rows.length,
    data: result.rows 
  });
};

module.exports = {
  sendMessage,
  getMessages
};
