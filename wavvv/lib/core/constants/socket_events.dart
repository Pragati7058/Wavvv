class SocketEvents {
  // Client -> Server
  static const String roomJoin = 'room:join';
  static const String roomLeave = 'room:leave';
  static const String playbackPlay = 'playback:play';
  static const String playbackPause = 'playback:pause';
  static const String playbackSeek = 'playback:seek';
  static const String videoChange = 'video:change';
  static const String chatMessage = 'chat:message';
  static const String reactionWave = 'reaction:wave';
  static const String reactionEmoji = 'reaction:emoji';
  static const String queueAdd = 'queue:add';
  static const String queueVote = 'queue:vote';
  static const String queueRemove = 'queue:remove';
  static const String queueReorder = 'queue:reorder';
  static const String clipMark = 'clip:mark';
  static const String rewindTrigger = 'rewind:trigger';

  // Server -> Client
  static const String roomState = 'room:state';
  static const String roomUserJoined = 'room:user_joined';
  static const String roomUserLeft = 'room:user_left';
  static const String roomStateUpdate = 'room:state_update';
  static const String playbackUpdate = 'playback:update';
  static const String chatNewMessage = 'chat:new_message';
  static const String serverReactionWave = 'reaction:wave';
  static const String serverReactionEmoji = 'reaction:emoji';
  static const String queueUpdated = 'queue:updated';
  static const String clipNew = 'clip:new';
  static const String rewindCountdown = 'rewind:countdown';
  static const String rewindExecute = 'rewind:execute';
  static const String syncStatus = 'sync:status';
}
