const express = require('express');
const authController = require('../controllers/auth.controller');
const authMiddleware = require('../middleware/auth.middleware');

const router = express.Router();

// Verify token and return/create user record
router.post('/verify', authMiddleware, authController.verify);

module.exports = router;
