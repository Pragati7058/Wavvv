import 'queue_item_model.dart';
import 'clip_moment_model.dart';

class RoomMember {
  final String uid;
  final String username;
  final bool isGhost;
  final bool isHost;
  final String? avatarColor;

  const RoomMember({
    required this.uid,
    required this.username,
    required this.isGhost,
    required this.isHost,
    this.avatarColor,
  });

  factory RoomMember.fromJson(String uid, Map<String, dynamic> json) {
    return RoomMember(
      uid: uid,
      username: json['username'] ?? 'Guest',
      isGhost: json['isGhost'] ?? false,
      isHost: json['isHost'] ?? false,
      avatarColor: json['avatarColor'],
    );
  }
}

class RoomModel {
  final String id;
  final String roomCode;
  final String hostId;
  final String hostFirebaseUid;
  final String hostUsername;
  final String videoId;
  final String videoTitle;
  final String videoThumbnail;
  final bool isActive;
  final bool isPlaying;
  final double positionSeconds;
  final List<QueueItemModel> queue;
  final List<ClipMomentModel> clipMoments;
  final Map<String, RoomMember> members;
  final int memberCount;
  final int messageCount;
  final DateTime? createdAt;

  const RoomModel({
    required this.id,
    required this.roomCode,
    required this.hostId,
    required this.hostFirebaseUid,
    required this.hostUsername,
    required this.videoId,
    required this.videoTitle,
    required this.videoThumbnail,
    required this.isActive,
    required this.isPlaying,
    required this.positionSeconds,
    required this.queue,
    required this.clipMoments,
    required this.members,
    required this.memberCount,
    required this.messageCount,
    this.createdAt,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    // Parse members map from Firestore or socket state
    final membersRaw = json['members'] as Map<String, dynamic>? ?? {};
    final members = membersRaw.map((uid, data) =>
        MapEntry(uid, RoomMember.fromJson(uid, data as Map<String, dynamic>)));

    return RoomModel(
      id: json['_id'] ?? json['id'] ?? '',
      roomCode: json['roomCode'] ?? '',
      hostId: json['hostId'] ?? '',
      hostFirebaseUid: json['hostFirebaseUid'] ?? '',
      hostUsername: json['hostUsername'] ?? '',
      videoId: json['videoId'] ?? '',
      videoTitle: json['videoTitle'] ?? '',
      videoThumbnail: json['videoThumbnail'] ?? '',
      isActive: json['isActive'] ?? true,
      isPlaying: json['isPlaying'] ?? false,
      positionSeconds: (json['positionSeconds'] ?? 0).toDouble(),
      queue: (json['queue'] as List<dynamic>?)
              ?.map((e) => QueueItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      clipMoments: (json['clipMoments'] as List<dynamic>?)
              ?.map((e) => ClipMomentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      members: members,
      memberCount: json['memberCount'] ?? 0,
      messageCount: json['messageCount'] ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }

  RoomModel copyWith({
    String? videoId,
    String? videoTitle,
    String? videoThumbnail,
    bool? isPlaying,
    double? positionSeconds,
    List<QueueItemModel>? queue,
    List<ClipMomentModel>? clipMoments,
    Map<String, RoomMember>? members,
  }) {
    return RoomModel(
      id: id,
      roomCode: roomCode,
      hostId: hostId,
      hostFirebaseUid: hostFirebaseUid,
      hostUsername: hostUsername,
      videoId: videoId ?? this.videoId,
      videoTitle: videoTitle ?? this.videoTitle,
      videoThumbnail: videoThumbnail ?? this.videoThumbnail,
      isActive: isActive,
      isPlaying: isPlaying ?? this.isPlaying,
      positionSeconds: positionSeconds ?? this.positionSeconds,
      queue: queue ?? this.queue,
      clipMoments: clipMoments ?? this.clipMoments,
      members: members ?? this.members,
      memberCount: memberCount,
      messageCount: messageCount,
      createdAt: createdAt,
    );
  }
}
