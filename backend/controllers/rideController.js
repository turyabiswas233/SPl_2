/**
 * Ride Controller
 * Handles ride creation, browsing, and management using Prisma ORM
 */

const prisma = require("../db/prismaClient");
const crypto = require("crypto");
const { v4: uuidv4 } = require("uuid");
const { clog } = require("../utils/log");
const { log } = require("console");
const {
  postNotification,
  postNotifications,
} = require("./notificationController");
const { io } = require("../index");
/**
 * @swagger
 * /api/v1/rides:
 *   post:
 *     summary: Create a new ride
 *     tags: [Rides]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - startLat
 *               - startLng
 *               - destination
 *               - destLat
 *               - destLng
 *               - maxSeats
 *             properties:
 *               startLat:
 *                 type: number
 *                 description: Starting latitude
 *               startLng:
 *                 type: number
 *                 description: Starting longitude
 *               destination:
 *                 type: string
 *                 description: Destination name
 *               destLat:
 *                 type: number
 *                 description: Destination latitude
 *               destLng:
 *                 type: number
 *                 description: Destination longitude
 *               maxSeats:
 *                 type: integer
 *                 description: Maximum number of seats
 *               preferredGender:
 *                 type: string
 *                 enum: [male, female, other]
 *                 description: Preferred gender for passengers
 *     responses:
 *       201:
 *         description: Ride created successfully
 *       400:
 *         description: Validation error
 *       500:
 *         description: Server error
 */

// @desc    Create a new ride
// @route   POST /api/rides
// @access  Private
const createRide = async (req, res) => {
  const {
    startLat,
    startLng,
    destination,
    preferredGender,
    destLat,
    destLng,
    maxSeats,
  } = req.body;
  const initiator_id = req.user.userId;

  try {
    const qrCode = crypto.randomBytes(16).toString("hex");
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const rideId = uuidv4();
    const participantId = initiator_id;
    const rideParticipantId = uuidv4();

    // Use transaction to create ride, participant, and notification atomically
    const result = await prisma.$transaction(async (tx) => {
      const startLocation = req.body.startLocation;
      const destLocation = req.body.destination;

      const findIfRideExists = await tx.ride.findFirst({
        where: {
          initiatorId: initiator_id,
          status: {
            in: ["in_progress"],
          },
        },
      });

      if (findIfRideExists) {
        throw new Error(
          "You already have an active ride. Please complete or cancel it before creating a new one.",
        );
      }

      // Create ride
      const ride = await tx.ride.create({
        data: {
          rideId,
          initiatorId: initiator_id,
          startLocation: startLocation,
          startLat: startLat,
          startLng: startLng,
          destinationName: destLocation,
          destLat: destLat,
          destLng: destLng,
          tripQrCode: qrCode,
          tripOtp: otp,
          preferredGender: preferredGender || "other",
          maxSeats: maxSeats + 1,
          status: "open",
        },
      });

      // Create ride participant (initiator joins their own ride)
      const participant = await tx.rideParticipant.create({
        data: {
          rideParticipantId,
          rideId,
          userId: initiator_id,
          participantId,
          meetingLat: startLat,
          meetingLng: startLng,
          hasMetBoolean: true,
          metAt: new Date(),
        },
      });

      // Create notification using notification service
      const notificationMessage = `Your ride from ${startLocation} to ${destination} has been created successfully.`;
      await postNotification(initiator_id, notificationMessage, rideId, tx);

      if (io)
        io.on("connecion", (socket) => {
          socket.emit("rideCreated", {
            rideId: ride.rideId,
          });
        });

      return {
        ...ride,
        participants: [participant],
      };
    });

    res.status(201).json({
      success: true,
      data: result,
    });
  } catch (err) {
    clog("Create ride error:" + err, "error");
    res.status(500).json({
      success: false,
      message: "Error creating ride",
      error: err.message,
    });
  }
};

