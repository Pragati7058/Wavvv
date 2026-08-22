const { Server } = require('socket.io');
const { verifyFirebaseToken } = require('../config/firebase');
const handleRoomEvents = require('./handlers/room.handler');
const handleChatEvents = require('./handlers/chat.handler');
const handleReactionEvents = require('./handlers/reaction.handler');
const handleQueueEvents = require('./handlers/queue.handler');
const handleClipEvents = require('./handlers/clip.handler');

const initSocket = (server) => {
  const io = new Server(server, {
    cors: {
      origin: '*', // Allow all origins for mobile/client access
      methods: ['GET', 'POST'],
    },
  });

  // Socket.io Handshake Token Verification
  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth?.token || socket.handshake.query?.token;
      
      if (!token) {
        return next(new Error('Authentication failed: Missing authorization token.'));
      }

      const decoded = await verifyFirebaseToken(token);
      socket.firebaseUser = decoded;
      next();
    } catch (error) {
      console.error('Socket Auth Middleware Error:', error.message);
      return next(new Error(`Authentication failed: ${error.message}`));
    }
  });

  io.on('connection', (socket) => {
    console.log(`🟢 Socket client connected: ${socket.id} (UID: ${socket.firebaseUser.uid})`);

    // Mount sub-handlers
    handleRoomEvents(io, socket);
    handleChatEvents(io, socket);
    handleReactionEvents(io, socket);
    handleQueueEvents(io, socket);
    handleClipEvents(io, socket);

    socket.on('disconnect', async () => {
      console.log(`🔴 Socket client disconnected: ${socket.id}`);
      
      // Clean up room associations and notify other members
      const { roomId, userId, username, ghostMode } = socket;
      if (roomId && userId) {
        socket.to(roomId).emit('room:user_left', {
          userId,
          username: username || 'Guest',
        });

        // Re-calculate active room syncing counts
        const activeSockets = await io.in(roomId).fetchSockets();
        const members = activeSockets.map((s) => ({
          userId: s.userId,
          username: s.username,
          isGhost: s.ghostMode,
          isHost: s.isHost,
        }));
        
        io.in(roomId).emit('sync:status', {
          inSync: members.length, // baseline active sockets
          total: members.length,
        });
      }
    });
  });

  return io;
};

module.exports = initSocket;
