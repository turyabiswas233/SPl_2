/**
 * Request Validation Middleware
 * Validates incoming request data
 */

const validateRegistration = (req, res, next) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({
      success: false,
      error: "Please provide email, and password",
    });
  }

  // Email validation
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    return res.status(400).json({
      success: false,
      error: "Please provide a valid email address",
    });
  }

  next();
};

const validateLogin = (req, res, next) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({
      success: false,
      error: "Please provide email and password",
    });
  }

  next();
};

const validateRideCreation = (req, res, next) => {
  const {
    startLocation,
    startLat,
    startLng,
    destination,
    destLat,
    destLng,
    maxSeats,
  } = req.body;

  if (!startLocation || !destination || !maxSeats) {
    return res.status(400).json({
      success: false,
      error: "Missing required fields",
    });
  }

  if (
    typeof startLat !== "number" ||
    typeof startLng !== "number" ||
    typeof destLat !== "number" ||
    typeof destLng !== "number"
  ) {
    return res.status(400).json({
      success: false,
      error: "Invalid coordinates",
    });
  }

  if (maxSeats < 1 || maxSeats > 20) {
    return res.status(400).json({
      success: false,
      error: "Max seats must be between 1 and 20",
    });
  }

  next();
};

const validateMovementTracking = (req, res, next) => {
  const { ride_id, user_id, latitude, longitude } = req.body;

  if (
    !ride_id ||
    !user_id ||
    typeof latitude !== "number" ||
    typeof longitude !== "number"
  ) {
    return res.status(400).json({
      success: false,
      error: "Invalid tracking data",
    });
  }

  next();
};

const validateRating = (req, res, next) => {
  const { rating } = req.body;

  if (!rating || rating < 1 || rating > 5) {
    return res.status(400).json({
      success: false,
      error: "Rating must be between 1 and 5",
    });
  }

  next();
};

const validateUUID = (paramName) => (req, res, next) => {
  const value = req.params[paramName];
  const uuidRegex =
    /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

  if (!uuidRegex.test(value)) {
    return res.status(400).json({
      success: false,
      error: `Invalid ${paramName} format`,
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
  validateUUID,
};
