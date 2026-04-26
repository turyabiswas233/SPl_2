require("dotenv").config({ path: [".env"], override: false });
const express = require("express");
const cors = require("cors");
const swaggerJsdoc = require("swagger-jsdoc");
const swaggerUi = require("swagger-ui-express");

// Import configurations
const corsOptions = require("./config/cors");
const { initDB, disconnectDB } = require("./config/database");

// Import middleware
const errorHandler = require("./middleware/errorHandler");

// Import routes
const apiRoutes = require("./routes/index");

// Initialize Express app
const app = express();
const { Server } = require("socket.io");
const connectMongoDB = require("./db/mongoose");
const server = require("http").createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST", "PUT", "DELETE", "PATCH"],
  },
});

// Swagger definition
const swaggerDefinition = {
  openapi: "3.0.0",
  info: {
    title: "Dromos Backend API",
    version: "1.0.0",
    description: "API documentation for Dromos ride-sharing backend",
  },
  servers: [
    {
      url: `http://localhost:${process.env.PORT || 3000}`,
      description: "Development server",
    },
  ],
  components: {
    securitySchemes: {
      bearerAuth: {
        type: "http",
        scheme: "bearer",
        bearerFormat: "JWT",
      },
    },
  },
  security: [
    {
      bearerAuth: [],
    },
  ],
};

const options = {
  swaggerDefinition,
  apis: ["./routes/**/*.js", "./controllers/**/*.js"], // Paths to files containing OpenAPI definitions
};

const swaggerSpec = swaggerJsdoc(options);

// Middleware
const jsonParser = express.json();
const urlencodedParser = express.urlencoded({ extended: true });

app.use((req, res, next) => {
  if (req.originalUrl.startsWith("/api/v1/payments/webhook/stripe")) {
    return next();
  }

  return jsonParser(req, res, next);
});

app.use((req, res, next) => {
  if (req.originalUrl.startsWith("/api/v1/payments/webhook/stripe")) {
    return next();
  }

  return urlencodedParser(req, res, next);
});

app.use(cors(corsOptions));

// Swagger route
app.use("/api/docs", swaggerUi.serve, swaggerUi.setup(swaggerSpec));

// API Routes
app.use("/api", apiRoutes);

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
    await connectMongoDB();

    // Start Express Server
    server.listen(PORT, () => {
      console.log(`🚀 Dromos Backend running on port ${PORT}`);
      console.log(`📍 API (v1) Docs: http://localhost:${PORT}/api/docs`);
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

module.exports = {
  app,
  io,
  server,
};
