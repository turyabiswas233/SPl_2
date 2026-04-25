/**
 * Ride Request Controller
 * Handles ride join requests and approvals using Prisma ORM
 */

const prisma = require('../db/prismaClient');
const { v4: uuidv4 } = require('uuid');
const { clog } = require('../utils/log');
const { postNotification } = require('./notificationController');

// @desc    Request to join a ride
// @route   POST /api/rides/:ride_id/requests
// @access  Private
const createRideRequest = async (req, res) => {
  const { ride_id } = req.params;
  const  requester_id  = req.user.userId;

  try {
    // Use transaction
    const result = await prisma.$transaction(async (tx) => {
      // Check if ride is still open and get ride details
      const ride = await tx.ride.findFirst({
        where: {
          rideId: ride_id,
          status: "open",
        },
        include: {
          initiator: {
            select: {
              userId: true,
              fullName: true,
            },
          },
        },
      });

      if (!ride) {
        throw new Error("Ride not available.");
      }

      // Verify requester exists
      const requester = await tx.user.findUnique({
        where: { userId: requester_id },
      });

      if (!requester) {
        throw new Error("User not found.");
      }

      const requestId = uuidv4();
      const notificationId = uuidv4();

      // check if already requested
      const existingRequest = await tx.rideRequest.findFirst({
        where: {
          rideId: ride_id,
          requesterId: requester_id,
        },
      });

      if (existingRequest) {
        clog(`User ${requester_id} has already requested to join ride ${ride_id}`, "warn");
        throw new Error("You have already requested to join this ride.");
      }

      // Create request
      const rideRequest = await tx.rideRequest.create({
        data: {
          requestId,
          rideId: ride_id,
          requesterId: requester_id,
          status: "pending",
        },
      });

      // Notify ride initiator using notification service
      const notificationMessage = `${requester.fullName} has requested to join your ride to ${ride.destinationName}.`;
      await postNotification(ride.initiatorId, notificationMessage, ride_id, tx);

      return rideRequest;
    });

    res.status(201).json({
      success: true,
      data: result,
    });
  } catch (err) {
    console.error("Create ride request error:", err);
    res.status(500).json({
      success: false,
      message: err.message || "Error creating ride request",
      error: err.message,
    });
  }
};

// @desc    Accept or reject ride request
// @route   PUT /api/rides/:ride_id/requests/:request_id
// @access  Private
const updateRideRequest = async (req, res) => {
  const { ride_id, request_id } = req.params;
  const { action, meetingLat, meetingLng } = req.body;

  try {
    // Use transaction
    const result = await prisma.$transaction(async (tx) => {
      // Get request details
      const rideRequest = await tx.rideRequest.findFirst({
        where: {
          requestId: request_id,
          rideId: ride_id,
          status: "pending",
        },
        include: {
          ride: {
            select: {
              destinationName: true,
            },
          },
          requester: {
            select: {
              fullName: true,
            },
          },
        },
      });

      if (!rideRequest) {
        throw new Error("Request not found or already processed.");
      }

      if (action === "accept") {
        // Update request status
        await tx.rideRequest.update({
          where: { requestId: request_id },
          data: { status: "accepted" },
        });

        // Add to ride participants
        const rideParticipantId = uuidv4();
        await tx.rideParticipant.create({
          data: {
            rideParticipantId,
            rideId: ride_id,
            userId: rideRequest.requesterId,
            participantId: rideRequest.requesterId,
            meetingLat: meetingLat ? parseFloat(meetingLat) : null,
            meetingLng: meetingLng ? parseFloat(meetingLng) : null,
            hasMetBoolean: false,
          },
        });

        // Notify requester using notification service
        const notificationMessage = `Your request to join the ride to ${rideRequest.ride.destinationName} has been accepted!`;
        await postNotification(rideRequest.requesterId, notificationMessage, ride_id, tx);
      } else if (action === "reject") {
        // Update request status to rejected
        await tx.rideRequest.update({
          where: { requestId: request_id },
          data: { status: "rejected" },
        });

        // Notify requester using notification service
        const notificationMessage = `Your request to join the ride to ${rideRequest.ride.destinationName} was not accepted.`;
        await postNotification(rideRequest.requesterId, notificationMessage, ride_id, tx);
      }

      return rideRequest;
    });

    res.status(200).json({
      success: true,
      message: `Request ${action}ed successfully.`,
    });
  } catch (err) {
    console.error("Update ride request error:", err);
    res.status(500).json({
      success: false,
      message: err.message || "Error updating ride request",
      error: err.message,
    });
  }
};

module.exports = {
  createRideRequest,
  updateRideRequest,
};
