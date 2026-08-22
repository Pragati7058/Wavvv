const mongoose = require('mongoose');

const MessageSchema = new mongoose.Schema(
  {
    roomId: { type: mongoose.Schema.Types.ObjectId, ref: 'Room', required: true, index: true },
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }, // Can be null for system messages
    username: { type: String, required: true },
    text: { type: String, required: true, maxlength: 500 },
    type: { type: String, enum: ['text', 'reaction', 'system'], default: 'text' },
  },
  {
    timestamps: { createdAt: 'createdAt', updatedAt: false }, // Only record creation time
  }
);

// Create compound index for fast history retrieval
MessageSchema.index({ roomId: 1, createdAt: -1 });

module.exports = mongoose.model('Message', MessageSchema);
