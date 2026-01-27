# Frontend Migration Guide

## 🔄 API Endpoint Updates Required

All API endpoints now require the `/api` prefix. Update your frontend API calls as follows:

### Authentication
```javascript
// OLD
fetch(`http://localhost:3000/studentship/${id}`)

// NEW
fetch(`http://localhost:3000/api/auth/studentship/${id}`)
```

### Rides
```javascript
// Create Ride - OLD
fetch('http://localhost:3000/create-ride', { method: 'POST', ... })

// Create Ride - NEW
fetch('http://localhost:3000/api/rides', { method: 'POST', ... })

// Browse Rides - OLD
fetch('http://localhost:3000/rides')

// Browse Rides - NEW
fetch('http://localhost:3000/api/rides')

// Get Ride Details - OLD
fetch(`http://localhost:3000/rides/${rideId}`)

// Get Ride Details - NEW
fetch(`http://localhost:3000/api/rides/${rideId}`)

// Complete Ride - OLD
fetch(`http://localhost:3000/rides/${rideId}/complete`, { method: 'POST', ... })

// Complete Ride - NEW
fetch(`http://localhost:3000/api/rides/${rideId}/complete`, { method: 'POST', ... })
```

### Ride Requests
```javascript
// Request to Join - OLD
fetch(`http://localhost:3000/rides/${rideId}/request`, { method: 'POST', ... })

// Request to Join - NEW
fetch(`http://localhost:3000/api/rides/${rideId}/requests`, { method: 'POST', ... })

// Accept/Reject Request - OLD
fetch(`http://localhost:3000/rides/${rideId}/requests/${requestId}`, { method: 'PUT', ... })

// Accept/Reject Request - NEW (Same)
fetch(`http://localhost:3000/api/rides/${rideId}/requests/${requestId}`, { method: 'PUT', ... })
```

### Tracking
```javascript
// Track Movement - OLD
fetch('http://localhost:3000/track-movement', { method: 'POST', ... })

// Track Movement - NEW
fetch('http://localhost:3000/api/tracking/movement', { method: 'POST', ... })
```

### Handshake
```javascript
// Verify Handshake - OLD
fetch('http://localhost:3000/verify-handshake', { method: 'POST', ... })

// Verify Handshake - NEW
fetch('http://localhost:3000/api/handshake/verify', { method: 'POST', ... })
```

### Messages
```javascript
// Send Message - OLD
fetch(`http://localhost:3000/rides/${rideId}/messages`, { method: 'POST', ... })

// Send Message - NEW (Same structure, just /api prefix)
fetch(`http://localhost:3000/api/rides/${rideId}/messages`, { method: 'POST', ... })

// Get Messages - OLD
fetch(`http://localhost:3000/rides/${rideId}/messages`)

// Get Messages - NEW
fetch(`http://localhost:3000/api/rides/${rideId}/messages`)
```

### Ratings
```javascript
// Submit Rating - OLD
fetch(`http://localhost:3000/rides/${rideId}/ratings`, { method: 'POST', ... })

// Submit Rating - NEW
fetch(`http://localhost:3000/api/rides/${rideId}/ratings`, { method: 'POST', ... })
```

### SOS
```javascript
// Create SOS Alert - OLD
fetch('http://localhost:3000/sos', { method: 'POST', ... })

// Create SOS Alert - NEW
fetch('http://localhost:3000/api/sos', { method: 'POST', ... })
```

### Notifications
```javascript
// Get Notifications - OLD
fetch(`http://localhost:3000/notifications/${userId}`)

// Get Notifications - NEW
fetch(`http://localhost:3000/api/notifications/${userId}`)

// Mark as Read - OLD
fetch(`http://localhost:3000/notifications/${notificationId}/read`, { method: 'PUT' })

// Mark as Read - NEW
fetch(`http://localhost:3000/api/notifications/${notificationId}/read`, { method: 'PUT' })
```

### User
```javascript
// Get User Profile - OLD
fetch(`http://localhost:3000/users/${userId}/profile`)

// Get User Profile - NEW
fetch(`http://localhost:3000/api/users/${userId}/profile`)

// Get Ride History - OLD
fetch(`http://localhost:3000/users/${userId}/ride-history`)

