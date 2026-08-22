import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Room State ───────────────────────────────────────────────────────────
  DocumentReference roomRef(String roomId) =>
      _db.collection('rooms').doc(roomId);

  Stream<DocumentSnapshot> watchRoom(String roomId) =>
      roomRef(roomId).snapshots();

  Future<void> updateRoomState(String roomId, {
    required bool isPlaying,
    required double positionSeconds,
    required String videoId,
    String videoTitle = '',
    String videoThumbnail = '',
  }) async {
    try {
      await roomRef(roomId).set({
        'isPlaying': isPlaying,
        'positionSeconds': positionSeconds,
        'videoId': videoId,
        'videoTitle': videoTitle,
        'videoThumbnail': videoThumbnail,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Silently fail if Firestore unavailable
    }
  }

  Future<void> updateSyncStatus(String roomId, String uid, double positionSeconds) async {
    try {
      await roomRef(roomId).set({
        'syncStatus': {
          uid: {
            'positionSeconds': positionSeconds,
            'updatedAt': FieldValue.serverTimestamp(),
          }
        }
      }, SetOptions(merge: true));
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> joinRoom(String roomId, String uid, {
    required String username,
    required bool isHost,
    bool isGhost = false,
  }) async {
    try {
      await roomRef(roomId).set({
        'members': {
          uid: {
            'username': username,
            'isHost': isHost,
            'isGhost': isGhost,
            'joinedAt': FieldValue.serverTimestamp(),
          }
        }
      }, SetOptions(merge: true));
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> leaveRoom(String roomId, String uid) async {
    try {
      await roomRef(roomId).update({
        'members.$uid': FieldValue.delete(),
        'syncStatus.$uid': FieldValue.delete(),
      });
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> createRoom(String roomId, {
    required String hostId,
    required String hostUsername,
    required String videoId,
    required String videoTitle,
    required String videoThumbnail,
  }) async {
    try {
      await roomRef(roomId).set({
        'videoId': videoId,
        'videoTitle': videoTitle,
        'videoThumbnail': videoThumbnail,
        'isPlaying': false,
        'positionSeconds': 0.0,
        'hostId': hostId,
        'hostUsername': hostUsername,
        'members': {},
        'syncStatus': {},
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Silently fail
    }
  }
}
