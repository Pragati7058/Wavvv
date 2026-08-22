const User = require('../models/User');

const getMe = async (req, res, next) => {
  try {
    if (!req.user) {
      return res.status(404).json({ error: 'User registration incomplete or not found.' });
    }
    res.status(200).json(req.user);
  } catch (error) {
    next(error);
  }
};

const updateMe = async (req, res, next) => {
  try {
    if (!req.user) {
      return res.status(404).json({ error: 'User registration not found.' });
    }

    const { username, avatarColor, fcmToken } = req.body;

    if (username) {
      if (username.length > 20) {
        return res.status(400).json({ error: 'Username must be less than 20 characters.' });
      }
      req.user.username = username;
    }

    if (avatarColor) {
      req.user.avatarColor = avatarColor;
    }

    if (fcmToken !== undefined) {
      req.user.fcmToken = fcmToken;
    }

    await req.user.save();
    res.status(200).json(req.user);
  } catch (error) {
    next(error);
  }
};

const getHistory = async (req, res, next) => {
  try {
    if (!req.user) {
      return res.status(404).json({ error: 'User not found.' });
    }
    // Return watch history sorted by most recent
    const sortedHistory = [...req.user.watchHistory].sort((a, b) => b.watchedAt - a.watchedAt);
    res.status(200).json(sortedHistory);
  } catch (error) {
    next(error);
  }
};

const getStreak = async (req, res, next) => {
  try {
    const user = req.user;
    if (!user) {
      return res.status(404).json({ error: 'User not found.' });
    }

    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const streak = user.watchStreak;

    let current = streak.current || 0;
    let longest = streak.longest || 0;

    if (streak.lastWatchDate) {
      const lastWatch = new Date(streak.lastWatchDate);
      const lastWatchDay = new Date(lastWatch.getFullYear(), lastWatch.getMonth(), lastWatch.getDate());
      
      const diffTime = Math.abs(today - lastWatchDay);
      const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

      if (diffDays > 1) {
        // Streak broken
        current = 0;
      }
    } else {
      current = 0;
    }

    res.status(200).json({
      current,
      longest,
      lastWatchDate: streak.lastWatchDate,
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getMe,
  updateMe,
  getHistory,
  getStreak,
};
