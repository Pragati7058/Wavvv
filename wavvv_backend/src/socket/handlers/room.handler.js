const Room = require('../../models/Room');

const MAX_MEMBERS_PER_ROOM = 50;

const handleRoomEvents = (io, socket) => {
  // room:join
  socket.on('room:join', async (data) => {
    try {
      const { roomId, userId, username, ghostMode } = data;
      if (!roomId || !userId) return;

      socket.roomId = roomId;
      socket.userId = userId;
      socket.username = username || 'Guest';
      socket.ghostMode = !!ghostMode;

      // Check member count before joining
      const activeSockets = await io.in(roomId).fetchSockets();
      if (activeSockets.length >= MAX_MEMBERS_PER_ROOM) {
        socket.emit('room:full', {
          message: `This room is full! Maximum ${MAX_MEMBERS_PER_ROOM} viewers allowed.`,
          max: MAX_MEMBERS_PER_ROOM,
        });
        console.log(`Room ${roomId} is full (${activeSockets.length}/${MAX_MEMBERS_PER_ROOM}). Rejecting ${username}.`);
        return;
      }

      // Join the socket.io room
      socket.join(roomId);

      const room = await Room.findById(roomId);
      if (!room) {
        socket.emit('error', { message: 'Room not found.' });
        return;
      }

      // Check if user is host
      socket.isHost = room.hostId.toString() === userId.toString();

      // Gather active member list in the room
      const currentSockets = await io.in(roomId).fetchSockets();
      const members = currentSockets.map((s) => ({
        userId: s.userId,
        username: s.username,
        isGhost: s.ghostMode,
        isHost: s.isHost,
      }));

      // Send current state back to the newly joined client
      socket.emit('room:state', {
        isPlaying: false, // fallback, firestore holds main state
        positionSeconds: 0,
        videoId: room.videoId,
        videoTitle: room.videoTitle,
        videoThumbnail: room.videoThumbnail,
        members,
        queue: room.queue,
      });

      // Broadcast to other members that a new user joined
      socket.to(roomId).emit('room:user_joined', {
        userId,
        username: socket.username,
        isGhost: socket.ghostMode,
      });

      // Emit status update of in-sync users
      const totalMembers = members.length;
      const inSyncCount = members.filter((m) => !m.isGhost).length;
      io.in(roomId).emit('sync:status', { inSync: inSyncCount, total: totalMembers, max: MAX_MEMBERS_PER_ROOM });

      console.log(`Socket client joined room: ${roomId}, user: ${username} (Ghost: ${ghostMode})`);
    } catch (err) {
      console.error('Socket room:join error:', err);
    }
  });

  // room:leave
  socket.on('room:leave', async (data) => {
    try {
      const { roomId, userId } = data;
      if (!roomId || !userId) return;

      socket.to(roomId).emit('room:user_left', {
        userId,
        username: socket.username,
      });

      socket.leave(roomId);
      console.log(`Socket client manually left room: ${roomId}, user: ${userId}`);
    } catch (err) {
      console.error('Socket room:leave error:', err);
    }
  });

  // playback:play
  socket.on('playback:play', (data) => {
    const { roomId, positionSeconds } = data;
    if (!roomId) return;
    // Broadcast playback change to all room members (guests)
    socket.to(roomId).emit('playback:update', {
      isPlaying: true,
      positionSeconds,
    });
  });

  // playback:pause
  socket.on('playback:pause', (data) => {
    const { roomId, positionSeconds } = data;
    if (!roomId) return;
    socket.to(roomId).emit('playback:update', {
      isPlaying: false,
      positionSeconds,
    });
  });

  // playback:seek
  socket.on('playback:seek', (data) => {
    const { roomId, positionSeconds } = data;
    if (!roomId) return;
    socket.to(roomId).emit('playback:update', {
      isPlaying: undefined, // keep current play state
      positionSeconds,
    });
  });

  // video:change
  socket.on('video:change', async (data) => {
    try {
      const { roomId, videoId, videoTitle, videoThumbnail } = data;
      if (!roomId || !videoId) return;

      // Update room in DB
      const room = await Room.findById(roomId);
      if (room) {
        room.videoId = videoId;
        room.videoTitle = videoTitle || '';
        room.videoThumbnail = videoThumbnail || '';
        await room.save();
      }

      // Broadcast changes to everyone in the room
      io.in(roomId).emit('room:state_update', {
        videoId,
        videoTitle,
        videoThumbnail,
      });
    } catch (err) {
      console.error('Socket video:change error:', err);
    }
  });

  // Host Rewind trigger
  socket.on('rewind:trigger', async (data) => {
    try {
      const { roomId, userId } = data;
      if (!roomId) return;

      // Count down 3... 2... 1...
      let countdown = 3;
      const interval = setInterval(() => {
        io.in(roomId).emit('rewind:countdown', { count: countdown });
        countdown--;
        if (countdown < 0) {
          clearInterval(interval);
          // Trigger execute (rewind 10s on client)
          io.in(roomId).emit('rewind:execute', { triggerBy: socket.username });
        }
      }, 1000);
    } catch (err) {
      console.error('Socket rewind trigger error:', err);
    }
  });
};

module.exports = handleRoomEvents;
