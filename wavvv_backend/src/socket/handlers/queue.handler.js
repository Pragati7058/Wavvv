const Room = require('../../models/Room');

const handleQueueEvents = (io, socket) => {
  // Helpers
  const getSortedQueue = (room) => {
    // Sort logic: primary sort by votes count descending, secondary by creation order/original index
    return room.queue.sort((a, b) => {
      const voteDiff = (b.votes || []).length - (a.votes || []).length;
      if (voteDiff !== 0) return voteDiff;
      return a.order - b.order;
    });
  };

  const broadcastQueue = (roomId, queue) => {
    io.in(roomId).emit('queue:updated', { queue });
  };

  // queue:add
  socket.on('queue:add', async (data) => {
    try {
      const { roomId, userId, username, videoId, videoTitle, videoThumbnail } = data;
      if (!roomId || !videoId) return;

      const room = await Room.findById(roomId);
      if (!room) return;

      // Avoid duplicates of the same video in queue
      const alreadyQueued = room.queue.some((item) => item.videoId === videoId);
      if (alreadyQueued) {
        socket.emit('error', { message: 'Video is already in the queue.' });
        return;
      }

      const nextOrder = room.queue.length;

      room.queue.push({
        videoId,
        videoTitle: videoTitle || 'YouTube Video',
        videoThumbnail: videoThumbnail || '',
        addedBy: username || 'User',
        votes: [userId], // User automatically votes for their added video
        order: nextOrder,
      });

      await room.save();
      broadcastQueue(roomId, getSortedQueue(room));
    } catch (err) {
      console.error('Socket queue:add error:', err);
    }
  });

  // queue:vote
  socket.on('queue:vote', async (data) => {
    try {
      const { roomId, userId, queueItemId } = data;
      if (!roomId || !queueItemId || !userId) return;

      const room = await Room.findById(roomId);
      if (!room) return;

      const queueItem = room.queue.id(queueItemId);
      if (!queueItem) return;

      // If user already voted, remove vote. Else add vote (toggle action)
      const voteIndex = queueItem.votes.indexOf(userId);
      if (voteIndex > -1) {
        queueItem.votes.splice(voteIndex, 1);
      } else {
        queueItem.votes.push(userId);
      }

      await room.save();
      broadcastQueue(roomId, getSortedQueue(room));
    } catch (err) {
      console.error('Socket queue:vote error:', err);
    }
  });

  // queue:remove
  socket.on('queue:remove', async (data) => {
    try {
      const { roomId, queueItemId } = data;
      if (!roomId || !queueItemId) return;

      const room = await Room.findById(roomId);
      if (!room) return;

      // Pull item from array
      room.queue.pull({ _id: queueItemId });

      // Re-normalize order keys
      room.queue.forEach((item, index) => {
        item.order = index;
      });

      await room.save();
      broadcastQueue(roomId, getSortedQueue(room));
    } catch (err) {
      console.error('Socket queue:remove error:', err);
    }
  });

  // queue:reorder
  socket.on('queue:reorder', async (data) => {
    try {
      const { roomId, newOrder } = data; // Array of item IDs in the new order
      if (!roomId || !Array.isArray(newOrder)) return;

      const room = await Room.findById(roomId);
      if (!room) return;

      // Map queue items to their new indices
      newOrder.forEach((id, index) => {
        const item = room.queue.id(id);
        if (item) {
          item.order = index;
        }
      });

      await room.save();
      broadcastQueue(roomId, getSortedQueue(room));
    } catch (err) {
      console.error('Socket queue:reorder error:', err);
    }
  });
};

module.exports = handleQueueEvents;
