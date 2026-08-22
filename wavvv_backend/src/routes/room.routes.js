const express = require('express');
const roomController = require('../controllers/room.controller');
const authMiddleware = require('../middleware/auth.middleware');

const router = express.Router();

router.post('/', authMiddleware, roomController.createRoom);
router.get('/recent', authMiddleware, roomController.getRecentRooms);
router.get('/code/:code', authMiddleware, roomController.getRoomByCode);

router.get('/:roomId', authMiddleware, roomController.getRoomById);
router.post('/:roomId/join', authMiddleware, roomController.joinRoom);
router.post('/:roomId/leave', authMiddleware, roomController.leaveRoom);
router.delete('/:roomId', authMiddleware, roomController.deleteRoom);

router.get('/:roomId/messages', authMiddleware, roomController.getRoomMessages);

module.exports = router;