/**
 * @swagger
 * /api/v1/rides:
 *   get:
 *     summary: Get all available rides
 *     tags: [Rides]
 *     parameters:
 *       - in: query
 *         name: gender_filter
 *         schema:
 *           type: string
 *           enum: [male, female, other]
 *         description: Filter by preferred gender
 *       - in: query
 *         name: min_seats
 *         schema:
 *           type: integer
 *         description: Minimum number of seats required
 *       - in: query
 *         name: destination
 *         schema:
 *           type: string
 *         description: Filter by destination name
 *     responses:
 *       200:
 *         description: List of rides
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 count:
 *                   type: integer
 *                 data:
 *                   type: array
 *                   items:
 *                     type: object
 *       500:
 *         description: Server error
 */

// @desc    Browse available rides
// @route   GET /api/rides
// @access  Public
const getRides = async (req, res) => {
  const { gender_filter, min_seats } = req.query;

  try {
    // Build where clause based on filters
    const where = {};

    // Filter by preferred gender
    if (gender_filter && gender_filter !== "other") {
      where.OR = [
        { preferredGender: gender_filter },
        { preferredGender: "other" },
      ];
    }

    // Filter by minimum seats
    if (min_seats) {
      where.maxSeats = {
        gte: parseInt(min_seats),
      };
    }

    // Fetch rides with initiator info and participant count
    const rides = await prisma.ride.findMany({
      where,
      include: {
        initiator: {
          select: {
            fullName: true,
            phoneNumber: true,
          },
        },
        participants: true,
      },
      orderBy: {
        createdAt: "desc",
      },
    });

    // Format response to match old structure
    const formattedRides = rides.map((ride) => ({
      ...ride,
      initiator_name: ride.initiator.fullName,
      initiator_phone: ride.initiator.phoneNumber,
      current_passengers: ride.participants.length,
    }));

    res.status(200).json({
      success: true,
      count: formattedRides.length,
      data: formattedRides,
    });
  } catch (err) {
    console.error("Get rides error:", err);
    res.status(500).json({
      success: false,
      message: "Error fetching rides",
      error: err.message,
    });
  }
};

/**
 * @swagger
 * /api/v1/rides/{ride_id}:
 *   get:
 *     summary: Get ride details by ID
 *     tags: [Rides]
 *     parameters:
 *       - in: path
 *         name: ride_id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Ride ID
 *     responses:
 *       200:
 *         description: Ride details
 *       404:
 *         description: Ride not found
 *       500:
 *         description: Server error
 */

// @desc    Get specific ride details
// @route   GET /api/rides/:ride_id
// @access  Public
const getRideById = async (req, res) => {
  const { ride_id } = req.params;

  try {
    const ride = await prisma.ride.findUnique({
      where: { rideId: ride_id },
      include: {
        initiator: {
          select: {
            fullName: true,
            phoneNumber: true,
            userId: true,
          },
        },
        participants: {
          include: {
            user: {
              select: {
                fullName: true,
                phoneNumber: true,
                userId: true,
              },
            },
          },
        },
      },
    });

    if (!ride) {
      return res.status(404).json({
        success: false,
        message: "Ride not found.",
      });
    }

    // Format participants data
    const formattedParticipants = ride.participants.map((rp) => ({
      ...rp,
      fullName: rp.user.fullName,
      phoneNumber: rp.user.phoneNumber,
      userIdFromParticipant: rp.user.userId,
    }));

    res.status(200).json({
      success: true,
      data: {
        ride: {
          ...ride,
          initiator_name: ride.initiator.fullName,
          initiator_phone: ride.initiator.phoneNumber,
        },
        participants: formattedParticipants,
      },
    });
  } catch (err) {
    console.error("Get ride by ID error:", err);
    res.status(500).json({
      success: false,
      message: "Error fetching ride details",
      error: err.message,
    });
  }
};

