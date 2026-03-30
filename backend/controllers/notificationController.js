/**
 * Notification Controller
 * Handles user notifications using Prisma ORM
 */

const prisma = require('../db/prismaClient');

// @desc    Get user notifications
// @route   GET /api/notifications/
// @access  Private
const getNotifications = async (req, res) => {
  const user_id = req.user.userId;

  try {
    const notifications = await prisma.notification.findMany({
      where: { userId: user_id },
      orderBy: { createdAt: "desc" },
    });

    res.status(200).json({
      success: true,
      count: notifications.length,
      data: notifications,
    });
  } catch (err) {
    console.error("Get notifications error:", err);
    res.status(500).json({
      success: false,
      message: "Error fetching notifications",
      error: err.message,
    });
  }
};

// @desc    Mark notification as read
// @route   PUT /api/notifications/:notification_id/read
// @access  Private
const markAsRead = async (req, res) => {
  const { notification_id } = req.params;

  try {
    const result = await prisma.notification.update({
      where: { notificationId: notification_id },
      data: { isRead: true },
    });

    res.status(200).json({
      success: true,
      data: result,
    });
  } catch (err) {
    if (err.code === "P2025") {
      return res.status(404).json({
        success: false,
        message: "Notification not found.",
      });
    }
    console.error("Mark as read error:", err);
    res.status(500).json({
      success: false,
      message: "Error updating notification",
      error: err.message,
    });
  }
};

module.exports = {
  getNotifications,
  markAsRead
};
