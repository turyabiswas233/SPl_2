const prisma = require("../db/prismaClient");
const { v4: uuidv4 } = require("uuid");
const {
  postNotification,
  postNotifications,
} = require("./notificationController");

// @desc    Join a ride by scanning QR code
// @route   POST /api/handshake/join-by-qr
// @access  Private
const joinByQr = async (req, res) => {
  const { tripQrCode, userId, met } = req.body;

  try {
    // Use transaction for atomic operations
    const result = await prisma.$transaction(async (tx) => {
      // Find ride by QR code
      const ride = await tx.ride.findUnique({
        where: { tripQrCode },
        include: {
          participants: true,
          initiator: {
            select: {
              fullName: true,
            },
          },
        },
      });

      if (!ride) {
        return res.status(404).json({
          success: false,
          message: "Ride not found for the provided QR code.",
        });
      }

      if (ride.status !== "open") {
        return res.status(400).json({
          success: false,
          message: "Ride is not available for joining.",
        });
      }

      // Check if user is already a participant
      const existingParticipant = ride.participants.find(
        (p) => p.userId === userId,
      );

      if (existingParticipant) {
        // Check if user exists
        const user = await tx.user.findUnique({
          where: { userId },
        });

        if (!user) {
          return res.status(404).json({
            success: false,
            message: "User not found.",
          });
        }

        // return the info
        return {
          ride: {
            rideId: ride.rideId,
            destinationName: ride.destinationName,
            initiatorName: ride.initiator.fullName,
          },
          participant: {
            userId,
            fullName: user.fullName,
          },
          message: "You have already joined this ride.",
        };
      }

      // Check if seats are available
      if (ride.participants.length > ride.maxSeats) {
        return res.status(400).json({
          success: false,
          message: "No seats available in this ride.",
        });
      }

      // Check if user exists
      const user = await tx.user.findUnique({
        where: { userId },
      });

      if (!user) {
        return res.status(404).json({
          success: false,
          message: "User not found.",
        });
      }

      // Create ride participant
      const rideParticipantId = uuidv4();
      await tx.rideParticipant.create({
        data: {
          rideParticipantId,
          rideId: ride.rideId,
          userId,
          participantId: userId,
          meetingLat: met?.lat || null,
          meetingLng: met?.lng || null,
          hasMetBoolean: false, // Set to false initially, verified later
        },
      });

      // Update ride requests: accept the user's request if exists, reject others
      const allRequests = await tx.rideRequest.findMany({
        where: {
          rideId: ride.rideId,
          status: "pending",
        },
      });

      // Accept user's request if exists
      const userRequest = allRequests.find((r) => r.requesterId === userId);
      if (userRequest) {
        await tx.rideRequest.update({
          where: { requestId: userRequest.requestId },
          data: { status: "accepted" },
        });
      }

      // Reject all other pending requests
      const otherRequests = allRequests.filter((r) => r.requesterId !== userId);
      if (otherRequests.length > 0) {
        await Promise.all(
          otherRequests.map((request) =>
            tx.rideRequest.update({
              where: { requestId: request.requestId },
              data: { status: "rejected" },
            }),
          ),
        );
      }

      // Notify the user
      const userNotificationMessage = `You have successfully joined the ride to ${ride.destinationName} initiated by ${ride.initiator.fullName}.`;
      await postNotification(userId, userNotificationMessage, ride.rideId, tx);

      // Notify the initiator
      const initiatorNotificationMessage = `${user.fullName} has joined your ride to ${ride.destinationName} by scanning the QR code.`;
      await postNotification(
        ride.initiatorId,
        initiatorNotificationMessage,
        ride.rideId,
        tx,
      );

      // Notify rejected requesters if any
      if (otherRequests.length > 0) {
        const rejectedUserIds = await Promise.all(
          otherRequests.map(async (request) => {
            const rejectedUser = await tx.user.findUnique({
              where: { userId: request.requesterId },
            });
            return rejectedUser ? request.requesterId : null;
          }),
        );

        const notificationsList = rejectedUserIds
          .filter((id) => id !== null)
          .map((rejectedUserId) => ({
            userId: rejectedUserId,
            messageText: `Your request to join the ride to ${ride.destinationName} was not accepted as someone else joined via QR code.`,
            rideId: ride.rideId,
          }));

        if (notificationsList.length > 0) {
          await postNotifications(notificationsList, tx);
        }
      }

      return {
        ride: {
          rideId: ride.rideId,
          destinationName: ride.destinationName,
          initiatorName: ride.initiator.fullName,
        },
        participant: {
          userId,
          fullName: user.fullName,
        },
        message: "Successfully joined the ride.",
      };
    });

    res.status(200).json({
      success: true,
      message: result.message,
      data: {
        ride: result.ride,
        participant: result.participant,
      },
    });
  } catch (err) {
    console.error("Join by QR error:", err);
    res.status(500).json({
      success: false,
      message: err?.message || "Error joining ride",
      error: err,
    });
  }
};

// @desc    Verify handshake with QR code
// @route   POST /api/handshake/verify
// @access  Private
const verifyHandshake = async (req, res) => {
  const { ride_id, user_id, otp } = req.body;

  try {
    // Fetch ride and participant meeting coordinates
    const rideParticipant = await prisma.rideParticipant.findFirst({
      where: {
        rideId: ride_id,
        userId: user_id,
      },
      include: {
        ride: {
          select: {
            tripOtp: true,
          },
        },
      },
    });

    if (!rideParticipant) {
      return res.status(404).json({
        success: false,
        message: "Ride or participant not found.",
      });
    }

    // 1. Check Ride OTP
    if (rideParticipant.ride.tripOtp !== otp) {
      return res.status(401).json({
        success: false,
        message: "Invalid OTP.",
      });
    }

    // 2. Update Status
    const result = await prisma.rideParticipant.update({
      where: {
        rideParticipantId: rideParticipant.rideParticipantId,
      },
      data: {
        hasMetBoolean: true,
        metAt: new Date(),
      },
    });

    res.status(200).json({
      success: true,
      message: "Handshake verified successfully!",
      data: result,
    });
  } catch (err) {
    console.error("Verify handshake error:", err);
    res.status(500).json({
      success: false,
      message: "Error verifying handshake",
      error: err.message,
    });
  }
};

module.exports = {
  joinByQr,
  verifyHandshake,
};
