/**
 * Main Router
 * Combines all route modules with API versioning
 */

const express = require('express');
const router = express.Router();

// Import v1 route modules
const authRoutes = require('./v1/authRoutes');
const rideRoutes = require('./v1/rideRoutes');
const requestRoutes = require('./v1/requestRoutes');
const messageRoutes = require('./v1/messageRoutes');
const ratingRoutes = require('./v1/ratingRoutes');
const handshakeRoutes = require('./v1/handshakeRoutes');
const trackingRoutes = require('./v1/trackingRoutes');
const sosRoutes = require('./v1/sosRoutes');
const notificationRoutes = require('./v1/notificationRoutes');
const userRoutes = require('./v1/userRoutes');

// Create v1 router
const v1Router = express.Router();

// Mount v1 routes
v1Router.use('/auth', authRoutes);
v1Router.use('/rides', rideRoutes);
v1Router.use('/rides/:ride_id/requests', requestRoutes);
v1Router.use('/rides/:ride_id/messages', messageRoutes);
v1Router.use('/rides/:ride_id/ratings', ratingRoutes);
v1Router.use('/handshake', handshakeRoutes);
v1Router.use('/tracking', trackingRoutes);
v1Router.use('/sos', sosRoutes);
v1Router.use('/notifications', notificationRoutes);
v1Router.use('/users', userRoutes);

// Mount v1 router
router.use('/v1', v1Router);

