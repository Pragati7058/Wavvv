import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/room_model.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../services/firestore_service.dart';

final socketServiceProvider = Provider<SocketService>((ref) => SocketService());
final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());

final currentRoomProvider = StateProvider<RoomModel?>((ref) => null);

class RoomNotifier extends StateNotifier<RoomModel?> {
  final SocketService _socket;
  final FirestoreService _firestore;
  final Ref _ref;

  RoomNotifier(this._socket, this._firestore, this._ref) : super(null);

  Future<RoomModel?> createRoom({
    required String videoId,
    required String videoTitle,
    required String videoThumbnail,
    required String hostFirebaseUid,
    required String hostUsername,
  }) async {
    try {
      final response = await apiService.post('/api/rooms', data: {
        'videoId': videoId,
        'videoTitle': videoTitle,
        'videoThumbnail': videoThumbnail,
      });
      final room = RoomModel.fromJson(response.data as Map<String, dynamic>);
      _firestore.createRoom(
        room.id,
        hostId: hostFirebaseUid,
        hostUsername: hostUsername,
        videoId: videoId,
        videoTitle: videoTitle,
        videoThumbnail: videoThumbnail,
      );
      state = room;
      _ref.read(currentRoomProvider.notifier).state = room;
      return room;
    } catch (e, st) {
      debugPrint('Error creating room: $e');
      debugPrint(st.toString());
      return null;
    }
  }

  Future<RoomModel?> getRoomByCode(String code) async {
    try {
      final response = await apiService.get('/api/rooms/code/$code');
      return RoomModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<List<RoomModel>> getRecentRooms() async {
    try {
      final response = await apiService.get('/api/rooms/recent');
      final items = response.data as List<dynamic>;
      return items
          .map((e) => RoomModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  void updateFromSocket(Map<String, dynamic> data) {
    if (state == null) return;
    final newVideoId = data['videoId'] as String?;
    state = state!.copyWith(
      videoId: newVideoId,
      videoTitle: data['videoTitle'] as String?,
      videoThumbnail: data['videoThumbnail'] as String?,
    );
    _ref.read(currentRoomProvider.notifier).state = state;
    // Notify socket of video change if needed
    if (newVideoId != null && _socket.isConnected) {
      _socket.changeVideo(
        state!.id,
        newVideoId,
        data['videoTitle'] as String? ?? '',
        data['videoThumbnail'] as String? ?? '',
      );
    }
  }

  void clearRoom() {
    state = null;
    _ref.read(currentRoomProvider.notifier).state = null;
  }
}

final roomNotifierProvider = StateNotifierProvider<RoomNotifier, RoomModel?>((ref) {
  final socket = ref.watch(socketServiceProvider);
  final firestore = ref.watch(firestoreServiceProvider);
  return RoomNotifier(socket, firestore, ref);
});
