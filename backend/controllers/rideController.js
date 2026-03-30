/**
 * Ride Controller
 * Handles ride creation, browsing, and management using Prisma ORM
 */

const prisma = require("../db/prismaClient");
const crypto = require("crypto");
const { v4: uuidv4 } = require("uuid");
const { clog } = require("../utils/log");
const { log } = require("console");

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
    const notificationId = uuidv4();

    // Use transaction to create ride, participant, and notification atomically
    const result = await prisma.$transaction(async (tx) => {
      // retrive mapbox place name from start cords
      const place = await fetch(
        process.env.API_URL +
          "/api/v1/mapbox/place-name?lng=" +
          startLng +
          "&lat=" +
          startLat,
        {
          method: "GET",
        },
      ).then((res) => res.json());
      const startLocation = place.place_name || req.body.startLocation;
      // Create ride
      const ride = await tx.ride.create({
        data: {
          rideId,
          initiatorId: initiator_id,
          startLocation: startLocation,
          startLat: startLat,
          startLng: startLng,
          destinationName: destination,
          destLat: destLat,
          destLng: destLng,
          tripQrCode: qrCode,
          tripOtp: otp,
          preferredGender: preferredGender || "any",
          maxSeats: maxSeats,
          status: "open",
        },
      });

      // Create ride participant (initiator joins their own ride)
      await tx.rideParticipant.create({
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

      // Create notification
      const notificationMessage = `Your ride from ${startLocation} to ${destination} has been created successfully.`;
      await tx.notification.create({
        data: {
          notificationId,
          userId: initiator_id,
          rideId,
          messageText: notificationMessage,
        },
      });

      return ride;
    });

    res.status(201).json({
      success: true,
      data: result,
    });
  } catch (err) {
    clog("Create ride error:"+ err, "error");
    res.status(500).json({
      success: false,
      message: "Error creating ride",
      error: err.message,
    });
  }
};

// @desc    Browse available rides
// @route   GET /api/rides
// @access  Public
const getRides = async (req, res) => {
  const { gender_filter, min_seats, destination } = req.query;

  try {
    // Build where clause based on filters
    const where = {};

    // Filter by preferred gender
    if (gender_filter && gender_filter !== "any") {
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

    // Filter by destination
    if (destination) {
      where.destinationName = {
        contains: destination,
        mode: "insensitive",
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
// @desc    Find nearby open rides
// @route   GET /api/rides/nearby
// @access  Private
// @query   lng, lat (user's current location)
const getNearbyRides = async (req, res) => {
  const { lng, lat } = req.query;
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

  try {
    // Get all open rides
    const openRides = await prisma.ride.findMany({
      where: {
        status: "open",
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

    log("Total open rides found: " + openRides.toString());

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
      return R * c; // Distance in meters
    };

    // Filter nearby rides within 500m radius and exclude current user's rides
    const nearbyRides = openRides
      .filter((ride) => {
        // Exclude rides created by the current user
        if (currentUserId && ride.initiatorId === currentUserId) {
          return false;
        }
        // Calculate distance from user location to ride start location
        const distance = calculateDistance(
          userLat,
          userLng,
          ride.startLat,
          ride.startLng,
        );
        // Keep rides within 500m radius
        return distance <= 500;
      })
      .map((ride) => ({
        ...ride,
        initiatorName: ride.initiator.fullName,
        initiatorPhone: ride.initiator.phoneNumber,
        current_passengers: ride.participants.length,
        available_seats: ride.maxSeats - ride.participants.length + 1,
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
          travelDistance: body?.routes[0]?.distance, // Distance in meters
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

      // Notify all participants
      const notificationPromises = participants.map((participant) => {
        const notificationMessage = total_fare
          ? `Trip completed! Your share: $${(total_fare / participants.length).toFixed(2)}. Please rate your co-passengers.`
          : `Trip completed! Please rate your co-passengers.`;

        return tx.notification.create({
          data: {
            notificationId: uuidv4(),
            userId: participant.userId,
            rideId: ride_id,
            messageText: notificationMessage,
          },
        });
      });

      await Promise.all(notificationPromises);

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

// @desc    Set ride status to in_progress
// @route   POST /api/rides/:ride_id/start
// @access  Private
const startRide = async (req, res) => {
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

      // Notify all participants about ride start
      const notificationPromises = participants.map((participant) =>
        tx.notification.create({
          data: {
            notificationId: uuidv4(),
            userId: participant.userId,
            rideId: ride_id,
            messageText: "Trip is now in progress. Please be ready!",
          },
        }),
      );

      await Promise.all(notificationPromises);

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

      // Notify all participants about cancellation
      const notificationPromises = participants.map((participant) =>
        tx.notification.create({
          data: {
            notificationId: uuidv4(),
            userId: participant.userId,
            rideId: ride_id,
            messageText: "Trip cancelled by the initiator.",
          },
        }),
      );

      await Promise.all(notificationPromises);

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
