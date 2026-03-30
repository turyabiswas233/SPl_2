const jwt = require("jsonwebtoken");
const { clog } = require("../utils/log");

// Protect routes - verify JWT token
const protect = async (req, res, next) => {
  let token;

  // Check if token exists in headers
  if (
    req.headers.authorization &&
    req.headers.authorization.startsWith("Bearer")
  ) {
    try {
      // Get token from header (format: "Bearer <token>")
      token = req.headers.authorization.split(" ")[1] || "";

      // Verify token
      const decoded = jwt.verify(token, process.env.JWT_SECRET_KEY);

      // Add user info to request
      req.user = decoded;
      clog(`User authenticated: ${req.user.userId}`, "info");
      next();
    } catch (err) {
      clog("Token verification failed:" + err, "error");
      return res.status(401).json({
        success: false,
        error: "Not authorized, token failed",
      });
    }
  }

  if (!token) {
    return res.status(401).json({
      success: false,
      error: "Not authorized, no token",
    });
  }
};

module.exports = { protect };
