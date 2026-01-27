/**
 * Request Validation Middleware
 * Validates incoming request data
 */

const validateRegistration = (req, res, next) => {
  const { full_name, email, password } = req.body;

  if (!full_name || !email || !password) {
    return res.status(400).json({ 
      success: false, 
      error: 'Please provide full name, email, and password' 
    });
  }

  // Email validation
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    return res.status(400).json({ 
      success: false, 
      error: 'Please provide a valid email address' 
    });
  }

  // Password validation (minimum 6 characters)
  if (password.length < 6) {
    return res.status(400).json({ 
      success: false, 
      error: 'Password must be at least 6 characters long' 
    });
  }

  next();
};

const validateLogin = (req, res, next) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ 
      success: false, 
      error: 'Please provide email and password' 
    });
  }

  next();
};

const validateRideCreation = (req, res, next) => {
  const { initiator_id, start_location, start_lat, start_lng, destination, dest_lat, dest_lng, max_seats } = req.body;

  if (!initiator_id || !start_location || !destination || !max_seats) {
    return res.status(400).json({ 
      success: false, 
      error: 'Missing required fields' 
    });
  }

  if (typeof start_lat !== 'number' || typeof start_lng !== 'number' || 
      typeof dest_lat !== 'number' || typeof dest_lng !== 'number') {
    return res.status(400).json({ 
      success: false, 
      error: 'Invalid coordinates' 
    });
  }

  if (max_seats < 1 || max_seats > 20) {
    return res.status(400).json({ 
      success: false, 
      error: 'Max seats must be between 1 and 20' 
    });
  }

  next();
};

const validateMovementTracking = (req, res, next) => {
  const { ride_id, user_id, latitude, longitude } = req.body;

  if (!ride_id || !user_id || typeof latitude !== 'number' || typeof longitude !== 'number') {
    return res.status(400).json({ 
      success: false, 
      error: 'Invalid tracking data' 
    });
  }

  next();
};

const validateRating = (req, res, next) => {
  const { rating } = req.body;

  if (!rating || rating < 1 || rating > 5) {
    return res.status(400).json({ 
      success: false, 
      error: 'Rating must be between 1 and 5' 
    });
  }

  next();
};

const validateUUID = (paramName) => (req, res, next) => {
  const value = req.params[paramName];
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

  if (!uuidRegex.test(value)) {
    return res.status(400).json({ 
      success: false, 
      error: `Invalid ${paramName} format` 
    });
  }

  next();
};

module.exports = {
  validateRegistration,
  validateLogin,
  validateRideCreation,
  validateMovementTracking,
  validateRating,
  validateUUID
};
