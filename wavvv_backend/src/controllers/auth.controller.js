const User = require('../models/User');

const avatarColors = [
  '#6366F1', // Indigo / Wave
  '#EC4899', // Pink
  '#10B981', // Emerald
  '#F59E0B', // Amber
  '#EF4444', // Red
  '#8B5CF6', // Purple
  '#06B6D4', // Cyan
];

const getRandomAvatarColor = () => {
  const index = Math.floor(Math.random() * avatarColors.length);
  return avatarColors[index];
};

const verify = async (req, res, next) => {
  try {
    const firebaseUser = req.firebaseUser;
    if (!firebaseUser) {
      return res.status(400).json({ error: 'Auth failed: No firebase user details found' });
    }

    let user = await User.findOne({ firebaseUid: firebaseUser.uid });
    let isNew = false;

    if (!user) {
      isNew = true;
      // Extract or generate a clean default username
      const defaultUsername = firebaseUser.name || `User_${firebaseUser.uid.substring(0, 5)}`;
      user = await User.create({
        firebaseUid: firebaseUser.uid,
        username: defaultUsername.substring(0, 20),
        avatarColor: getRandomAvatarColor(),
        isAnonymous: firebaseUser.isAnonymous || false,
        watchStreak: {
          current: 0,
          longest: 0,
        },
        stats: {
          roomsCreated: 0,
          roomsJoined: 0,
          wavesCount: 0,
          clipsMarked: 0,
        },
        watchHistory: [],
        createdAt: new Date(),
        lastSeenAt: new Date(),
      });
    } else {
      user.lastSeenAt = new Date();
      await user.save();
    }

    res.status(200).json({
      user,
      isNew,
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  verify,
};
