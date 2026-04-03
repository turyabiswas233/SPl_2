/**
 * Notification Controller
 * Handles user notifications using Prisma ORM with OOP pattern
 */
const { io } = require("../index");
const prisma = require("../db/prismaClient");
const { v4: uuidv4 } = require("uuid");

/**
 * Notification Class
 * Encapsulates notification creation and socket.io emission logic
 */
class Notification {
  /**
   * Constructor
   * @param {string} userId - User ID receiving the notification
   * @param {string} messageText - Notification message
   * @param {string} rideId - Associated ride ID (optional)
   */
  constructor(userId, messageText, rideId = null) {
    this.notificationId = uuidv4();
    this.userId = userId;
    this.messageText = messageText;
    this.rideId = rideId;
    this.isRead = false;
    this.createdAt = new Date();
  }

  /**
   * Create notification in database
   * @param {object} txClient - Prisma transaction client (or prisma client)
   * @returns {Promise<object>} Created notification record
   */
  async save(txClient = prisma) {
    try {
      const notification = await txClient.notification.create({
        data: {
          notificationId: this.notificationId,
          userId: this.userId,
          messageText: this.messageText,
          rideId: this.rideId,
          isRead: this.isRead,
        },
      });
      return notification;
    } catch (err) {
      console.error("Error saving notification:", err);
      throw err;
    }
  }

  /**
   * Emit notification via Socket.IO to specific user
   * @param {object} ioInstance - Socket.IO instance
   */
  emit(ioInstance) {
    if (!ioInstance) {
      console.warn(
        "Socket.IO instance not available for notification emission",
      );
      return;
    }

    try {
      // Emit to specific user's room (userId as room identifier)
      ioInstance.to(this.userId).emit("notificationReceived", {
        notificationId: this.notificationId,
        userId: this.userId,
        messageText: this.messageText,
        rideId: this.rideId,
        isRead: this.isRead,
        createdAt: this.createdAt,
      });

      console.log(`📢 Notification emitted to user: ${this.userId}`);
    } catch (err) {
      console.error("Error emitting notification via Socket.IO:", err);
    }
  }
}

/**
 * @desc    Create and send a notification
 * @param   {string} userId - User ID
 * @param   {string} messageText - Notification message
 * @param   {string} rideId - Associated ride ID (optional)
 * @param   {object} txClient - Prisma transaction client (optional, defaults to prisma)
 * @returns {Promise<object>} Created notification with socket emission
 *
 * @example
 * // Simple usage
 * await postNotification(userId, "Your ride is ready!");
 *
 * // With ride ID
 * await postNotification(userId, "Ride confirmed", rideId);
 *
 * // Within a transaction
 * await prisma.$transaction(async (tx) => {
 *   await postNotification(userId, "Message", rideId, tx);
 * });
 */
const postNotification = async (
  userId,
  messageText,
  rideId = null,
  txClient = undefined,
) => {
  try {
    // Use provided transaction client or default prisma
    const client = txClient || prisma;

    // Create notification instance using OOP pattern
    const notification = new Notification(userId, messageText, rideId);

    // Save to database
    const savedNotification = await notification.save(client);

    // Emit via Socket.IO (emit asynchronously to avoid blocking transaction)
    // Use setImmediate to ensure this happens after transaction commits
    // setImmediate(() => {
    //   notification.emit(io);
    // });

    return savedNotification;
  } catch (err) {
    console.error("Error in postNotification:", err);
    throw err;
  }
};

/**
 * @desc    Create and send notifications in batch
 * @param   {Array<{userId, messageText, rideId}>} notificationsList - Array of notification objects
 * @param   {object} txClient - Prisma transaction client (optional)
 * @returns {Promise<Array>} Array of created notifications
 *
 * @example
 * await postNotifications([
 *   { userId: 'user1', messageText: 'Message 1', rideId: 'ride1' },
 *   { userId: 'user2', messageText: 'Message 2', rideId: 'ride1' },
 * ]);
 */
const postNotifications = async (notificationsList, txClient = undefined) => {
  try {
    const client = txClient || prisma;
    const savingPromises = notificationsList.map(
      ({ userId, messageText, rideId }) =>
        postNotification(userId, messageText, rideId, client),
    );

    const savedNotifications = await Promise.all(savingPromises);

    // Emit all notifications via Socket.IO (asynchronously)
    setImmediate(() => {
      savedNotifications.forEach((notification) => {
        const notifObj = new Notification(
          notification.userId,
          notification.messageText,
          notification.rideId,
        );
        if (io) notifObj.emit(io);
      });
    });

    return savedNotifications;
  } catch (err) {
    console.error("Error in postNotifications:", err);
    throw err;
  }
};

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
  Notification,
  postNotification,
  postNotifications,
  getNotifications,
  markAsRead,
};