// API Info Route
router.get('/info', (req, res) => {
  const apiData = {
    success: true,
    message: "Dromos Backend API - RESTful Architecture",
    version: "1.0",
    currentVersion: "v1",
    baseUrl: "/api/v1",
    endpoints: {
      auth: {
        base: "/api/v1/auth",
        routes: [
          { method: "POST", path: "/api/v1/auth/register", description: "Register a new user" },
          { method: "POST", path: "/api/v1/auth/login", description: "User login" },
          { method: "GET", path: "/api/v1/auth/me", description: "Get current user (protected)" },
          { method: "GET", path: "/api/v1/auth/studentship/:id", description: "Verify studentship" }
        ]
      },
      rides: {
        base: "/api/v1/rides",
        routes: [
          { method: "POST", path: "/api/v1/rides", description: "Create a new ride" },
          { method: "GET", path: "/api/v1/rides", description: "Get all rides" },
          { method: "GET", path: "/api/v1/rides/:ride_id", description: "Get ride by ID" },
          { method: "POST", path: "/api/v1/rides/:ride_id/complete", description: "Complete a ride" }
        ]
      },
      requests: {
        base: "/api/v1/rides/:ride_id/requests",
        routes: [
          { method: "POST", path: "/api/v1/rides/:ride_id/requests", description: "Create ride request" },
          { method: "PUT", path: "/api/v1/rides/:ride_id/requests/:request_id", description: "Update ride request" }
        ]
      },
      messages: {
        base: "/api/v1/rides/:ride_id/messages",
        routes: [
          { method: "POST", path: "/api/v1/rides/:ride_id/messages", description: "Send a message" },
          { method: "GET", path: "/api/v1/rides/:ride_id/messages", description: "Get all messages for a ride" }
        ]
      },
      ratings: {
        base: "/api/v1/rides/:ride_id/ratings",
        routes: [
          { method: "POST", path: "/api/v1/rides/:ride_id/ratings", description: "Submit a rating" }
        ]
      },
      handshake: {
        base: "/api/v1/handshake",
        routes: [
          { method: "POST", path: "/api/v1/handshake/verify", description: "Verify handshake" }
        ]
      },
      tracking: {
        base: "/api/v1/tracking",
        routes: [
          { method: "POST", path: "/api/v1/tracking/movement", description: "Track movement" }
        ]
      },
      sos: {
        base: "/api/v1/sos",
        routes: [
          { method: "POST", path: "/api/v1/sos", description: "Create SOS alert" }
        ]
      },
      notifications: {
        base: "/api/v1/notifications",
        routes: [
          { method: "GET", path: "/api/v1/notifications/:user_id", description: "Get user notifications" },
          { method: "PUT", path: "/api/v1/notifications/:notification_id/read", description: "Mark notification as read" }
        ]
      },
      users: {
        base: "/api/v1/users",
        routes: [
          { method: "GET", path: "/api/v1/users/:user_id/profile", description: "Get user profile" },
          { method: "GET", path: "/api/v1/users/:user_id/ride-history", description: "Get user ride history" }
        ]
      }
    }
  };

  // Check if request accepts HTML
  const acceptsHtml = req.headers.accept && req.headers.accept.includes('text/html');
  
  if (acceptsHtml) {
    // Serve HTML UI
    const html = `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Dromos API Documentation</title>
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }
    
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      min-height: 100vh;
      padding: 20px;
    }
    
    .container {
      max-width: 1200px;
      margin: 0 auto;
      background: white;
      border-radius: 12px;
      box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
      overflow: hidden;
    }
    
    .header {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
      padding: 40px;
      text-align: center;
    }
    
    .header h1 {
      font-size: 2.5em;
      margin-bottom: 10px;
      font-weight: 700;
    }
    
    .header p {
      font-size: 1.2em;
      opacity: 0.95;
    }
    
    .version-badge {
      display: inline-block;
      background: rgba(255, 255, 255, 0.2);
      padding: 6px 16px;
      border-radius: 20px;
      margin-top: 15px;
      font-weight: 600;
    }
    
    .content {
      padding: 40px;
    }
    
    .intro {
      text-align: center;
      margin-bottom: 40px;
      color: #666;
    }
    
    .endpoint-section {
      margin-bottom: 40px;
      background: #f8f9fa;
      border-radius: 8px;
      padding: 24px;
      border-left: 4px solid #667eea;
    }
    
    .endpoint-section h2 {
      color: #333;
      font-size: 1.5em;
      margin-bottom: 8px;
      text-transform: capitalize;
    }
    
    .base-path {
      color: #667eea;
      font-family: 'Courier New', monospace;
      font-size: 0.9em;
      margin-bottom: 20px;
      padding: 8px 12px;
      background: white;
      border-radius: 4px;
      display: inline-block;
    }
    
    .route-list {
      display: grid;
      gap: 12px;
    }
    
    .route-item {
      background: white;
      padding: 16px;
      border-radius: 6px;
      border: 1px solid #e0e0e0;
      transition: all 0.3s ease;
      display: grid;
      grid-template-columns: 80px 1fr;
      gap: 16px;
      align-items: center;
    }
    
    .route-item:hover {
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
      border-color: #667eea;
      transform: translateY(-2px);
    }
    
    .method {
      font-weight: 700;
      padding: 6px 12px;
      border-radius: 4px;
      text-align: center;
      font-size: 0.85em;
      letter-spacing: 0.5px;
    }
    
    .method.POST {
      background: #10b981;
      color: white;
    }
    
    .method.GET {
      background: #3b82f6;
      color: white;
    }
    
    .method.PUT {
      background: #f59e0b;
      color: white;
    }
    
    .method.DELETE {
      background: #ef4444;
      color: white;
    }
    
    .route-details {
      display: flex;
      flex-direction: column;
      gap: 4px;
    }
    
    .route-path {
      font-family: 'Courier New', monospace;
      color: #333;
      font-weight: 600;
      font-size: 0.95em;
    }
    
    .route-description {
      color: #666;
      font-size: 0.9em;
    }
    
    .footer {
      text-align: center;
      padding: 30px;
      background: #f8f9fa;
      color: #666;
      border-top: 1px solid #e0e0e0;
    }
    
    .stats {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 20px;
      margin-bottom: 40px;
    }
    
    .stat-card {
      background: white;
      padding: 20px;
      border-radius: 8px;
      text-align: center;
      border: 2px solid #e0e0e0;
    }
    
    .stat-card h3 {
      font-size: 2em;
      color: #667eea;
      margin-bottom: 8px;
    }
    
    .stat-card p {
      color: #666;
      font-size: 0.9em;
    }
    
    @media (max-width: 768px) {
      .header h1 {
        font-size: 1.8em;
      }
      
      .route-item {
        grid-template-columns: 1fr;
        gap: 8px;
      }
      
      .method {
        width: fit-content;
      }
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🚗 Dromos API</h1>
      <p>RESTful Backend Architecture</p>
      <span class="version-badge">Version ${apiData.currentVersion}</span>
    </div>
    
    <div class="content">
      <div class="intro">
        <p>Complete API reference for the Dromos ride-sharing platform</p>
      </div>
      
      <div class="stats">
        <div class="stat-card">
          <h3>${Object.keys(apiData.endpoints).length}</h3>
          <p>Resource Groups</p>
        </div>
        <div class="stat-card">
          <h3>${Object.values(apiData.endpoints).reduce((sum, ep) => sum + ep.routes.length, 0)}</h3>
          <p>Total Endpoints</p>
        </div>
        <div class="stat-card">
          <h3>REST</h3>
          <p>Architecture Style</p>
        </div>
      </div>
      
      ${Object.entries(apiData.endpoints).map(([key, value]) => `
        <div class="endpoint-section">
          <h2>${key}</h2>
          <div class="base-path">${value.base}</div>
          <div class="route-list">
            ${value.routes.map(route => `
              <div class="route-item">
                <span class="method ${route.method}">${route.method}</span>
                <div class="route-details">
                  <div class="route-path">${route.path}</div>
                  <div class="route-description">${route.description}</div>
                </div>
              </div>
            `).join('')}
          </div>
        </div>
      `).join('')}
    </div>
    
    <div class="footer">
      <p>Built with ❤️ for seamless ride-sharing experiences</p>
      <p style="margin-top: 10px; font-size: 0.85em;">© ${new Date().getFullYear()} Dromos - All rights reserved</p>
    </div>
  </div>
</body>
</html>
    `;
    
    res.status(200).send(html);
  } else {
    // Return JSON for API clients
    res.status(200).json(apiData);
  }
});

module.exports = router;
