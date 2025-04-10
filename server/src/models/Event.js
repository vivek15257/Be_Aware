const mongoose = require('mongoose');

const eventSchema = new mongoose.Schema({
  location: {
    type: {
      type: String,
      enum: ['Point'],
      required: true,
      default: 'Point'
    },
    coordinates: {
      type: [Number], // [longitude, latitude]
      required: true
    }
  },
  category: {
    type: String,
    required: true,
    enum: ['ROAD_CLOSURE', 'DOG_BITE', 'HAZARD', 'OTHER']
  },
  description: {
    type: String,
    required: true,
    trim: true
  },
  media: [{
    fileId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'uploads.files'
    },
    filename: String,
    contentType: String
  }],
  upvotes: {
    type: Number,
    default: 0
  },
  downvotes: {
    type: Number,
    default: 0
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  resolved: {
    type: Boolean,
    default: false
  },
  createdAt: {
    type: Date,
    default: Date.now,
    expires: 86400 // Documents will be automatically deleted after 24 hours
  }
});

// Create a 2dsphere index for geospatial queries
eventSchema.index({ location: '2dsphere' });

const Event = mongoose.model('Event', eventSchema);

module.exports = Event; 