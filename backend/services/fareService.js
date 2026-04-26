/**
 * Fare Splitting Service
 * Calculates dynamic fares for shared rides based on individual passenger segments
 */

const prisma = require('../db/prismaClient');

// Cost calculation constants (BDT)
const BASE_FARE = 20;
const PER_KM_RATE = 8;
const PER_MIN_RATE = 0.5;

/**
 * Calculate fare for a route segment
 * @param {number} distance - Distance in meters
 * @param {number} duration - Duration in seconds
 * @returns {object} Fare details
 */
const calculateSegmentFare = (distance, duration) => {
  const distanceKm = distance / 1000; // Convert to km
  const durationMin = duration / 60; // Convert to minutes
  
  const fare = BASE_FARE + (distanceKm * PER_KM_RATE) + (durationMin * PER_MIN_RATE);
  
  return {
    distance: distanceKm,
    duration: durationMin,
    fare: Math.round(fare * 100) / 100, // Round to 2 decimal places
  };
};

/**
 * Calculate Haversine distance between two points
 * @param {number} lat1 - Latitude 1
 * @param {number} lng1 - Longitude 1
 * @param {number} lat2 - Latitude 2
 * @param {number} lng2 - Longitude 2
 * @returns {number} Distance in meters
 */
const calculateHaversineDistance = (lat1, lng1, lat2, lng2) => {
  const R = 6371000; // Earth's radius in meters
  const dLat = (lat2 - lat1) * (Math.PI / 180);
  const dLng = (lng2 - lng1) * (Math.PI / 180);
  const a = 
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * (Math.PI / 180)) * 
    Math.cos(lat2 * (Math.PI / 180)) * 
    Math.sin(dLng / 2) * Math.sin(dLng / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
};

/**
 * Calculate total fare for a ride based on route distance
 * @param {number} distance - Total distance in meters
 * @param {number} duration - Total duration in seconds
 * @returns {object} Total fare details
 */
const calculateTotalFare = (distance, duration) => {
  const result = calculateSegmentFare(distance, duration);
  return {
    distance: result.distance,
    duration: result.duration,
    totalFare: result.fare,
    currency: 'BDT'
  };
};

/**
 * Calculate fare breakdown for all participants in a ride
 * @param {string} rideId - The ride ID
 * @param {number} totalDistance - Total ride distance in meters
 * @param {number} totalDuration - Total ride duration in seconds
 * @returns {object} Fare breakdown
 */
const calculateFareBreakdown = async (rideId, totalDistance, totalDuration) => {
  try {
    const ride = await prisma.ride.findUnique({
      where: { rideId },
      include: {
        participants: {
          include: {
            user: {
              select: {
                fullName: true,
                phoneNumber: true
              }
            }
          }
        },
        initiator: {
          select: {
            fullName: true,
            phoneNumber: true
          }
        }
      }
    });

    if (!ride) {
      throw new Error('Ride not found');
    }

    const totalFare = calculateTotalFare(totalDistance, totalDuration).totalFare;
    const participants = ride.participants;
    const totalPassengers = participants.length + 1; // Include initiator

    // Calculate proportional share for each participant
    const breakdown = [];
    
    // Initiator's share (usually pays more or gets discount)
    const initiatorShare = {
      userId: ride.initiatorId,
      name: ride.initiator.fullName,
      phoneNumber: ride.initiator.phoneNumber,
      role: 'initiator',
      distance: totalDistance / 1000,
      duration: totalDuration / 60,
      fare: totalFare * 0.5, // Initiator pays 50% or negotiated share
      currency: 'BDT'
    };
    breakdown.push(initiatorShare);

    // Calculate passenger shares
    const remainingFare = totalFare * 0.5; // Remaining 50% split among passengers
    const passengerShare = participants.length > 0 ? remainingFare / participants.length : 0;

    for (const participant of participants) {
      const participantFare = {
        userId: participant.userId,
        name: participant.user.fullName,
        phoneNumber: participant.user.phoneNumber,
        role: 'passenger',
        distance: participant.pickupLat && participant.dropoffLat ? 
          calculateHaversineDistance(
            participant.pickupLat, participant.pickupLng,
            participant.dropoffLat, participant.dropoffLng
          ) / 1000 : totalDistance / 1000,
        duration: participant.pickupLat && participant.dropoffLat ?
          0 : totalDuration / 60,
        fare: Number(passengerShare.toFixed(2)),
        currency: 'BDT'
      };
      breakdown.push(participantFare);
    }

    return {
      success: true,
      rideId,
      totalDistance: totalDistance / 1000,
      totalDuration: totalDuration / 60,
      totalFare,
      currency: 'BDT',
      breakdown,
      participantCount: totalPassengers
    };
  } catch (error) {
    console.error('Error calculating fare breakdown:', error);
    return {
      success: false,
      error: error.message
    };
  }
};

/**
 * Update participant fare in database
 * @param {string} rideId - The ride ID
 * @param {string} userId - The user ID
 * @param {number} fare - The calculated fare
 * @returns {object} Updated participant
 */
const updateParticipantFare = async (rideId, userId, fare) => {
  try {
    const updated = await prisma.rideParticipant.update({
      where: {
        rideId_userId: {
          rideId,
          userId
        }
      },
      data: {
        fare
      },
      include: {
        user: {
          select: {
            fullName: true
          }
        }
      }
    });

    return {
      success: true,
      data: updated
    };
  } catch (error) {
    console.error('Error updating participant fare:', error);
    return {
      success: false,
      error: error.message
    };
  }
};

/**
 * Update ride total fare
 * @param {string} rideId - The ride ID
 * @param {number} totalFare - The total fare
 * @returns {object} Updated ride
 */
const updateRideTotalFare = async (rideId, totalFare) => {
  try {
    const updated = await prisma.ride.update({
      where: { rideId },
      data: {
        totalFare
      }
    });

    return {
      success: true,
      data: updated
    };
  } catch (error) {
    console.error('Error updating ride total fare:', error);
    return {
      success: false,
      error: error.message
    };
  }
};

module.exports = {
  calculateSegmentFare,
  calculateParticipantFare,
  calculateTotalFare,
  calculateFareBreakdown,
  updateParticipantFare,
  updateRideTotalFare,
  BASE_FARE,
  PER_KM_RATE,
  PER_MIN_RATE
};
