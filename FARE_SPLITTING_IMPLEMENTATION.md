# Dynamic Fare Splitting Implementation

## Overview
This implementation adds dynamic fare splitting functionality to the Dromos ride-sharing application. When multiple passengers share the same ride but have different starting and ending points, each passenger's fare is calculated based on their individual journey segment.

## Features Implemented

### 1. Backend Changes

#### New Service: `services/fareService.js`
- `calculateSegmentFare(distance, duration)` - Calculate fare for a route segment
- `calculateHaversineDistance(lat1, lng1, lat2, lng2)` - Calculate distance between two coordinates
- `calculateTotalFare(distance, duration)` - Calculate total ride fare
- `calculateFareBreakdown(rideId, totalDistance, totalDuration)` - Calculate fare breakdown for all participants
- `updateParticipantFare(rideId, userId, fare)` - Update individual participant fare
- `updateRideTotalFare(rideId, totalFare)` - Update ride total fare

#### API Endpoint: GET /api/v1/rides/{ride_id}/fare-breakdown
- Returns detailed fare breakdown for a shared ride
- Includes individual passenger fares
- Calculates proportional sharing based on journey segments

#### Updated: GET /api/v1/rides/nearby
- Now includes `targetFare` field for each nearby ride
- Shows estimated fare per passenger

#### Database Schema Updates (Prisma)
- Added `totalFare` and `currency` fields to `Ride` model
- Added `pickupLat`, `pickupLng`, `dropoffLat`, `dropoffLng`, `fare` fields to `RideParticipant` model

### 2. Frontend Changes

#### Updated: `lib/models/ride_model.dart`
- Added `totalFare` field
- Added `currency` field

#### Updated: `lib/models/nearby_ride_model.dart`
- Added `targetFare` field
- Added `status` field

#### Updated: `lib/pages/ride/map_page.dart`
- Added fare breakdown section at the bottom of ride details
- Shows total trip fare
- Lists all passengers with individual fares
- Highlights current user's share
- Visual indicator for ride initiator vs passenger

#### Updated: `lib/screens/payment/payment_screen.dart`
- Shows estimated cost breakdown
- Displays individual share vs total cost
- Validates payment amount against estimated cost

## Fare Calculation Logic

### Cost Formula
```
Total Fare = Base Fare + (Distance × Per Km Rate) + (Duration × Per Min Rate)
```

### Constants
- Base Fare: 20 BDT
- Per Km Rate: 8 BDT/km
- Per Min Rate: 0.5 BDT/minute

### Splitting Logic
- **Initiator**: Pays 50% of total fare (or negotiated share)
- **Passengers**: Remaining 50% split equally among all passengers
- If passengers have custom pickup/dropoff points, fare is calculated based on their individual segment

## API Usage Examples

### Get Fare Breakdown
```
GET /api/v1/rides/{ride_id}/fare-breakdown
Authorization: Bearer <token>

Response:
{
  "success": true,
  "data": {
    "rideId": "...",
    "totalDistance": 15.5,  // km
    "totalDuration": 45,     // minutes
    "totalFare": 245.50,    // BDT
    "currency": "BDT",
    "participantCount": 3,
    "breakdown": [
      {
        "userId": "...",
        "name": "John Doe",
        "role": "initiator",
        "fare": 122.75,
        "currency": "BDT"
      },
      {
        "userId": "...",
        "name": "Jane Smith",
        "role": "passenger",
        "fare": 61.38,
        "currency": "BDT"
      }
    ]
  }
}
```

### Get Nearby Rides (with fare)
```
GET /api/v1/rides/nearby?lng=90.4125&lat=23.8103
Authorization: Bearer <token>

Response includes:
{
  "targetFare": 85.50  // Estimated fare per passenger
}
```

## Frontend Usage

### Display Fare Breakdown in Ride Details
```dart
// In map_page.dart, the fare breakdown is automatically fetched
// and displayed when viewing a ride
FutureBuilder<Map<String, dynamic>>(
  future: _fetchFareBreakdown(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return _buildFareBreakdown(snapshot.data!);
    }
    return CircularProgressIndicator();
  }
)
```

### Show Estimated Fare in Payment Screen
```dart
// When creating a ride or joining a ride
// The estimated fare is automatically calculated
// and displayed to the user
```

## Testing

### Test Fare Calculation
```bash
# Run the fare service unit tests
node test/fareService.test.js
```

### Test API Endpoints
```bash
# Get fare breakdown
curl -X GET http://localhost:5000/api/v1/rides/{ride_id}/fare-breakdown \
  -H "Authorization: Bearer <token>"

# Get nearby rides with fare info
curl -X GET "http://localhost:5000/api/v1/rides/nearby?lng=90.4125&lat=23.8103" \
  -H "Authorization: Bearer <token>"
```

## Configuration

### Environment Variables
```
MAPBOX_ACCESS_TOKEN=your_mapbox_token  # For route distance calculation
```

### Customize Fare Rates
Edit `services/fareService.js`:
```javascript
const BASE_FARE = 20;        // Change base fare
const PER_KM_RATE = 8;       // Change per km rate
const PER_MIN_RATE = 0.5;    // Change per minute rate
```

## Future Enhancements

1. **Dynamic Pricing**: Implement surge pricing during peak hours
2. **Route Optimization**: Calculate optimal routes considering all pickup/dropoff points
3. **Split Payment**: Allow passengers to pay individually through the app
4. **Fare Negotiation**: Enable passengers to negotiate their share
5. **Discounts**: Apply discounts for regular users or group bookings
6. **Tolls and Fees**: Add toll charges and other fees to fare calculation
7. **Multi-Currency**: Support multiple currencies
8. **Fare History**: Track and display fare history for users

## Troubleshooting

### Fare Calculation Not Working
- Ensure Mapbox API token is configured
- Check that ride has valid start/destination coordinates
- Verify route can be calculated (try manual route calculation)

### Incorrect Fare Amounts
- Verify fare constants in `services/fareService.js`
- Check currency settings
- Ensure distance and duration are in correct units (meters, seconds)

### API Errors
- Verify authentication token is valid
- Check ride ID format (must be UUID)
- Ensure user has permission to view fare breakdown

## Security Considerations

1. **Authentication**: All fare-related endpoints require authentication
2. **Authorization**: Users can only view fares for rides they're participating in
3. **Data Validation**: All inputs are validated and sanitized
4. **Rate Limiting**: API endpoints are rate-limited to prevent abuse
5. **Audit Trail**: Fare calculations are logged for audit purposes

## Conclusion

This implementation provides a robust dynamic fare splitting system that:
- ✅ Calculates fair shares based on individual journey segments
- ✅ Provides transparent fare breakdown to all participants
- ✅ Integrates seamlessly with existing ride and payment systems
- ✅ Scales to handle multiple passengers per ride
- ✅ Provides clear UI/UX for fare information
