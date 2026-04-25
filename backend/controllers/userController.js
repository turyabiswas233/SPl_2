/**
 * User Controller
 * Handles user profile and history with Prisma ORM
 */

const prisma = require("../db/prismaClient");

// @desc    Get user profile
// @route   GET /api/users/:user_id/profile
// @access  Public
const getUserProfile = async (req, res) => {
  const { user_id } = req.params;

  try {
    const user = await prisma.user.findUnique({
      where: { userId: user_id },
      select: {
        userId: true,
        fullName: true,
        email: true,
        phoneNumber: true,
        registrationNumber: true,
        deptName: true,
        verificationStatus: true,
        createdAt: true,
      },
    });

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found.",
      });
    }

    // Get average rating and total ratings
    const ratingStats = await prisma.rating.aggregate({
      where: { ratedUserId: user_id },
      _avg: { rating: true },
      _count: true,
    });

    // Get total rides
    const rideCount = await prisma.rideParticipant.count({
      where: { userId: user_id },
    });

    res.status(200).json({
      success: true,
      data: {
        ...user,
        avg_rating: parseFloat(ratingStats._avg.rating || 0).toFixed(2),
        total_ratings: ratingStats._count,
        total_rides: rideCount,
      },
    });
  } catch (error) {
    console.error("Get user profile error:", error);
    res.status(500).json({
      success: false,
      message: "An error occurred while fetching user profile",
    });
  }
};

// @desc    Get user ride history
// @route   GET /api/users/ride-history
// @access  Private
const getUserRideHistory = async (req, res) => {
  const user_id = req.user.userId;

  try {
    const rideHistory = await prisma.rideParticipant.findMany({
      where: { userId: user_id },
      include: {
        ride: {
          include: {
            initiator: {
              select: {
                fullName: true,
              },
            },
            participants: {
              // where userId != initiatorid
              where: {
                userId: { not: user_id },
              },
              select: {
                userId: true,
              },
            },
          },
        },
      },
      orderBy: {
        ride: {
          createdAt: "desc",
        },
      },
    });

    // Format the response to match the old query structure
    const formattedData = rideHistory.map((rp) => ({
      ...rp.ride,
      maxSeats: rp.ride.maxSeats - 1, // Adjust maxSeats to reflect available seats
      initiator_name: rp.ride.initiator.fullName,
      has_met: rp.hasMetBoolean,
      met_at: rp.metAt,
    }));

    res.status(200).json({
      success: true,
      count: formattedData.length,
      data: formattedData,
    });
  } catch (error) {
    console.error("Get ride history error:", error);
    res.status(500).json({
      success: false,
      message: "An error occurred while fetching ride history",
    });
  }
};

// @desc    Get all rides requested by current user
// @route   GET /api/users/my-requests
// @access  Private
const getUserRequestedRides = async (req, res) => {
  const user_id = req.user.userId;

  try {
    const requestedRides = await prisma.rideRequest.findMany({
      where: { requesterId: user_id },
      include: {
        ride: {
          include: {
            initiator: {
              select: {
                fullName: true,
              },
            },
            participants: {
              where: {
                userId: { not: user_id },
              },
              select: {
                userId: true,
              },
            },
          },
        },
      },
      orderBy: {
        createdAt: "desc",
      },
    });

    // Format the response to match the ride history pattern
    const formattedData = requestedRides.map((rr) => ({
      ...rr.ride,
      initiator_name: rr.ride.initiator.fullName,
      request_status: rr.status,
    }));

    res.status(200).json({
      success: true,
      count: formattedData.length,
      data: formattedData,
    });
  } catch (error) {
    console.error("Get requested rides error:", error);
    res.status(500).json({
      success: false,
      message: "An error occurred while fetching requested rides",
    });
  }
};

module.exports = {
  getUserProfile,
  getUserRideHistory,
  getUserRequestedRides,
};
