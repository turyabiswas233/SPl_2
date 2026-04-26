/**
 * Standalone Fare Calculation Test
 * Tests the fare splitting logic without database dependency
 */

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
function calculateSegmentFare(distance, duration) {
  const distanceKm = distance / 1000; // Convert to km
  const durationMin = duration / 60; // Convert to minutes
  
  const fare = BASE_FARE + (distanceKm * PER_KM_RATE) + (durationMin * PER_MIN_RATE);
  
  return {
    distance: distanceKm,
    duration: durationMin,
    fare: Math.round(fare * 100) / 100, // Round to 2 decimal places
  };
}

/**
 * Calculate Haversine distance between two points
 * @param {number} lat1 - Latitude 1
 * @param {number} lng1 - Longitude 1
 * @param {number} lat2 - Latitude 2
 * @param {number} lng2 - Longitude 2
 * @returns {number} Distance in meters
 */
function calculateHaversineDistance(lat1, lng1, lat2, lng2) {
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
}

/**
 * Calculate total fare for a ride based on route distance
 * @param {number} distance - Total distance in meters
 * @param {number} duration - Total duration in seconds
 * @returns {object} Total fare details
 */
function calculateTotalFare(distance, duration) {
  const result = calculateSegmentFare(distance, duration);
  return {
    distance: result.distance,
    duration: result.duration,
    totalFare: result.fare,
    currency: 'BDT'
  };
}

/**
 * Calculate fare breakdown for all participants in a ride
 * @param {number} totalDistance - Total ride distance in meters
 * @param {number} totalDuration - Total ride duration in seconds
 * @param {number} participantCount - Number of participants (excluding initiator)
 * @returns {object} Fare breakdown
 */
function calculateFareBreakdown(totalDistance, totalDuration, participantCount) {
  const totalFare = calculateTotalFare(totalDistance, totalDuration).totalFare;
  const totalPassengers = participantCount + 1; // Include initiator

  // Calculate proportional share
  // Initiator pays 50%, remaining 50% split among passengers
  const initiatorShare = totalFare * 0.5;
  const remainingFare = totalFare * 0.5;
  const passengerShare = participantCount > 0 ? remainingFare / participantCount : 0;

  const breakdown = [];
  
  // Initiator's share
  breakdown.push({
    userId: 'initiator',
    name: 'Ride Initiator',
    role: 'initiator',
    distance: totalDistance / 1000,
    duration: totalDuration / 60,
    fare: Number(initiatorShare.toFixed(2)),
    currency: 'BDT'
  });

  // Passenger shares
  for (let i = 0; i < participantCount; i++) {
    breakdown.push({
      userId: `passenger_${i + 1}`,
      name: `Passenger ${i + 1}`,
      role: 'passenger',
      distance: totalDistance / 1000,
      duration: totalDuration / 60,
      fare: Number(passengerShare.toFixed(2)),
      currency: 'BDT'
    });
  }

  return {
    success: true,
    totalDistance: totalDistance / 1000,
    totalDuration: totalDuration / 60,
    totalFare,
    currency: 'BDT',
    breakdown,
    participantCount: totalPassengers
  };
}

// Run Tests
console.log('=== Fare Splitting Implementation Test ===\n');

// Test 1: Calculate segment fare
console.log('Test 1: Calculate segment fare');
const distance = 15000; // 15 km in meters
const duration = 1800; // 30 minutes in seconds
const result = calculateSegmentFare(distance, duration);
console.log(`Distance: ${result.distance} km`);
console.log(`Duration: ${result.duration} minutes`);
console.log(`Fare: ${result.fare} BDT`);
console.log('Expected: Base Fare (20) + (15 × 8) + (30 × 0.5) = 20 + 120 + 15 = 155 BDT');
console.log(`✓ Pass: ${result.fare === 155 ? 'YES' : 'NO'}\n`);

// Test 2: Calculate Haversine distance
console.log('Test 2: Calculate Haversine distance');
const lat1 = 23.8103, lng1 = 90.4125; // Dhaka
const lat2 = 23.7606, lng2 = 90.3865; // Another point in Dhaka
const dist = calculateHaversineDistance(lat1, lng1, lat2, lng2);
console.log(`Distance between points: ${(dist / 1000).toFixed(2)} km`);
console.log(`✓ Pass: ${dist > 0 ? 'YES' : 'NO'}\n`);

// Test 3: Calculate total fare
console.log('Test 3: Calculate total fare');
const totalFareResult = calculateTotalFare(distance, duration);
console.log(`Total Fare: ${totalFareResult.totalFare} BDT`);
console.log(`Currency: ${totalFareResult.currency}`);
console.log(`✓ Pass: ${totalFareResult.totalFare === 155 ? 'YES' : 'NO'}\n`);

// Test 4: Calculate fare breakdown
console.log('Test 4: Calculate fare breakdown');
const breakdown = calculateFareBreakdown(15000, 2700, 2); // 15km, 45min, 2 passengers
console.log(`Total Fare: ${breakdown.totalFare} BDT`);
console.log(`Number of Participants: ${breakdown.participantCount}`);
console.log('Breakdown:');
breakdown.breakdown.forEach(p => {
  console.log(`  - ${p.name} (${p.role}): ${p.fare} BDT`);
});

// Verify total
const sumFares = breakdown.breakdown.reduce((sum, p) => sum + p.fare, 0);
console.log(`\nSum of all fares: ${sumFares.toFixed(2)} BDT`);
console.log(`Expected total: ${breakdown.totalFare} BDT`);
console.log(`✓ Pass: ${Math.abs(sumFares - breakdown.totalFare) < 0.01 ? 'YES' : 'NO'}\n`);

// Test 5: Different scenarios
console.log('Test 5: Different ride scenarios');
const scenarios = [
  { distance: 5000, duration: 600, passengers: 1, desc: 'Short ride, 1 passenger' },
  { distance: 10000, duration: 1200, passengers: 2, desc: 'Medium ride, 2 passengers' },
  { distance: 20000, duration: 2400, passengers: 3, desc: 'Long ride, 3 passengers' },
  { distance: 30000, duration: 3600, passengers: 4, desc: 'Very long ride, 4 passengers' }
];

scenarios.forEach((scenario, idx) => {
  const result = calculateFareBreakdown(scenario.distance, scenario.duration, scenario.passengers);
  console.log(`  ${idx + 1}. ${scenario.desc}`);
  console.log(`     Total Fare: ${result.totalFare} BDT`);
  console.log(`     Per person: ${(result.totalFare / result.participantCount).toFixed(2)} BDT`);
  console.log(`     Initiator pays: ${result.breakdown[0].fare} BDT`);
});

console.log('\n=== All Tests Complete ===');
console.log('\nImplementation Summary:');
console.log('✓ Fare calculation based on distance and time');
console.log('✓ Dynamic splitting between initiator and passengers');
console.log('✓ Haversine formula for distance calculation');
console.log('✓ Scalable to multiple passengers');
console.log('✓ Transparent breakdown for all participants');
