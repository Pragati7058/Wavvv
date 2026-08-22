const mongoose = require('mongoose');

const QueueItemSchema = new mongoose.Schema({
  videoId: { type: String, required: true },
  videoTitle: { type: String, required: true },
  videoThumbnail: { type: String },
  addedBy: { type: String, required: true }, // username
  votes: [{ type: String }], // Array of user IDs/Firebase UIDs who upvoted
  order: { type: Number, default: 0 },
});

const ClipMomentSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  username: { type: String, required: true },
  positionSeconds: { type: Number, required: true },
  createdAt: { type: Date, default: Date.now },
});

const RoomSchema = new mongoose.Schema(
  {
    roomCode: { type: String, required: true, unique: true, index: true },
    hostId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    hostFirebaseUid: { type: String, required: true },
    hostUsername: { type: String, required: true },
    videoId: { type: String },
    videoTitle: { type: String },
    videoThumbnail: { type: String },
    isActive: { type: Boolean, default: true, index: true },
    queue: [QueueItemSchema],
    clipMoments: [ClipMomentSchema],
    memberCount: { type: Number, default: 0 },
    messageCount: { type: Number, default: 0 },
    endedAt: { type: Date },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('Room', RoomSchema);
