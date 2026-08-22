const Message = require('../../models/Message');
const Room = require('../../models/Room');

const handleChatEvents = (io, socket) => {
  socket.on('chat:message', async (data) => {
    try {
      const { roomId, userId, username, text } = data;
      if (!roomId || !text) return;

      // Save to database
      const msg = await Message.create({
        roomId,
        userId: userId || null,
        username: username || 'Guest',
        text: text.substring(0, 500),
        type: 'text',
      });

      // Increment message count on room
      await Room.findByIdAndUpdate(roomId, { $inc: { messageCount: 1 } });

      // Broadcast to room
      io.in(roomId).emit('chat:new_message', {
        messageId: msg._id,
        userId: msg.userId,
        username: msg.username,
        text: msg.text,
        type: msg.type,
        createdAt: msg.createdAt,
      });
    } catch (err) {
      console.error('Socket chat:message error:', err);
    }
  });
};

module.exports = handleChatEvents;
