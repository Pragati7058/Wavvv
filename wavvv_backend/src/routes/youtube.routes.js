const express = require('express');
const youtubeController = require('../controllers/youtube.controller');
const authMiddleware = require('../middleware/auth.middleware');

const router = express.Router();

router.get('/search', authMiddleware, youtubeController.searchVideos);
router.get('/video/:id', authMiddleware, youtubeController.getVideoDetails);

module.exports = router;
