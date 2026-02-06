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
          { 
            method: "POST", 
            path: "/api/v1/auth/register", 
            description: "Register a new user",
            requestBody: {
              full_name: "John Doe",
              email: "john@example.com",
              password: "securePassword123",
              phone_number: "+1234567890",
              registration_number: "2021CS001",
              dept_name: "Computer Science"
            },
            response: {
              success: true,
              data: {
                user: {
                  user_id: "uuid-here",
                  full_name: "John Doe",
                  email: "john@example.com",
                  verification_status: "pending"
                },
                token: "jwt-token-here"
              }
            }
          },
          { 
            method: "POST", 
            path: "/api/v1/auth/login", 
            description: "User login",
            requestBody: {
              email: "john@example.com",
              password: "securePassword123"
            },
            response: {
              success: true,
              data: {
                user: {
                  user_id: "uuid-here",
                  full_name: "John Doe",
                  email: "john@example.com"
                },
                token: "jwt-token-here"
              }
            }
          },
          { 
            method: "GET", 
            path: "/api/v1/auth/me", 
            description: "Get current user (protected)",
            headers: {
              Authorization: "Bearer <jwt-token>"
            },
            response: {
              success: true,
              data: {
                user_id: "uuid-here",
                full_name: "John Doe",
                email: "john@example.com",
                verification_status: "verified"
              }
            }
          },
          { 
            method: "GET", 
            path: "/api/v1/auth/studentship/:id", 
            description: "Verify studentship",
            response: {
              success: true,
              data: {
                isStudent: true,
                registration_number: "2021CS001"
              }
            }
          }
        ]
      },
      rides: {
        base: "/api/v1/rides",
        routes: [
          { 
            method: "POST", 
            path: "/api/v1/rides", 
            description: "Create a new ride",
            requestBody: {
              initiator_id: "user-uuid",
              start_location: "University Gate",
              start_lat: 23.8103,
              start_lng: 90.4125,
              destination: "Airport",
              dest_lat: 23.8432,
              dest_lng: 90.3978,
              max_seats: 4
            },
            response: {
              success: true,
              data: {
                ride_id: "ride-uuid",
                initiator_id: "user-uuid",
                start_location: "University Gate",
                destination_name: "Airport",
                trip_qr_code: "generated-qr-code",
                trip_otp: "123456",
                status: "open"
              }
            }
          },
          { 
            method: "GET", 
            path: "/api/v1/rides", 
            description: "Get all rides (Query params: gender_filter, min_seats, destination)",
            response: {
              success: true,
              count: 2,
              data: [
                {
                  ride_id: "ride-uuid",
                  initiator_name: "John Doe",
                  start_location: "University Gate",
                  destination_name: "Airport",
                  max_seats: 4,
                  current_passengers: 2,
                  status: "open"
                }
              ]
            }
          },
          { 
            method: "GET", 
            path: "/api/v1/rides/:ride_id", 
            description: "Get ride by ID",
            response: {
              success: true,
              data: {
                ride_id: "ride-uuid",
                initiator_id: "user-uuid",
                start_location: "University Gate",
                destination_name: "Airport",
                status: "open",
                created_at: "2026-02-06T10:00:00Z"
              }
            }
          },
          { 
            method: "POST", 
            path: "/api/v1/rides/:ride_id/complete", 
            description: "Complete a ride",
            requestBody: {
              initiator_id: "user-uuid"
            },
            response: {
              success: true,
              message: "Ride completed successfully"
            }
          }
        ]
      },
      requests: {
        base: "/api/v1/rides/:ride_id/requests",
        routes: [
          { 
            method: "POST", 
            path: "/api/v1/rides/:ride_id/requests", 
            description: "Create ride request",
            requestBody: {
              requester_id: "user-uuid"
            },
            response: {
              success: true,
              data: {
                request_id: "request-uuid",
                ride_id: "ride-uuid",
                requester_id: "user-uuid",
                status: "pending"
              }
            }
          },
          { 
            method: "PUT", 
            path: "/api/v1/rides/:ride_id/requests/:request_id", 
            description: "Update ride request (accept/reject)",
            requestBody: {
              action: "accept",
              meeting_lat: 23.8103,
              meeting_lng: 90.4125
            },
            response: {
              success: true,
              message: "Request accepted"
            }
          }
        ]
      },
      messages: {
        base: "/api/v1/rides/:ride_id/messages",
        routes: [
          { 
            method: "POST", 
            path: "/api/v1/rides/:ride_id/messages", 
            description: "Send a message",
            requestBody: {
              sender_id: "user-uuid",
              message_text: "On my way!"
            },
            response: {
              success: true,
              data: {
                message_id: "message-uuid",
                ride_id: "ride-uuid",
                sender_id: "user-uuid",
                message_text: "On my way!",
                created_at: "2026-02-06T10:00:00Z"
              }
            }
          },
          { 
            method: "GET", 
            path: "/api/v1/rides/:ride_id/messages", 
            description: "Get all messages for a ride",
            response: {
              success: true,
              count: 5,
              data: [
                {
                  message_id: "message-uuid",
                  sender_name: "John Doe",
                  message_text: "On my way!",
                  created_at: "2026-02-06T10:00:00Z"
                }
              ]
            }
          }
        ]
      },
      ratings: {
        base: "/api/v1/rides/:ride_id/ratings",
        routes: [
          { 
            method: "POST", 
            path: "/api/v1/rides/:ride_id/ratings", 
            description: "Submit a rating",
            requestBody: {
              rater_id: "user-uuid",
              rated_user_id: "user-uuid",
              rating: 5,
              comment: "Great ride!"
            },
            response: {
              success: true,
              data: {
                rating_id: "rating-uuid",
                rating: 5,
                comment: "Great ride!"
              }
            }
          }
        ]
      },
      handshake: {
        base: "/api/v1/handshake",
        routes: [
          { 
            method: "POST", 
            path: "/api/v1/handshake/verify", 
            description: "Verify handshake",
            requestBody: {
              ride_id: "ride-uuid",
              user_id: "user-uuid",
              verification_code: "123456"
            },
            response: {
              success: true,
              message: "Handshake verified"
            }
          }
        ]
      },
      tracking: {
        base: "/api/v1/tracking",
        routes: [
          { 
            method: "POST", 
            path: "/api/v1/tracking/movement", 
            description: "Track movement",
            requestBody: {
              ride_id: "ride-uuid",
              user_id: "user-uuid",
              latitude: 23.8103,
              longitude: 90.4125
            },
            response: {
              success: true,
              message: "Location updated"
            }
          }
        ]
      },
      sos: {
        base: "/api/v1/sos",
        routes: [
          { 
            method: "POST", 
            path: "/api/v1/sos", 
            description: "Create SOS alert",
            requestBody: {
              user_id: "user-uuid",
              ride_id: "ride-uuid",
              latitude: 23.8103,
              longitude: 90.4125,
              message: "Emergency help needed"
            },
            response: {
              success: true,
              data: {
                sos_id: "sos-uuid",
                status: "active"
              }
            }
          }
        ]
      },
      notifications: {
        base: "/api/v1/notifications",
        routes: [
          { 
            method: "GET", 
            path: "/api/v1/notifications/:user_id", 
            description: "Get user notifications",
            response: {
              success: true,
              count: 3,
              data: [
                {
                  notification_id: "notif-uuid",
                  message: "Your ride request was accepted",
                  is_read: false,
                  created_at: "2026-02-06T10:00:00Z"
                }
              ]
            }
          },
          { 
            method: "PUT", 
            path: "/api/v1/notifications/:notification_id/read", 
            description: "Mark notification as read",
            response: {
              success: true,
              message: "Notification marked as read"
            }
          }
        ]
      },
      users: {
        base: "/api/v1/users",
        routes: [
          { 
            method: "GET", 
            path: "/api/v1/users/:user_id/profile", 
            description: "Get user profile",
            response: {
              success: true,
              data: {
                user_id: "user-uuid",
                full_name: "John Doe",
                email: "john@example.com",
                phone_number: "+1234567890",
                verification_status: "verified"
              }
            }
          },
          { 
            method: "GET", 
            path: "/api/v1/users/:user_id/ride-history", 
            description: "Get user ride history",
            response: {
              success: true,
              count: 10,
              data: [
                {
                  ride_id: "ride-uuid",
                  start_location: "University Gate",
                  destination_name: "Airport",
                  status: "completed",
                  created_at: "2026-02-05T10:00:00Z"
                }
              ]
            }
          }
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
    }
    
    .route-item:hover {
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
      border-color: #667eea;
    }
    
    .route-header {
      display: grid;
      grid-template-columns: 80px 1fr auto;
      gap: 16px;
      align-items: center;
      cursor: pointer;
    }
    
    .expand-icon {
      color: #667eea;
      font-size: 1.2em;
      transition: transform 0.3s ease;
    }
    
    .expand-icon.expanded {
      transform: rotate(180deg);
    }
    
    .route-examples {
      margin-top: 16px;
      padding-top: 16px;
      border-top: 1px solid #e0e0e0;
      display: none;
    }
    
    .route-examples.show {
      display: block;
    }
    
    .example-section {
      margin-bottom: 16px;
    }
    
    .example-section h4 {
      color: #667eea;
      font-size: 0.9em;
      margin-bottom: 8px;
      text-transform: uppercase;
      font-weight: 600;
    }
    
    .example-code {
      background: #1e1e1e;
      color: #d4d4d4;
      padding: 12px;
      border-radius: 4px;
      font-family: 'Courier New', monospace;
      font-size: 0.85em;
      overflow-x: auto;
      line-height: 1.5;
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
    
    .json-example {
      background: #1e1e1e;
      color: #d4d4d4;
      padding: 20px;
      border-radius: 8px;
      margin-bottom: 40px;
      overflow-x: auto;
      border: 2px solid #667eea;
    }
    
    .json-example h3 {
      color: #667eea;
      margin-bottom: 15px;
      font-size: 1.2em;
    }
    
    .json-example pre {
      margin: 0;
      font-family: 'Courier New', monospace;
      font-size: 0.9em;
      line-height: 1.6;
    }
    
    .json-key {
      color: #c8ddf8;
    }
    
    .json-string {
      color: #f05314;
    }
    
    .json-number {
      color: #5cf10b;
    }
    
    .json-boolean {
      color: #569cd6;
    }
    
    .json-bracket {
      color: #f004f0;
      font-weight: bold;
    }
    
    @media (max-width: 768px) {
      .header h1 {
      font-size: 1.8em;
      }
      
      .route-item {
      position: relative;
      }
      
      .route-header {
      grid-template-columns: 1fr;
      gap: 8px;
      }
      
      .method {
      width: fit-content;
      }
      
      .expand-icon {
      position: absolute;
      right: 16px;
      top: 16px;
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
        ${value.routes.map((route, index) => `
          <div class="route-item">
          <div class="route-header" onclick="toggleRoute('${key}-${index}')">
            <span class="method ${route.method}">${route.method}</span>
            <div class="route-details">
            <div class="route-path">${route.path}</div>
            <div class="route-description">${route.description}</div>
            </div>
            <span class="expand-icon" id="icon-${key}-${index}">▼</span>
          </div>
          <div class="route-examples" id="examples-${key}-${index}">
            ${route.headers ? `
            <div class="example-section">
              <h4>📋 Required Headers</h4>
              <div class="example-code">${JSON.stringify(route.headers, null, 2)
              .replace(/&/g, '&amp;')
              .replace(/</g, '&lt;')
              .replace(/>/g, '&gt;')
              .replace(/"([^"]+)":/g, '<span class="json-key">"$1"</span>:')
              .replace(/: "([^"]*)"/g, ': <span class="json-string">"$1"</span>')
              }</div>
            </div>
            ` : ''}
            ${route.requestBody ? `
            <div class="example-section">
              <h4>📤 Request Body</h4>
              <pre class="example-code">${JSON.stringify(route.requestBody, null, 2)
              .replace(/&/g, '&amp;')
              .replace(/</g, '&lt;')
              .replace(/>/g, '&gt;')
              .replace(/"([^"]+)":/g, '<span class="json-key">"$1"</span>:')
              .replace(/: "([^"]*)"/g, ': <span class="json-string">"$1"</span>')
              .replace(/: (\d+\.?\d*)/g, ': <span class="json-number">$1</span>')
              .replace(/: (true|false)/g, ': <span class="json-boolean">$1</span>')
              }</pre>
            </div>
            ` : ''}
            ${route.response ? `
            <div class="example-section">
              <h4>📥 Response Example</h4>
              <pre class="example-code">${JSON.stringify(route.response, null, 2)
              .replace(/&/g, '&amp;')
              .replace(/</g, '&lt;')
              .replace(/>/g, '&gt;')
              .replace(/"([^"]+)":/g, '<span class="json-key">"$1"</span>:')
              .replace(/: "([^"]*)"/g, ': <span class="json-string">"$1"</span>')
              .replace(/: (\d+\.?\d*)/g, ': <span class="json-number">$1</span>')
              .replace(/: (true|false)/g, ': <span class="json-boolean">$1</span>')
              .replace(/: (\[)/g, ': <span class="json-bracket"><b>$1</b></span>')
              }</pre>
            </div>
            ` : ''}
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
    
    <script>
    function toggleRoute(id) {
      const examples = document.getElementById('examples-' + id);
      const icon = document.getElementById('icon-' + id);
      
      if (examples.classList.contains('show')) {
      examples.classList.remove('show');
      icon.classList.remove('expanded');
      } else {
      examples.classList.add('show');
      icon.classList.add('expanded');
      }
    }
    </script>
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
