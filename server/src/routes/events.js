const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const Event = require('../models/Event');
const upload = require('../utils/fileUpload');

// Helper function to get file stream
const getFileStream = async (fileId) => {
  try {
    const bucket = new mongoose.mongo.GridFSBucket(mongoose.connection.db, {
      bucketName: 'uploads'
    });
    return bucket.openDownloadStream(fileId);
  } catch (error) {
    throw error;
  }
};

// GET /api/events/media/:fileId - Stream media file
router.get('/media/:fileId', async (req, res) => {
  try {
    const fileId = new mongoose.Types.ObjectId(req.params.fileId);
    const file = await mongoose.connection.db
      .collection('uploads.files')
      .findOne({ _id: fileId });

    if (!file) {
      return res.status(404).json({ error: 'File not found' });
    }

    res.set('Content-Type', file.contentType);
    const downloadStream = await getFileStream(fileId);
    downloadStream.pipe(res);
  } catch (error) {
    console.error('Error streaming file:', error);
    res.status(500).json({ error: 'Error streaming file' });
  }
});

// POST /api/events - Create a new event with media
router.post('/', upload.array('media', 5), async (req, res) => {
  try {
    const { lat, lng, category, description } = req.body;

    if (!lat || !lng || !category || !description) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    // Process uploaded files
    const mediaFiles = req.files ? req.files.map(file => ({
      fileId: file.id,
      filename: file.filename,
      contentType: file.contentType
    })) : [];

    const event = new Event({
      location: {
        type: 'Point',
        coordinates: [parseFloat(lng), parseFloat(lat)]
      },
      category,
      description,
      media: mediaFiles,
      createdBy: req.user?.id || '000000000000000000000000' // Temporary until auth is implemented
    });

    await event.save();
    res.status(201).json(event);
  } catch (error) {
    console.error('Error creating event:', error);
    res.status(500).json({ error: 'Error creating event' });
  }
});

// DELETE /api/events/:id - Delete an event and its associated media
router.delete('/:id', async (req, res) => {
  try {
    const event = await Event.findById(req.params.id);
    if (!event) {
      return res.status(404).json({ error: 'Event not found' });
    }

    // Delete associated media files
    const bucket = new mongoose.mongo.GridFSBucket(mongoose.connection.db, {
      bucketName: 'uploads'
    });

    for (const media of event.media) {
      await bucket.delete(media.fileId);
    }

    await event.deleteOne();
    res.json({ message: 'Event deleted successfully' });
  } catch (error) {
    console.error('Error deleting event:', error);
    res.status(500).json({ error: 'Error deleting event' });
  }
});

// GET /api/events - Get events within radius
router.get('/', async (req, res) => {
  try {
    const { lat, lng, radius = 5000 } = req.query; // radius in meters

    if (!lat || !lng) {
      return res.status(400).json({ error: 'Latitude and longitude are required' });
    }

    const events = await Event.find({
      location: {
        $near: {
          $geometry: {
            type: 'Point',
            coordinates: [parseFloat(lng), parseFloat(lat)]
          },
          $maxDistance: parseInt(radius)
        }
      }
    }).sort('-createdAt');

    res.json(events);
  } catch (error) {
    console.error('Error fetching events:', error);
    res.status(500).json({ error: 'Error fetching events' });
  }
});

module.exports = router; 