import 'package:socket_io_client/socket_io_client.dart' as io;
import '../core/constants/api_constants.dart';
import '../core/constants/socket_events.dart';

class SocketService {
  io.Socket? _socket;
  bool _isConnected = false;
  String? _currentRoomId;

  bool get isConnected => _isConnected;
  String? get currentRoomId => _currentRoomId;

  void connect(String token) {
    if (_socket != null && _isConnected) return;

    _socket = io.io(ApiConstants.socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'auth': {'token': token},
    });

    _socket!.on('connect', (_) {
      _isConnected = true;
    });

    _socket!.on('disconnect', (_) {
      _isConnected = false;
      _currentRoomId = null;
    });

    _socket!.on('connect_error', (data) {
      _isConnected = false;
    });

    _socket!.connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
    _isConnected = false;
    _currentRoomId = null;
  }

  // ─── Room Events ─────────────────────────────────────────────────────────
  void joinRoom({
    required String roomId,
    required String userId,
    required String username,
    bool ghostMode = false,
  }) {
    _currentRoomId = roomId;
    emit(SocketEvents.roomJoin, {
      'roomId': roomId,
      'userId': userId,
      'username': username,
      'ghostMode': ghostMode,
    });
  }

  void leaveRoom(String roomId, String userId) {
    emit(SocketEvents.roomLeave, {'roomId': roomId, 'userId': userId});
    if (_currentRoomId == roomId) _currentRoomId = null;
  }

  // ─── Playback Events ─────────────────────────────────────────────────────
  void play(String roomId, double positionSeconds) =>
      emit(SocketEvents.playbackPlay, {'roomId': roomId, 'positionSeconds': positionSeconds});

  void pause(String roomId, double positionSeconds) =>
      emit(SocketEvents.playbackPause, {'roomId': roomId, 'positionSeconds': positionSeconds});

  void seek(String roomId, double positionSeconds) =>
      emit(SocketEvents.playbackSeek, {'roomId': roomId, 'positionSeconds': positionSeconds});

  void changeVideo(String roomId, String videoId, String videoTitle, String videoThumbnail) =>
      emit(SocketEvents.videoChange, {
        'roomId': roomId,
        'videoId': videoId,
        'videoTitle': videoTitle,
        'videoThumbnail': videoThumbnail,
      });

  // ─── Chat Events ─────────────────────────────────────────────────────────
  void sendMessage(String roomId, String userId, String username, String text) =>
      emit(SocketEvents.chatMessage, {
        'roomId': roomId,
        'userId': userId,
        'username': username,
        'text': text,
      });

  // ─── Reaction Events ─────────────────────────────────────────────────────
  void sendWave(String roomId, String userId, String username) =>
      emit(SocketEvents.reactionWave, {
        'roomId': roomId,
        'userId': userId,
        'username': username,
      });

  void sendEmoji(String roomId, String userId, String emoji) =>
      emit(SocketEvents.reactionEmoji, {
        'roomId': roomId,
        'userId': userId,
        'emoji': emoji,
      });

  // ─── Queue Events ─────────────────────────────────────────────────────────
  void addToQueue(String roomId, String userId, String username,
      String videoId, String videoTitle, String videoThumbnail) =>
      emit(SocketEvents.queueAdd, {
        'roomId': roomId,
        'userId': userId,
        'username': username,
        'videoId': videoId,
        'videoTitle': videoTitle,
        'videoThumbnail': videoThumbnail,
      });

  void voteQueue(String roomId, String userId, String queueItemId) =>
      emit(SocketEvents.queueVote, {
        'roomId': roomId,
        'userId': userId,
        'queueItemId': queueItemId,
      });

  void removeFromQueue(String roomId, String userId, String queueItemId) =>
      emit(SocketEvents.queueRemove, {
        'roomId': roomId,
        'userId': userId,
        'queueItemId': queueItemId,
      });

  // ─── Clip Events ─────────────────────────────────────────────────────────
  void markClip(String roomId, String userId, String username, double positionSeconds) =>
      emit(SocketEvents.clipMark, {
        'roomId': roomId,
        'userId': userId,
        'username': username,
        'positionSeconds': positionSeconds,
      });

  // ─── Rewind ──────────────────────────────────────────────────────────────
  void triggerRewind(String roomId, String userId) =>
      emit(SocketEvents.rewindTrigger, {'roomId': roomId, 'userId': userId});

  // ─── Generic Event Binding ────────────────────────────────────────────────
  void on(String event, Function(dynamic) callback) {
    _socket?.on(event, callback);
  }

  void off(String event) {
    _socket?.off(event);
  }

  void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }
}