/**
 * @swagger
 * /api/v1/rides/nearby:
 *   get:
 *     summary: Get nearby rides
 *     tags: [Rides]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: lng
 *         required: true
 *         schema:
 *           type: number
 *         description: User's longitude
 *       - in: query
 *         name: lat
 *         required: true
 *         schema:
 *           type: number
 *         description: User's latitude
 *     responses:
 *       200:
 *         description: List of nearby rides
 *       400:
 *         description: Missing coordinates
 *       500:
 *         description: Server error
 */

// @desc    Find nearby open rides
// @route   GET /api/rides/nearby
// @access  Private
// @query   lng, lat (user's current location)
const getNearbyRides = async (req, res) => {
  const { gender_filter, min_seats, lng, lat } = req.query;

  try {
    const currentUserId = req.user?.userId;

    // Validate coordinates
    if (!lng || !lat) {
      return res.status(400).json({
        success: false,
        message: "Missing required query parameters: lng, lat",
      });
    }

    const userLng = parseFloat(lng);
    const userLat = parseFloat(lat);

    if (isNaN(userLng) || isNaN(userLat)) {
      return res.status(400).json({
        success: false,
        message: "Invalid coordinates format",
      });
    }

    const where = {};

    // Filter by preferred gender
    if (gender_filter && gender_filter !== "other") {
      where.OR = [
        { preferredGender: gender_filter },
        { preferredGender: "other" },
      ];
    }

    // Filter by minimum seats
    if (min_seats) {
      where.maxSeats = {
        gte: parseInt(min_seats),
      };
    }

    // Get all open rides
    const openRides = await prisma.ride.findMany({
      where: {
        status: "open",
        ...where,
        requests: {
          none: {
            requesterId: currentUserId,
          },
        },
      },
      include: {
        initiator: {
          select: {
            fullName: true,
            phoneNumber: true,
            userId: true,
          },
        },
        participants: true,
      },
    });

    log("Total open rides found: " + openRides.length);

    // Helper function to calculate distance using Haversine formula
    const calculateDistance = (lat1, lng1, lat2, lng2) => {
      const R = 6371000; // Earth's radius in meters
      const dLat = (lat2 - lat1) * (Math.PI / 180);
      const dLng = (lng2 - lng1) * (Math.PI / 180);
      const a =
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(lat1 * (Math.PI / 180)) *
          Math.cos(lat2 * (Math.PI / 180)) *
          Math.sin(dLng / 2) *
          Math.sin(dLng / 2);
      const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
      console.log(R * c);
      return R * c; // Distance in meters
    };

    // Filter nearby rides within 2000m radius and exclude current user's rides
    const nearbyRides = openRides
      .filter((ride) => {
        // Exclude rides created by the current user
        if (ride.initiatorId === currentUserId) {
          return false;
        }
        // Calculate distance from user location to ride start location
        const distance = calculateDistance(
          userLat,
          userLng,
          ride.startLat,
          ride.startLng,
        );
        // Keep rides within 2000m radius
        return distance <= 2000; // 2000 meters = 2 km
      })
      .map((ride) => ({
        ...ride,
        initiatorName: ride.initiator.fullName,
        initiatorPhone: ride.initiator.phoneNumber,
        current_passengers: ride.participants.length,
        available_seats: ride.maxSeats - ride.participants.length,
        distance: Number(
          calculateDistance(
            userLat,
            userLng,
            ride.startLat,
            ride.startLng,
          ).toFixed(2),
        ), // Distance in meters, rounded to 2 decimals
      }));
    const sortedNearbyRides = nearbyRides.sort(
      (a, b) => a.distance - b.distance,
    );
    const ridesWithTravelDistance = await Promise.all(
      sortedNearbyRides.map(async (ride) => {
        const body = await fetch(
          process.env.API_URL +
            "/api/v1/mapbox/route?startLng=" +
            ride.startLng +
            "&startLat=" +
            ride.startLat +
            "&destLng=" +
            ride.destLng +
            "&destLat=" +
            ride.destLat +
            "&steps=false&geometries=geojson",
          {
            method: "GET",
          },
        ).then((res) => res.json());

        return {
          ...ride,
          travelDistance: body?.distance, // Distance in meters
        };
      }),
    );
    res.status(200).json({
      success: true,
      count: ridesWithTravelDistance.length,
      data: ridesWithTravelDistance,
    });
  } catch (err) {
    console.error("Get nearby rides error:", err);
    res.status(500).json({
      success: false,
      message: "Error fetching nearby rides",
      error: err.message,
    });
  }
};

