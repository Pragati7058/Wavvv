const mongoose = require('mongoose');

const WatchHistorySchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    videoId: { type: String, required: true },
    videoTitle: { type: String, required: true },
    videoThumbnail: { type: String },
    roomId: { type: mongoose.Schema.Types.ObjectId, ref: 'Room' },
    watchedAt: { type: Date, default: Date.now },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('WatchHistory', WatchHistorySchema);
