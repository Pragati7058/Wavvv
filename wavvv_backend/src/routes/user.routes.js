const express = require('express');
const userController = require('../controllers/user.controller');
const authMiddleware = require('../middleware/auth.middleware');

const router = express.Router();

router.get('/me', authMiddleware, userController.getMe);
router.put('/me', authMiddleware, userController.updateMe);
router.get('/me/history', authMiddleware, userController.getHistory);
router.get('/me/streak', authMiddleware, userController.getStreak);

module.exports = router;
