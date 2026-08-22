const Room = require('../models/Room');
const Message = require('../models/Message');
const User = require('../models/User');

const generateRoomCode = () => {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let code = '';
  for (let i = 0; i < 6; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return code;
};

const createRoom = async (req, res, next) => {
  try {
    const user = req.user;
    if (!user) {
      return res.status(404).json({ error: 'User not registered.' });
    }

    const { videoId, videoTitle, videoThumbnail } = req.body;

    // Generate unique 6-digit code
    let roomCode = generateRoomCode();
    let codeExists = await Room.findOne({ roomCode, isActive: true });
    let attempts = 0;
    while (codeExists && attempts < 10) {
      roomCode = generateRoomCode();
      codeExists = await Room.findOne({ roomCode, isActive: true });
      attempts++;
    }

    const room = await Room.create({
      roomCode,
      hostId: user._id,
      hostFirebaseUid: user.firebaseUid,
      hostUsername: user.username,
      videoId: videoId || '',
      videoTitle: videoTitle || '',
      videoThumbnail: videoThumbnail || '',
      queue: [],
      clipMoments: [],
      memberCount: 0,
      messageCount: 0,
      isActive: true,
      createdAt: new Date(),
    });

    // Update user stats
    user.stats.roomsCreated = (user.stats.roomsCreated || 0) + 1;
    await user.save();

    res.status(201).json(room);
  } catch (error) {
    next(error);
  }
};

const getRoomById = async (req, res, next) => {
  try {
    const { roomId } = req.params;
    const room = await Room.findById(roomId);
    if (!room || !room.isActive) {
      return res.status(404).json({ error: 'Room not found or is inactive.' });
    }
    res.status(200).json(room);
  } catch (error) {
    next(error);
  }
};

const getRoomByCode = async (req, res, next) => {
  try {
    const { code } = req.params;
    const room = await Room.findOne({ roomCode: code.toUpperCase(), isActive: true });
    if (!room) {
      return res.status(404).json({ error: 'Room code not found.' });
    }
    res.status(200).json(room);
  } catch (error) {
    next(error);
  }
};

const joinRoom = async (req, res, next) => {
  try {
    const user = req.user;
    if (!user) {
      return res.status(404).json({ error: 'User not registered.' });
    }

    const { roomId } = req.params;
    const room = await Room.findById(roomId);

    if (!room || !room.isActive) {
      return res.status(404).json({ error: 'Room not found or inactive.' });
    }

    // Increment member count in db
    room.memberCount = (room.memberCount || 0) + 1;
    await room.save();

    // Increment user stats
    user.stats.roomsJoined = (user.stats.roomsJoined || 0) + 1;

    // Check & update user's watch history
    if (room.videoId) {
      const historyItem = {
        videoId: room.videoId,
        videoTitle: room.videoTitle,
        videoThumbnail: room.videoThumbnail,
        roomId: room._id,
        watchedAt: new Date(),
      };
      
      // Keep watchHistory size bounded if needed (e.g. 50 items)
      user.watchHistory.push(historyItem);
      if (user.watchHistory.length > 50) {
        user.watchHistory.shift();
      }

      // Update Watch Streak
      const now = new Date();
      const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
      
      if (!user.watchStreak) {
        user.watchStreak = { current: 1, longest: 1, lastWatchDate: today };
      } else {
        const streak = user.watchStreak;
        if (!streak.lastWatchDate) {
          streak.current = 1;
          streak.longest = Math.max(streak.longest || 0, 1);
          streak.lastWatchDate = today;
        } else {
          const lastWatch = new Date(streak.lastWatchDate);
          const lastWatchDay = new Date(lastWatch.getFullYear(), lastWatch.getMonth(), lastWatch.getDate());
          
          const diffTime = today - lastWatchDay;
          const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));

          if (diffDays === 1) {
            // Consecutive day watch!
            streak.current = (streak.current || 0) + 1;
            streak.longest = Math.max(streak.longest || 0, streak.current);
            streak.lastWatchDate = today;
          } else if (diffDays > 1) {
            // Broke streak, reset
            streak.current = 1;
            streak.lastWatchDate = today;
          }
          // If diffDays === 0, they already watched today, streak stays active, do not change
        }
      }
    }

    await user.save();
    res.status(200).json({ room, user });
  } catch (error) {
    next(error);
  }
};

const leaveRoom = async (req, res, next) => {
  try {
    const { roomId } = req.params;
    const room = await Room.findById(roomId);

    if (room) {
      room.memberCount = Math.max(0, (room.memberCount || 0) - 1);
      await room.save();
    }
    
    res.status(200).json({ success: true });
  } catch (error) {
    next(error);
  }
};

const deleteRoom = async (req, res, next) => {
  try {
    const user = req.user;
    const { roomId } = req.params;
    const room = await Room.findById(roomId);

    if (!room) {
      return res.status(404).json({ error: 'Room not found.' });
    }

    // Verify requesting user is the host
    if (room.hostId.toString() !== user._id.toString()) {
      return res.status(403).json({ error: 'Forbidden: Only the room host can delete the room.' });
    }

    room.isActive = false;
    room.endedAt = new Date();
    await room.save();

    res.status(200).json({ success: true, message: 'Room successfully closed.' });
  } catch (error) {
    next(error);
  }
};

const getRoomMessages = async (req, res, next) => {
  try {
    const { roomId } = req.params;
    const messages = await Message.find({ roomId })
      .sort({ createdAt: 1 })
      .limit(100); // retrieve last 100 messages chronologically
    res.status(200).json(messages);
  } catch (error) {
    next(error);
  }
};

const getRecentRooms = async (req, res, next) => {
  try {
    const user = req.user;
    if (!user) {
      return res.status(404).json({ error: 'User not found.' });
    }

    // Find rooms user has interacted with (either hosted or in their watch history)
    const roomIds = user.watchHistory.map((item) => item.roomId).filter(Boolean);
    
    const recentRooms = await Room.find({
      $or: [
        { hostId: user._id },
        { _id: { $in: roomIds } }
      ],
      isActive: true,
    })
      .sort({ updatedAt: -1 })
      .limit(10);

    res.status(200).json(recentRooms);
  } catch (error) {
    next(error);
  }
};

module.exports = {
  createRoom,
  getRoomById,
  getRoomByCode,
  joinRoom,
  leaveRoom,
  deleteRoom,
  getRoomMessages,
  getRecentRooms,
};
