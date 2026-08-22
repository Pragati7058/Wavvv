const Room = require('../../models/Room');
const User = require('../../models/User');
const Message = require('../../models/Message');

const formatTime = (secs) => {
  const m = Math.floor(secs / 60);
  const s = Math.floor(secs % 60);
  return `${m}:${s < 10 ? '0' : ''}${s}`;
};

const handleClipEvents = (io, socket) => {
  socket.on('clip:mark', async (data) => {
    try {
      const { roomId, userId, username, positionSeconds } = data;
      if (!roomId || !userId || positionSeconds === undefined) return;

      const user = await User.findOne({ firebaseUid: userId });
      if (!user) return;

      const room = await Room.findById(roomId);
      if (!room) return;

      // Add moment to room array
      room.clipMoments.push({
        userId: user._id,
        username: username || socket.username,
        positionSeconds,
        createdAt: new Date(),
      });
      await room.save();

      // Increment stats in user
      user.stats.clipsMarked = (user.stats.clipsMarked || 0) + 1;
      await user.save();

      // Broadcast new clip to room
      io.in(roomId).emit('clip:new', {
        userId: user._id,
        username: username || socket.username,
        positionSeconds,
      });

      // Inject system message in chat history
      const timeStr = formatTime(positionSeconds);
      const textMessage = `${username || socket.username} marked ${timeStr} 🔥 — tap to jump`;
      
      const msg = await Message.create({
        roomId,
        userId: null, // system message has no user ID
        username: 'Wavvv',
        text: textMessage,
        type: 'system',
      });

      // Broadcast system message in real-time
      io.in(roomId).emit('chat:new_message', {
        messageId: msg._id,
        userId: null,
        username: msg.username,
        text: msg.text,
        type: 'system',
        createdAt: msg.createdAt,
      });
    } catch (err) {
      console.error('Socket clip:mark error:', err);
    }
  });
};

module.exports = handleClipEvents;
