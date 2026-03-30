/**
 * Message Controller
 * Handles in-ride chat messages using Prisma ORM
 */

const prisma = require("../db/prismaClient");
const { v4: uuidv4 } = require("uuid");

// @desc    Send message in ride chat
// @route   POST /api/rides/:ride_id/messages
// @access  Private
const sendMessage = async (req, res) => {
  const { ride_id } = req.params;
  const { sender_id, message_text } = req.body;

  try {
    // Verify sender is part of the ride
    const participantCheck =
      (await prisma.rideRequest.findFirst({
        where: {
          rideId: ride_id,
          requesterId: sender_id,
        },
      })) ||
      (await prisma.ride.findFirst({
        where: {
          rideId: ride_id,
          initiatorId: sender_id,
        },
      }));

    if (!participantCheck) {
      return res.status(403).json({
        success: false,
        message: "You are not part of this ride.",
      });
    }

    const messageId = uuidv4();
const createdAt = new Date();
const offsetMs = 6 * 60 * 60 * 1000; // 6 hours in milliseconds
const gmtPlus6 = new Date(createdAt.getTime() + offsetMs);
    // Create message
    const result = await prisma.message.create({
      data: {
        messageId,
        rideId: ride_id,
        senderId: sender_id,
        messageText: message_text,
        createdAt: gmtPlus6.toISOString(),
      },
    });

    res.status(201).json({
      success: true,
      data: result,
    });
  } catch (err) {
    console.error("Send message error:", err);
    res.status(500).json({
      success: false,
      message: "Error sending message",
      error: err.message,
    });
  }
};

// @desc    Get ride messages
// @route   GET /api/rides/:ride_id/messages
// @access  Private
const getMessages = async (req, res) => {
  const { ride_id } = req.params;

  try {
    const messages = await prisma.message.findMany({
      where: { rideId: ride_id },
      include: {
        sender: {
          select: {
            fullName: true,
            userId: true,
          },
        },
      },
      orderBy: {
        createdAt: "asc",
      },
    });

    res.status(200).json({
      success: true,
      count: messages.length,
      data: messages,
    });
  } catch (err) {
    console.error("Get messages error:", err);
    res.status(500).json({
      success: false,
      message: "Error fetching messages",
      error: err.message,
    });
  }
};

module.exports = {
  sendMessage,
  getMessages,
};
