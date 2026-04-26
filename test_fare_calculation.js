/**
 * Fare Calculation Test Script
 * Tests the fare splitting implementation
 */

const fareService = require('./backend/services/fareService');

console.log('=== Fare Splitting Implementation Test ===\n');

// Test 1: Calculate segment fare
console.log('Test 1: Calculate segment fare');
const distance = 15000; // 15 km in meters
const duration = 1800; // 30 minutes in seconds
const result = fareService.calculateSegmentFare(distance, duration);
console.log(`Distance: ${result.distance} km`);
console.log(`Duration: ${result.duration} minutes`);
console.log(`Fare: ${result.fare} BDT`);
console.log('Expected: Base Fare (20) + (15 × 8) + (30 × 0.5) = 20 + 120 + 15 = 155 BDT');
console.log(`✓ Pass: ${result.fare === 155 ? 'YES' : 'NO'}\n`);

// Test 2: Calculate Haversine distance
console.log('Test 2: Calculate Haversine distance');
const lat1 = 23.8103, lng1 = 90.4125; // Dhaka
const lat2 = 23.7606, lng2 = 90.3865; // Another point in Dhaka
const dist = fareService.calculateHaversineDistance(lat1, lng1, lat2, lng2);
console.log(`Distance between points: ${(dist / 1000).toFixed(2)} km`);
console.log(`✓ Pass: ${dist > 0 ? 'YES' : 'NO'}\n`);

// Test 3: Calculate total fare
console.log('Test 3: Calculate total fare');
const totalFareResult = fareService.calculateTotalFare(distance, duration);
console.log(`Total Fare: ${totalFareResult.totalFare} BDT`);
console.log(`Currency: ${totalFareResult.currency}`);
console.log(`✓ Pass: ${totalFareResult.totalFare === 155 ? 'YES' : 'NO'}\n`);

// Test 4: Calculate fare breakdown (mock data)
console.log('Test 4: Calculate fare breakdown (mock)');
const mockBreakdown = {
  success: true,
  rideId: 'test-ride-123',
  totalDistance: 15,
  totalDuration: 45,
  totalFare: 245.50,
  currency: 'BDT',
  breakdown: [
    {
      userId: 'user1',
      name: 'John Doe',
      role: 'initiator',
      distance: 15,
      duration: 45,
      fare: 122.75,
      currency: 'BDT'
    },
    {
      userId: 'user2',
      name: 'Jane Smith',
      role: 'passenger',
      distance: 10,
      duration: 30,
      fare: 61.38,
      currency: 'BDT'
    },
    {
      userId: 'user3',
      name: 'Bob Johnson',
      role: 'passenger',
      distance: 10,
      duration: 30,
      fare: 61.37,
      currency: 'BDT'
    }
  ],
  participantCount: 3
};

console.log(`Total Fare: ${mockBreakdown.totalFare} BDT`);
console.log(`Number of Participants: ${mockBreakdown.participantCount}`);
console.log('Breakdown:');
mockBreakdown.breakdown.forEach(p => {
  console.log(`  - ${p.name} (${p.role}): ${p.fare} BDT`);
});

// Verify total
const sumFares = mockBreakdown.breakdown.reduce((sum, p) => sum + p.fare, 0);
console.log(`\nSum of all fares: ${sumFares.toFixed(2)} BDT`);
console.log(`Expected total: ${mockBreakdown.totalFare} BDT`);
console.log(`✓ Pass: ${Math.abs(sumFares - mockBreakdown.totalFare) < 0.01 ? 'YES' : 'NO'}\n`);

// Test 5: Different distances and durations
console.log('Test 5: Different ride parameters');
const testCases = [
  { distance: 5000, duration: 600, expected: 20 + (5 * 8) + (10 * 0.5) }, // 65 BDT
  { distance: 10000, duration: 1200, expected: 20 + (10 * 8) + (20 * 0.5) }, // 110 BDT
  { distance: 20000, duration: 2400, expected: 20 + (20 * 8) + (40 * 0.5) } // 200 BDT
];

testCases.forEach((test, idx) => {
  const result = fareService.calculateSegmentFare(test.distance, test.duration);
  const pass = Math.abs(result.fare - test.expected) < 0.01;
  console.log(`  Test ${idx + 1}: ${test.distance/1000}km, ${test.duration/60}min → ${result.fare} BDT (expected ${test.expected}) - ${pass ? '✓' : '✗'}`);
});

console.log('\n=== All Tests Complete ===');
