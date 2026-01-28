require('dotenv').config({ path: [".env"] });
const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');

// Import configurations
const corsOptions = require('./config/cors');
const { initDB } = require('./config/database');

// Import middleware
const errorHandler = require('./middleware/errorHandler');

// Import routes
const apiRoutes = require('./routes/index');

// Initialize Express app
const app = express();

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cors(corsOptions));

// API Routes
app.use('/api', apiRoutes);

// Root route
app.get('/', (req, res) => {
  res.status(200).json({
    success: true,
    message: "Dromos Backend API",
    version: "1.0",
    currentVersion: "v1",
    documentation: "/api/info"
  });
});

// 404 Handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: "Route not found"
  });
});

// Error Handler (must be last)
app.use(errorHandler);

// Server Configuration
const PORT = process.env.PORT || 3000;

// Start Server
const startServer = async () => {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGO_URI);
    console.log("✅ MongoDB Connected");

    // Initialize PostgreSQL Tables
    await initDB();
    console.log("✅ PostgreSQL Initialized");

    // Start Express Server
    app.listen(PORT, () => {
      console.log(`🚀 Dromos Backend running on port ${PORT}`);
      console.log(`📍 API Documentation: http://localhost:${PORT}/api/info`);
      console.log(`📍 API v1 Base: http://localhost:${PORT}/api/v1`);
    });
  } catch (error) {
    console.error("❌ Server startup failed:", error);
    process.exit(1);
  }
};

startServer();

module.exports = app;

