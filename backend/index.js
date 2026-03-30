require("dotenv").config({ path: [".env"], override: false });
const express = require("express");
const cors = require("cors");

// Import configurations
const corsOptions = require("./config/cors");
const { initDB, disconnectDB } = require("./config/database");

// Import middleware
const errorHandler = require("./middleware/errorHandler");

// Import routes
const apiRoutes = require("./routes/index");

// Initialize Express app
const app = express();


// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cors(corsOptions));

// API Routes
app.use("/api", apiRoutes);

// Root route
app.get("/api/v1", (req, res) => {
  res.status(200).json({
    success: true,
    message: "Dromos Backend API",
    version: "1.0",
    currentVersion: "v1",
  });
});

// 404 Handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: "Route not found",
  });
});

// Error Handler (must be last)
app.use(errorHandler);

// Server Configuration
const PORT = process.env.PORT || 3000;

// Start Server
const startServer = async () => {
  try {
    // Initialize Prisma Database Connection
    await initDB();
    console.log("✅ Prisma: Database connected");

    // Start Express Server
    app.listen(PORT, () => {
      console.log(`🚀 Dromos Backend running on port ${PORT}`);
      console.log(`📍 API v1 Base: http://localhost:${PORT}/api/v1`);
      console.log(`🔗 Using: Prisma ORM`);
    });
  } catch (error) {
    console.error("❌ Server startup failed:", error);
    await disconnectDB();
    process.exit(1);
  }
};

// Graceful Shutdown
process.on("SIGINT", async () => {
  console.log("\n📛 Shutting down gracefully...");
  await disconnectDB();
  process.exit(0);
});

startServer();

module.exports = app;