/**
 * @swagger
 * /api/v1/rides/{ride_id}/complete:
 *   post:
 *     summary: Complete a ride
 *     tags: [Rides]
 *     parameters:
 *       - in: path
 *         name: ride_id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Ride ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - initiator_id
 *             properties:
 *               initiator_id:
 *                 type: string
 *                 format: uuid
 *                 description: Initiator user ID
 *               total_fare:
 *                 type: number
 *                 description: Total fare amount
 *     responses:
 *       200:
 *         description: Ride completed successfully
 *       500:
 *         description: Server error
 */

// @desc    Complete a trip
// @route   POST /api/rides/:ride_id/complete
// @access  Private
const completeRide = async (req, res) => {
  const { ride_id } = req.params;
  const { initiator_id, total_fare } = req.body;

  try {
    // Use transaction for atomic operations
    const result = await prisma.$transaction(async (tx) => {
      // Verify initiator
      const rideCheck = await tx.ride.findFirst({
        where: {
          rideId: ride_id,
          initiatorId: initiator_id,
        },
      });

      if (!rideCheck) {
        throw new Error("Only the initiator can complete the ride.");
      }

      // Update ride status to completed
      await tx.ride.update({
        where: { rideId: ride_id },
        data: { status: "completed" },
      });

      // Get all participants
      const participants = await tx.rideParticipant.findMany({
        where: { rideId: ride_id },
      });

      // Calculate and create fares if total_fare provided
      if (total_fare) {
        const splitAmount = (total_fare / participants.length).toFixed(2);

        const farePromises = participants.map((participant) =>
          tx.fare.create({
            data: {
              fareId: uuidv4(),
              rideId: ride_id,
              userId: participant.userId,
              amount: parseFloat(splitAmount),
            },
          }),
        );

        await Promise.all(farePromises);
      }

      // Notify all participants using notification service
      const notificationsList = participants.map((participant) => ({
        userId: participant.userId,
        messageText: total_fare
          ? `Trip completed! Your share: $${(total_fare / participants.length).toFixed(2)}. Please rate your co-passengers.`
          : `Trip completed! Please rate your co-passengers.`,
        rideId: ride_id,
      }));

      await postNotifications(notificationsList, tx);

      return participants;
    });

    res.status(200).json({
      success: true,
      message: "Trip completed successfully.",
    });
  } catch (err) {
    console.error("Complete ride error:", err);
    res.status(500).json({
      success: false,
      message: err.message || "Error completing ride",
      error: err.message,
    });
  }
};

/**
 * @swagger
 * /api/v1/rides/{ride_id}/start:
 *   post:
 *     summary: Start a ride
 *     tags: [Rides]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: ride_id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Ride ID
 *     responses:
 *       200:
 *         description: Ride started successfully
 *       401:
 *         description: Authentication required
 *       500:
 *         description: Server error
 */