// Get Ride History - NEW
fetch(`http://localhost:3000/api/users/${userId}/ride-history`)
```

## 📦 Response Format Changes

All responses now include a standardized format:

### Success Response
```json
{
  "success": true,
  "data": { /* your data here */ }
}
```

### Success with Message
```json
{
  "success": true,
  "message": "Operation completed successfully",
  "data": { /* your data here */ }
}
```

### Error Response
```json
{
  "success": false,
  "error": "Error message here"
}
```

### List Response
```json
{
  "success": true,
  "count": 10,
  "data": [ /* array of items */ ]
}
```

## 🔧 Frontend Code Update Example

### Before (Old API)
```javascript
const createRide = async (rideData) => {
  try {
    const response = await fetch('http://localhost:3000/create-ride', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(rideData)
    });
    const data = await response.json();
    return data; // Returns ride object directly
  } catch (error) {
    console.error(error);
  }
};
```

### After (New API)
```javascript
const createRide = async (rideData) => {
  try {
    const response = await fetch('http://localhost:3000/api/rides', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(rideData)
    });
    const result = await response.json();
    
    if (result.success) {
      return result.data; // Access data from result.data
    } else {
      throw new Error(result.error);
    }
  } catch (error) {
    console.error(error);
    throw error;
  }
};
```

## 🎯 Recommended Frontend Updates

### 1. Create an API Configuration File
```javascript
// src/config/api.js
export const API_BASE_URL = 'http://localhost:3000/api';

export const API_ENDPOINTS = {
  // Auth
  VERIFY_STUDENT: (id) => `${API_BASE_URL}/auth/studentship/${id}`,
  
  // Rides
  RIDES: `${API_BASE_URL}/rides`,
  RIDE_DETAILS: (id) => `${API_BASE_URL}/rides/${id}`,
  COMPLETE_RIDE: (id) => `${API_BASE_URL}/rides/${id}/complete`,
  
  // Requests
  CREATE_REQUEST: (rideId) => `${API_BASE_URL}/rides/${rideId}/requests`,
  UPDATE_REQUEST: (rideId, requestId) => `${API_BASE_URL}/rides/${rideId}/requests/${requestId}`,
  
  // Tracking
  TRACK_MOVEMENT: `${API_BASE_URL}/tracking/movement`,
  
  // Handshake
  VERIFY_HANDSHAKE: `${API_BASE_URL}/handshake/verify`,
  
  // Messages
  MESSAGES: (rideId) => `${API_BASE_URL}/rides/${rideId}/messages`,
  
  // Ratings
  SUBMIT_RATING: (rideId) => `${API_BASE_URL}/rides/${rideId}/ratings`,
  
  // SOS
  CREATE_SOS: `${API_BASE_URL}/sos`,
  
  // Notifications
  NOTIFICATIONS: (userId) => `${API_BASE_URL}/notifications/${userId}`,
  MARK_READ: (notificationId) => `${API_BASE_URL}/notifications/${notificationId}/read`,
  
  // User
  USER_PROFILE: (userId) => `${API_BASE_URL}/users/${userId}/profile`,
  USER_HISTORY: (userId) => `${API_BASE_URL}/users/${userId}/ride-history`,
};
```

### 2. Create an API Helper Function
```javascript
// src/utils/apiHelper.js
export const apiCall = async (url, options = {}) => {
  try {
    const response = await fetch(url, {
      headers: {
        'Content-Type': 'application/json',
        ...options.headers,
      },
      ...options,
    });

    const result = await response.json();

    if (!response.ok) {
      throw new Error(result.error || 'API request failed');
    }

    return result.data; // Automatically extract data
  } catch (error) {
    console.error('API Error:', error);
    throw error;
  }
};
```

### 3. Usage Example
```javascript
import { API_ENDPOINTS } from './config/api';
import { apiCall } from './utils/apiHelper';

// Create a ride
const createRide = async (rideData) => {
  const data = await apiCall(API_ENDPOINTS.RIDES, {
    method: 'POST',
    body: JSON.stringify(rideData),
  });
  return data;
};

// Get rides
const getRides = async (filters = {}) => {
  const queryString = new URLSearchParams(filters).toString();
  const url = `${API_ENDPOINTS.RIDES}?${queryString}`;
  const data = await apiCall(url);
  return data;
};
```

## ✅ Testing Checklist

After updating your frontend, test these scenarios:

- [ ] User verification/authentication
- [ ] Creating a new ride
- [ ] Browsing available rides
- [ ] Requesting to join a ride
- [ ] Accepting/rejecting requests
- [ ] Sending messages in ride chat
- [ ] Tracking GPS location
- [ ] Verifying handshake with QR
- [ ] Completing a trip
- [ ] Submitting ratings
- [ ] Creating SOS alerts
- [ ] Viewing notifications
- [ ] Viewing user profile
- [ ] Viewing ride history

## 🐛 Common Issues

### Issue: CORS Error
**Solution**: The backend now has proper CORS configuration. Ensure your frontend origin is added in `backend/config/cors.js`

### Issue: 404 Not Found
**Solution**: Double-check you've added the `/api` prefix to all endpoints

### Issue: Response structure changed
**Solution**: Update your code to access `result.data` instead of the response directly

---

**Note**: All old endpoints without `/api` prefix will return 404. Make sure to update all API calls in your frontend!
