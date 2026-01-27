# Authentication API Documentation

## 🔐 JWT Authentication Endpoints

All authentication endpoints use JWT (JSON Web Tokens) for secure user authentication. The JWT secret is stored in the `.env` file as `JWT_SECRET_KEY`.

---

## Register User

Create a new user account with email and password.

**Endpoint:** `POST /api/auth/register`

**Access:** Public

**Request Body:**
```json
{
  "full_name": "John Doe",
  "email": "john.doe@example.com",
  "password": "password123",
  "phone_number": "01712345678",
  "registration_number": "2020001234",
  "dept_name": "Computer Science"
}
```

**Required Fields:**
- `full_name` (string)
- `email` (string, valid email format)
- `password` (string, minimum 6 characters)

**Optional Fields:**
- `phone_number` (string)
- `registration_number` (string)
- `dept_name` (string)

**Success Response (201):**
```json
{
  "success": true,
  "data": {
    "user": {
      "user_id": "550e8400-e29b-41d4-a716-446655440000",
      "full_name": "John Doe",
      "email": "john.doe@example.com",
      "phone_number": "01712345678",
      "registration_number": "2020001234",
      "dept_name": "Computer Science",
      "verification_status": "pending",
      "created_at": "2026-01-27T10:30:00.000Z"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

**Error Responses:**
- `400` - Missing required fields or invalid input
- `400` - User already exists with this email

---

## Login User

Authenticate a user with email and password.

**Endpoint:** `POST /api/auth/login`

**Access:** Public

**Request Body:**
```json
{
  "email": "john.doe@example.com",
  "password": "password123"
}
```

**Required Fields:**
- `email` (string)
- `password` (string)

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "user": {
      "user_id": "550e8400-e29b-41d4-a716-446655440000",
      "full_name": "John Doe",
      "email": "john.doe@example.com",
      "phone_number": "01712345678",
      "registration_number": "2020001234",
      "dept_name": "Computer Science",
      "verification_status": "pending",
      "created_at": "2026-01-27T10:30:00.000Z"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

**Error Responses:**
- `400` - Missing email or password
- `401` - Invalid credentials
- `401` - Account not created with email/password

---

## Get Current User

Get the currently authenticated user's profile.

**Endpoint:** `GET /api/auth/me`

**Access:** Private (requires JWT token)

**Headers:**
```
Authorization: Bearer <your_jwt_token>
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "full_name": "John Doe",
    "email": "john.doe@example.com",
    "phone_number": "01712345678",
    "registration_number": "2020001234",
    "dept_name": "Computer Science",
    "verification_status": "pending",
    "created_at": "2026-01-27T10:30:00.000Z"
  }
}
```

**Error Responses:**
- `401` - Not authorized, no token
- `401` - Not authorized, token failed
- `404` - User not found

---

## How to Use JWT Token

### 1. Register or Login
First, register a new account or login to get a JWT token:

```javascript
// Register
const response = await fetch('http://localhost:3000/api/auth/register', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    full_name: 'John Doe',
    email: 'john@example.com',
    password: 'password123'
  })
});

const data = await response.json();
const token = data.data.token; // Save this token
```

### 2. Use Token for Protected Routes
Include the token in the Authorization header for protected routes:

```javascript
// Example: Get current user profile
const response = await fetch('http://localhost:3000/api/auth/me', {
  method: 'GET',
  headers: {
    'Authorization': `Bearer ${token}`
  }
});

const userData = await response.json();
```

### 3. Store Token Securely
Store the token in:
- **Browser**: `localStorage` or `sessionStorage`
- **Mobile**: Secure storage (e.g., AsyncStorage, SecureStore)

```javascript
// Save token
localStorage.setItem('authToken', token);

// Retrieve token
const token = localStorage.getItem('authToken');

// Remove token (logout)
localStorage.removeItem('authToken');
```

---

## Frontend Integration Example

### React/Next.js Example

```javascript
import { useState } from 'react';

const API_BASE = 'http://localhost:3000/api';

// Register
const register = async (userData) => {
  const response = await fetch(`${API_BASE}/auth/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(userData)
  });
  
  const data = await response.json();
  if (data.success) {
    localStorage.setItem('authToken', data.data.token);
    return data.data;
  }
  throw new Error(data.error);
};

// Login
const login = async (email, password) => {
  const response = await fetch(`${API_BASE}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password })
  });
  
  const data = await response.json();
  if (data.success) {
    localStorage.setItem('authToken', data.data.token);
    return data.data;
  }
  throw new Error(data.error);
};

// Get current user
const getCurrentUser = async () => {
  const token = localStorage.getItem('authToken');
  const response = await fetch(`${API_BASE}/auth/me`, {
    headers: {
      'Authorization': `Bearer ${token}`
    }
  });
  
  const data = await response.json();
  if (data.success) {
    return data.data;
  }
  throw new Error(data.error);
};

// Logout
const logout = () => {
  localStorage.removeItem('authToken');
};
```

---

## Token Details

- **Expiration:** 30 days
- **Algorithm:** HS256
- **Payload:** Contains `userId` field
- **Secret:** Stored in `.env` as `JWT_SECRET_KEY`

---

## Security Notes

1. **Password Hashing:** Passwords are hashed using bcryptjs with salt rounds of 10
2. **Token Storage:** Never expose JWT tokens in URLs or logs
3. **HTTPS:** Always use HTTPS in production
4. **Token Expiry:** Tokens expire after 30 days - implement refresh logic if needed
5. **Validation:** All inputs are validated before processing

---

## Testing with cURL

### Register
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "full_name": "John Doe",
    "email": "john@example.com",
    "password": "password123"
  }'
```

### Login
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "password123"
  }'
```

### Get Current User
```bash
curl -X GET http://localhost:3000/api/auth/me \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

---

## Testing with Postman

1. **Register/Login:**
   - Method: POST
   - URL: `http://localhost:3000/api/auth/register` or `/api/auth/login`
   - Headers: `Content-Type: application/json`
   - Body (raw JSON): User credentials

2. **Protected Routes:**
   - Method: GET (or as required)
   - URL: Protected endpoint
   - Headers: 
     - `Content-Type: application/json`
     - `Authorization: Bearer YOUR_TOKEN`

---

## Next Steps

To protect other routes (like creating rides, etc.), add the `protect` middleware:

```javascript
// Example: Protect ride creation
const { protect } = require('../middleware/auth');

router.post('/rides', protect, asyncHandler(createRide));
```

The `req.user` object will be available in protected route controllers, containing:
```javascript
{
  userId: "550e8400-e29b-41d4-a716-446655440000"
}
```
