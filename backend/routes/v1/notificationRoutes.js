/**
 * Notification Routes
 * @route /api/v1/notifications
 */

const express = require("express");
const router = express.Router();
const {
  getNotifications,
  markAsRead,
} = require("../../controllers/notificationController");
const { validateUUID } = require("../../middleware/validators");
const asyncHandler = require("../../middleware/asyncHandler");
const { protect } = require("../../middleware/auth");

// @route   GET /api/v1/notifications/
router.get("/", protect, asyncHandler(getNotifications));

// @route   PUT /api/v1/notifications/:notification_id/read
router.put(
  "/:notification_id/read",
  validateUUID("notification_id"),
  asyncHandler(markAsRead),
);

module.exports = router;
