const mongoose = require('mongoose');

const WatchHistorySchema = new mongoose.Schema({
  videoId: { type: String, required: true },
  videoTitle: { type: String, required: true },
  videoThumbnail: { type: String },
  roomId: { type: mongoose.Schema.Types.ObjectId, ref: 'Room' },
  watchedAt: { type: Date, default: Date.now },
});

const UserSchema = new mongoose.Schema(
  {
    firebaseUid: { type: String, required: true, unique: true, index: true },
    username: { type: String, required: true, maxlength: 20 },
    avatarColor: { type: String, default: '#6366F1' },
    isAnonymous: { type: Boolean, default: false },
    fcmToken: { type: String },
    watchStreak: {
      current: { type: Number, default: 0 },
      longest: { type: Number, default: 0 },
      lastWatchDate: { type: Date },
    },
    stats: {
      roomsCreated: { type: Number, default: 0 },
      roomsJoined: { type: Number, default: 0 },
      wavesCount: { type: Number, default: 0 },
      clipsMarked: { type: Number, default: 0 },
    },
    watchHistory: [WatchHistorySchema],
    lastSeenAt: { type: Date, default: Date.now },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('User', UserSchema);
