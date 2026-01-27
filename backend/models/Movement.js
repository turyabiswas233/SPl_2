const mongoose = require('mongoose');

const MovementSchema = new mongoose.Schema({
    // Links to the Ride ID in PostgreSQL
    ride_id: { 
        type: String, 
        required: true, 
        index: true 
    },
    // Links to the User ID in PostgreSQL
    user_id: { 
        type: String, 
        required: true, 
        index: true 
    },
    // GeoJSON format for PostGIS compatibility
    location: {
        type: {
            type: String,
            enum: ['Point'],
            default: 'Point'
        },
        coordinates: {
            type: [Number], // [longitude, latitude]
            required: true
        }
    },
    speed: { type: Number },
    heading: { type: Number }, // Direction of travel
    
    // Safety feature: Auto-delete logs after 7 days
    createdAt: { 
        type: Date, 
        default: Date.now, 
        expires: 604800 // 7 days in seconds
    }
});

// Create a 2dsphere index for proximity calculations
MovementSchema.index({ location: '2dsphere' });

module.exports = mongoose.model('Movement', MovementSchema);