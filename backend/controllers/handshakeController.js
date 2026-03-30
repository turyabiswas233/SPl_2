/**
 * Handshake Controller
 * Handles QR code verification and meeting confirmation using Prisma ORM
 */

const prisma = require('../db/prismaClient');
const { getDistance } = require('geolib');

// @desc    Verify handshake with QR code
// @route   POST /api/handshake/verify
// @access  Private
const verifyHandshake = async (req, res) => {
  const { ride_id, user_id, scanned_qr_code, current_lat, current_lng } = req.body;

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
            tripQrCode: true,
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

    // 1. Check QR Code
    if (rideParticipant.ride.tripQrCode !== scanned_qr_code) {
      return res.status(401).json({
        success: false,
        message: "Invalid QR Code.",
      });
    }

    // 2. Geography Check
    if (rideParticipant.meetingLat && rideParticipant.meetingLng) {
      const distance = getDistance(
        { latitude: current_lat, longitude: current_lng },
        { latitude: rideParticipant.meetingLat, longitude: rideParticipant.meetingLng }
      );

      // Distance is in meters. Limit: 100 meters
      if (distance > 100) {
        return res.status(400).json({
          success: false,
          message: `Too far! You are ${distance}m away.`,
        });
      }
    }

    // 3. Update Status
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
  verifyHandshake
};
