const mongoose = require('mongoose');

const paymentSchema = new mongoose.Schema({
  orderId: {
    type: String,
    required: true,
    unique: true,
    index: true
  },
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  rideId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Ride'
  },
  amount: {
    type: Number,
    required: true
  },
  currency: {
    type: String,
    default: 'BDT'
  },
  status: {
    type: String,
    enum: ['pending', 'processing', 'completed', 'failed', 'cancelled', 'refunded'],
    default: 'pending'
  },
  transactionId: {
    type: String
  },
  paymentMethod: {
    type: String
  },
  customerName: String,
  customerEmail: String,
  customerPhone: String,
  aamarPayResponse: {
    type: Object
  },
  paymentStatus: {
    type: String
  },
  paymentTime: {
    type: Date
  },
  rideFare: {
    type: Number
  },
  platformFee: {
    type: Number,
    default: 0
  },
  paymentType: {
    type: String,
    enum: ['ride_fare', 'deposit', 'subscription'],
    default: 'ride_fare'
  }
}, {
  timestamps: true
});

paymentSchema.index({ userId: 1, createdAt: -1 });
paymentSchema.index({ rideId: 1 });
paymentSchema.index({ status: 1 });

module.exports = mongoose.model('Payment', paymentSchema);