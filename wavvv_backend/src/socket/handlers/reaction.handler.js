const User = require('../../models/User');

const handleReactionEvents = (io, socket) => {
  // reaction:wave
  socket.on('reaction:wave', async (data) => {
    try {
      const { roomId, userId, username } = data;
      if (!roomId || !userId) return;

      // Broadcast reaction event to all sockets in the room
      io.in(roomId).emit('reaction:wave', {
        userId,
        username: username || socket.username,
      });

      // Increment wave statistics for user in DB
      await User.findOneAndUpdate(
        { firebaseUid: userId },
        { $inc: { 'stats.wavesCount': 1 } }
      );
    } catch (err) {
      console.error('Socket reaction:wave error:', err);
    }
  });

  // reaction:emoji
  socket.on('reaction:emoji', (data) => {
    try {
      const { roomId, userId, emoji } = data;
      if (!roomId || !emoji) return;

      // Broadcast floating emoji reaction to all room members
      io.in(roomId).emit('reaction:emoji', {
        userId: userId || socket.userId,
        emoji,
      });
    } catch (err) {
      console.error('Socket reaction:emoji error:', err);
    }
  });
};

module.exports = handleReactionEvents;
