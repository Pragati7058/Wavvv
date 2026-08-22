class QueueItemModel {
  final String id;
  final String videoId;
  final String videoTitle;
  final String videoThumbnail;
  final String addedBy;
  final List<String> votes;
  final int order;

  const QueueItemModel({
    required this.id,
    required this.videoId,
    required this.videoTitle,
    required this.videoThumbnail,
    required this.addedBy,
    required this.votes,
    required this.order,
  });

  factory QueueItemModel.fromJson(Map<String, dynamic> json) {
    return QueueItemModel(
      id: json['_id'] ?? json['id'] ?? '',
      videoId: json['videoId'] ?? '',
      videoTitle: json['videoTitle'] ?? '',
      videoThumbnail: json['videoThumbnail'] ?? '',
      addedBy: json['addedBy'] ?? '',
      votes: List<String>.from(json['votes'] ?? []),
      order: json['order'] ?? 0,
    );
  }

  int get voteCount => votes.length;

  bool hasVoted(String userId) => votes.contains(userId);
}
