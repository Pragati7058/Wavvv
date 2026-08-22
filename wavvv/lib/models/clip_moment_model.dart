class ClipMomentModel {
  final String userId;
  final String username;
  final double positionSeconds;
  final DateTime createdAt;

  const ClipMomentModel({
    required this.userId,
    required this.username,
    required this.positionSeconds,
    required this.createdAt,
  });

  factory ClipMomentModel.fromJson(Map<String, dynamic> json) {
    return ClipMomentModel(
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      positionSeconds: (json['positionSeconds'] ?? 0).toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String get formattedTime {
    final m = (positionSeconds / 60).floor();
    final s = (positionSeconds % 60).floor();
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
