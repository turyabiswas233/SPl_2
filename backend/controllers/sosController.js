/**
 * SOS Controller
 * Handles emergency alerts using Prisma ORM
 */

const prisma = require('../db/prismaClient');
const { v4: uuidv4 } = require('uuid');

// @desc    Create SOS alert
// @route   POST /api/sos
// @access  Private
const createSOSAlert = async (req, res) => {
  const { ride_id, user_id, alert_type, latitude, longitude } = req.body;

  try {
    // Use transaction
    const result = await prisma.$transaction(async (tx) => {
      const alertId = uuidv4();

      // Create SOS alert
      const alert = await tx.sOSAlert.create({
        data: {
          alertId,
          rideId: ride_id,
          userId: user_id,
          alertType: alert_type,
          latitude: parseFloat(latitude),
          longitude: parseFloat(longitude),
          status: "active",
        },
      });

      // Get all other participants in the ride
      const participants = await tx.rideParticipant.findMany({
        where: {
          rideId: ride_id,
          userId: {
            not: user_id,
          },
        },
      });

      // Notify all other participants
      const notificationPromises = participants.map((participant) => {
        const notificationId = uuidv4();
        const notificationMessage = `🚨 SOS Alert: ${alert_type} reported in your ride!`;

        return tx.notification.create({
          data: {
            notificationId,
            userId: participant.userId,
            rideId: ride_id,
            messageText: notificationMessage,
          },
        });
      });

      await Promise.all(notificationPromises);

      return alert;
    });

    res.status(201).json({
      success: true,
      data: result,
    });
  } catch (err) {
    console.error("Create SOS alert error:", err);
    res.status(500).json({
      success: false,
      message: "Error creating SOS alert",
      error: err.message,
    });
  }
};

module.exports = {
  createSOSAlert
};
