/**
 * Notification Routes
 * @route /api/notifications
 */

const express = require('express');
const router = express.Router();
const { 
  getNotifications, 
  markAsRead 
} = require('../controllers/notificationController');
const { validateUUID } = require('../middleware/validators');
const asyncHandler = require('../middleware/asyncHandler');

// @route   GET /api/notifications/:user_id
router.get('/:user_id', validateUUID('user_id'), asyncHandler(getNotifications));

// @route   PUT /api/notifications/:notification_id/read
router.put('/:notification_id/read', validateUUID('notification_id'), asyncHandler(markAsRead));

module.exports = router;
