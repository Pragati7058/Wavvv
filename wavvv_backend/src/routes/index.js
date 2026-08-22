const express = require('express');
const authRoutes = require('./auth.routes');
const userRoutes = require('./user.routes');
const roomRoutes = require('./room.routes');
const youtubeRoutes = require('./youtube.routes');

const router = express.Router();

// Mount API routes
router.use('/auth', authRoutes);
router.use('/users', userRoutes);
router.use('/rooms', roomRoutes);
router.use('/youtube', youtubeRoutes);

module.exports = router;
