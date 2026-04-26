# CRC Diagrams and Use Cases
## Dynamic Fare Splitting System

---

## 📊 CRC (Class-Responsibility-Collaboration) Diagrams

### 1. Ride Management Classes

    +─────────────────────+           +─────────────────────+           +─────────────────────+
    │      Ride           │           │  RideParticipant    │           │        User         │
    ├─────────────────────┤           ├─────────────────────┤           ├─────────────────────┤
    │ - rideId: String    │           │ - participantId:    │           │ - userId: String    │
    │ - initiatorId:      │           │   String            │           │ - fullName: String  │
    │   String            │           │ - pickupLat: Float? │           │ - email: String?    │
    │ - startLocation:    │           │ - pickupLng: Float? │           │ - phoneNumber:      │
    │   String            │◄──────────┤ - dropoffLat: Float?│           │   String?           │
    │ - startLat: Float   │           │ - dropoffLng: Float?│           └─────────────────────┘
    │ - startLng: Float   │           │ - fare: Float?      │                      ▲
    │ - destLat: Float    │           │ - hasMet: Boolean   │                      │
    │ - destLng: Float    │           │ - metAt: DateTime?  │           +─────────┴─────────+
    │ - totalFare: Float? │           ├─────────────────────┤           │   RideService      │
    │ - currency: String  │           │ + calculateFare()   │           ├─────────────────────┤
    │ - status: String    │           │ + updateFare()      │           │ + createRide()     │
    ├─────────────────────┤           └─────────────────────┘           │ + getRides()       │
    │ + calculateTotal()  │                      ▲                     │ + getNearbyRides() │
    │ + addParticipant()  │──────────────────────┼─────────────────────┤ + getFareBreakdown()│
    │ + removeParticipant()│                     │                     │ + startRide()      │
    └─────────────────────┘           +─────────┴─────────+           │ + cancelRide()     │
                                      │  FareService   │           └─────────────────────┘
                                      ├────────────────┤
                                      │ + calculate-   │
                                      │   SegmentFare()│
                                      │ + calculate-   │
                                      │   TotalFare()  │
                                      │ + calculate-   │
                                      │   Breakdown()  │
                                      │ + update-      │
                                      │   Participant()│
                                      └────────────────┘

### 2. Payment Processing Classes

    +─────────────────────+           +─────────────────────+           +─────────────────────+
    │   PaymentService   │           │      Payment        │           │  StripeService      │
    ├─────────────────────┤           ├─────────────────────┤           ├─────────────────────┤
    │ + estimateCost()   │           │ - paymentId: String │           │ + createPayment()   │
    │ + initiatePayment()│           │ - orderId: String  │           │ + processPayment()  │
    │ + verifyPayment()  │           │ - amount: Float    │           │ + verifyPayment()   │
    │ + getStatus()      │           │ - status: String   │           └─────────────────────┘
    └─────────────────────┘           │ - currency: String │
                                        │ - rideId: String? │
                                        │ - userId: String │
                                        └─────────────────┘

### 3. Notification System Classes

    +─────────────────────+           +─────────────────────+           +─────────────────────+
    │ NotificationService│           │   Notification     │           │        Ride          │
    ├─────────────────────┤           ├─────────────────────┤           ├─────────────────────┤
    │ + sendNotification()│          │ - notificationId:  │           │ - rideId: String    │
    │ + bulkNotify()     │           │   String           │           │ - status: String    │
    │ + createSOSAlert() │◄──────────┤ - messageText:     │           │ - participants:     │
    └─────────────────────┘           │   String           │           │   List<User>        │
                                        │ - createdAt:       │           └─────────────────────┘
                                        │   DateTime        │
                                        └───────────────────┘

### 4. Map and Location Services

    +─────────────────────+           +─────────────────────+           +─────────────────────+
    │   MapboxService    │           │   LocationInfo     │           │     Cord           │
    ├─────────────────────┤           ├─────────────────────┤           ├─────────────────────┤
    │ + getRoute()       │           │ - currentLocation: │           │ - latitude: double │
    │ + searchLocation() │           │   Cord?            │           │ - longitude: double│
    │ + getDistance()    │           │ - cityName: String │           └─────────────────────┘
    │ + calculateFare()  │◄──────────├─────────────────────┤
    └─────────────────────┘           │ + resolveCity()    │
                                        │ + updateLocation()│
                                        │ + getInstance()   │
                                        └───────────────────┘

---

## 📝 USE CASES

### Use Case 1: Calculate Fare Breakdown

**Actors:** Ride Initiator, Passengers, System

**Preconditions:**
- Ride exists with at least one participant
- Route distance and duration are known

**Main Flow:**
1. User taps on a ride in the app
2. System calls GET /api/v1/rides/{ride_id}/fare-breakdown
3. FareService calculates total fare using formula:
   - totalFare = 20 + (distance_km x 8) + (duration_min x 0.5)
4. System splits fare:
   - initiatorShare = totalFare x 0.5
   - passengerShare = (totalFare x 0.5) / passengerCount
5. System returns breakdown with individual fares
6. Display shows:
   - Total trip fare
   - Number of participants
   - Individual breakdown (initiator vs passengers)
   - Current user's share highlighted

**Postconditions:**
- Fare breakdown visible to all ride participants
- Each participant sees their individual share

--- 

### Use Case 2: Create Ride with Fare Estimation

**Actors:** Ride Initiator, System

**Preconditions:**
- User authenticated
- Start and destination locations selected

**Main Flow:**
1. User enters ride details (start, destination, seats)
2. System estimates route via Mapbox API
3. Calculate estimated fare:
   - distance = route distance
   - duration = route duration
   - fare = 20 + (distance_km x 8) + (duration_min x 0.5)
4. Display estimated total fare
5. User confirms and creates ride
6. System saves ride with totalFare field

**Postconditions:**
- Ride created with calculated totalFare
- Initiator sees estimated cost before confirming

---

### Use Case 3: Join Ride with Individual Fare Display

**Actors:** Passenger, System

**Preconditions:**
- Ride exists and is open
- Passenger selects ride from nearby list

**Main Flow:**
1. User browses nearby rides
2. Each ride shows targetFare (estimated per passenger)
3. User selects ride to view details
4. System fetches fare breakdown
5. Display shows:
   - Total fare
   - Passenger's individual share
   - Number of current participants
6. User requests to join
7. System adds passenger to ride

**Postconditions:**
- Passenger joins ride knowing their cost
- Fare breakdown updated for all participants

---

## 💡 KEY RESPONSIBILITIES

### Ride Class
- Store ride details (start, end, participants)
- Calculate total fare
- Manage participant list
- Track ride status

### RideParticipant Class
- Store individual participant details
- Track custom pickup/dropoff
- Store individual fare
- Track meeting status

### FareService Class
- Calculate segment fares
- Split fares fairly (50/50)
- Generate breakdown
- Update participant fares

### Payment Service
- Process individual payments
- Link payments to participants
- Track payment status
- Generate receipts

---

## ✅ CONCLUSION

The CRC diagrams and use cases demonstrate a well-structured, scalable system for dynamic fare splitting that:

1. Accurately calculates fair fares based on individual usage
2. Clearly displays breakdown to all participants
3. Flexibly handles custom pickup/dropoff points
4. Reliably processes individual payments
5. Scalably supports multiple passengers per ride

The design follows SOLID principles, is easy to test and maintain, and provides a foundation for future enhancements.
