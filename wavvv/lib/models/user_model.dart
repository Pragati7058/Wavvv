class UserModel {
  final String id;
  final String firebaseUid;
  final String username;
  final String avatarColor;
  final bool isAnonymous;
  final String? fcmToken;
  final WatchStreakModel watchStreak;
  final UserStatsModel stats;
  final List<WatchHistoryItem> watchHistory;
  final DateTime? createdAt;
  final DateTime? lastSeenAt;

  const UserModel({
    required this.id,
    required this.firebaseUid,
    required this.username,
    required this.avatarColor,
    required this.isAnonymous,
    this.fcmToken,
    required this.watchStreak,
    required this.stats,
    required this.watchHistory,
    this.createdAt,
    this.lastSeenAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      firebaseUid: json['firebaseUid'] ?? '',
      username: json['username'] ?? 'Guest',
      avatarColor: json['avatarColor'] ?? '#6366F1',
      isAnonymous: json['isAnonymous'] ?? false,
      fcmToken: json['fcmToken'],
      watchStreak: json['watchStreak'] != null
          ? WatchStreakModel.fromJson(json['watchStreak'])
          : const WatchStreakModel(),
      stats: json['stats'] != null
          ? UserStatsModel.fromJson(json['stats'])
          : const UserStatsModel(),
      watchHistory: (json['watchHistory'] as List<dynamic>?)
              ?.map((e) => WatchHistoryItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      lastSeenAt: json['lastSeenAt'] != null ? DateTime.tryParse(json['lastSeenAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'firebaseUid': firebaseUid,
        'username': username,
        'avatarColor': avatarColor,
        'isAnonymous': isAnonymous,
      };
}

class WatchStreakModel {
  final int current;
  final int longest;
  final DateTime? lastWatchDate;

  const WatchStreakModel({
    this.current = 0,
    this.longest = 0,
    this.lastWatchDate,
  });

  factory WatchStreakModel.fromJson(Map<String, dynamic> json) {
    return WatchStreakModel(
      current: json['current'] ?? 0,
      longest: json['longest'] ?? 0,
      lastWatchDate: json['lastWatchDate'] != null
          ? DateTime.tryParse(json['lastWatchDate'])
          : null,
    );
  }
}

class UserStatsModel {
  final int roomsCreated;
  final int roomsJoined;
  final int wavesCount;
  final int clipsMarked;

  const UserStatsModel({
    this.roomsCreated = 0,
    this.roomsJoined = 0,
    this.wavesCount = 0,
    this.clipsMarked = 0,
  });

  factory UserStatsModel.fromJson(Map<String, dynamic> json) {
    return UserStatsModel(
      roomsCreated: json['roomsCreated'] ?? 0,
      roomsJoined: json['roomsJoined'] ?? 0,
      wavesCount: json['wavesCount'] ?? 0,
      clipsMarked: json['clipsMarked'] ?? 0,
    );
  }
}

class WatchHistoryItem {
  final String videoId;
  final String videoTitle;
  final String? videoThumbnail;
  final String? roomId;
  final DateTime? watchedAt;

  const WatchHistoryItem({
    required this.videoId,
    required this.videoTitle,
    this.videoThumbnail,
    this.roomId,
    this.watchedAt,
  });

  factory WatchHistoryItem.fromJson(Map<String, dynamic> json) {
    return WatchHistoryItem(
      videoId: json['videoId'] ?? '',
      videoTitle: json['videoTitle'] ?? '',
      videoThumbnail: json['videoThumbnail'],
      roomId: json['roomId'],
      watchedAt: json['watchedAt'] != null ? DateTime.tryParse(json['watchedAt']) : null,
    );
  }
}