// @desc    Set ride status to in_progress
// @route   POST /api/rides/:ride_id/start
// @access  Private
const startRide = async (req, res) => {
  const { ride_id } = req.params;
  const initiator_id = req.user?.userId;

  console.log("Start ride request for ride_id:", ride_id, "by user:", initiator_id);

  if (!initiator_id) {
    return res.status(401).json({
      success: false,
      message: "Authentication required.",
    });
  }

  try {
    // Use transaction for atomic operations
    const result = await prisma.$transaction(async (tx) => {
      // Verify initiator and check ride status
      const rides = await tx.ride.findMany({
        where: {
          initiatorId: initiator_id,
        },
        select: {
          status: true,
          rideId: true,
        },
      });

      if (rides.find((ride) => ride.status === "in_progress")) {
        throw new Error(
          "You already have a ride in progress. Please complete it before starting another.",
        );
      }
      const rideCheck = rides.find((ride) => ride.rideId === ride_id);

      if (!rideCheck) {
        throw new Error("Only the initiator can start the ride.");
      }

      if (rideCheck.status === "completed") {
        throw new Error("Completed rides cannot be started.");
      }

      if (rideCheck.status === "in_progress") {
        throw new Error("Ride is already in progress.");
      }

      if (rideCheck.status === "cancelled") {
        throw new Error("Cancelled rides cannot be started.");
      }

      // Update ride status to in_progress
      await tx.ride.update({
        where: { rideId: ride_id },
        data: { status: "in_progress" },
      });

      // Get all participants
      const participants = await tx.rideParticipant.findMany({
        where: { rideId: ride_id },
      });

      // Notify all participants about ride start using notification service
      const notificationsList = participants.map((participant) => ({
        userId: participant.userId,
        messageText: "Trip is now in progress. Please be ready!",
        rideId: ride_id,
      }));

      await postNotifications(notificationsList, tx);

      return rideCheck;
    });

    res.status(200).json({
      success: true,
      message: "Trip started successfully.",
      data: result,
    });
  } catch (err) {
    console.error("Start ride error:", err);
    res.status(500).json({
      success: false,
      message: err.message || "Error starting ride",
      error: err.message,
    });
  }
};

/**
 * @swagger
 * /api/v1/rides/{ride_id}/cancel:
 *   patch:
 *     summary: Cancel a ride
 *     tags: [Rides]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: ride_id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Ride ID
 *     responses:
 *       200:
 *         description: Ride cancelled successfully
 *       401:
 *         description: Authentication required
 *       500:
 *         description: Server error
 */

// @desc    Cancel a trip
// @route   POST /api/rides/:ride_id/cancel
// @access  Private
const cancelRide = async (req, res) => {
  const { ride_id } = req.params;
  const initiator_id = req.user?.userId;

  if (!initiator_id) {
    return res.status(401).json({
      success: false,
      message: "Authentication required.",
    });
  }

  try {
    // Use transaction for atomic operations
    const result = await prisma.$transaction(async (tx) => {
      // Verify initiator and check ride status
      const rideCheck = await tx.ride.findFirst({
        where: {
          rideId: ride_id,
          initiatorId: initiator_id,
        },
      });

      if (!rideCheck) {
        throw new Error("Only the initiator can cancel the ride.");
      }

      if (rideCheck.status === "completed") {
        throw new Error("Completed rides cannot be cancelled.");
      }

      if (rideCheck.status === "cancelled") {
        throw new Error("Ride is already cancelled.");
      }

      // Update ride status to cancelled
      await tx.ride.update({
        where: { rideId: ride_id },
        data: { status: "cancelled" },
      });

      // Get all participants
      const participants = await tx.rideParticipant.findMany({
        where: { rideId: ride_id },
      });

      // Notify all participants about cancellation using notification service
      const notificationsList = participants.map((participant) => ({
        userId: participant.userId,
        messageText: "Trip cancelled by the initiator.",
        rideId: ride_id,
      }));

      await postNotifications(notificationsList, tx);

      return rideCheck;
    });

    res.status(200).json({
      success: true,
      message: "Trip cancelled successfully.",
    });
  } catch (err) {
    console.error("Cancel ride error:", err);
    res.status(500).json({
      success: false,
      message: err.message || "Error cancelling ride",
      error: err.message,
    });
  }
};

module.exports = {
  createRide,
  getRides,
  getRideById,
  getNearbyRides,
  startRide,
  completeRide,
  cancelRide,
};
