/**
 * Notification Controller
 * Handles user notifications
 */

const pool = require('../db/db');

// @desc    Get user notifications
// @route   GET /api/notifications/
// @access  Private
const getNotifications = async (req, res) => {
  const user_id  = req.user.userId;
  
  const result = await pool.query(
    `SELECT * FROM notifications WHERE user_id = $1 ORDER BY created_at DESC`,
    [user_id]
  );
  
  res.status(200).json({ 
    success: true, 
    count: result.rows.length,
    data: result.rows 
  });
};

// @desc    Mark notification as read
// @route   PUT /api/notifications/:notification_id/read
// @access  Private
const markAsRead = async (req, res) => {
  const { notification_id } = req.params;
  
  const result = await pool.query(
    `UPDATE notifications SET is_read = TRUE WHERE notification_id = $1 RETURNING *`,
    [notification_id]
  );
  
  if (result.rows.length === 0) {
    return res.status(404).json({ 
      success: false, 
      message: "Notification not found." 
    });
  }
  
  res.status(200).json({ 
    success: true, 
    data: result.rows[0] 
  });
};

module.exports = {
  getNotifications,
  markAsRead
};
