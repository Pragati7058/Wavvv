class YouTubeVideoModel {
  final String videoId;
  final String title;
  final String channelTitle;
  final String thumbnailUrl;
  final String? duration;

  const YouTubeVideoModel({
    required this.videoId,
    required this.title,
    required this.channelTitle,
    required this.thumbnailUrl,
    this.duration,
  });

  factory YouTubeVideoModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final videoId = (id is Map) ? (id['videoId'] ?? '') : (id ?? '');
    final snippet = json['snippet'] as Map<String, dynamic>? ?? {};
    final thumbs = snippet['thumbnails'] as Map<String, dynamic>? ?? {};
    final high = thumbs['high'] as Map<String, dynamic>?;
    final medium = thumbs['medium'] as Map<String, dynamic>?;
    final thumbnailUrl = high?['url'] ?? medium?['url'] ?? 'https://img.youtube.com/vi/$videoId/0.jpg';

    return YouTubeVideoModel(
      videoId: videoId.toString(),
      title: snippet['title'] ?? 'Untitled',
      channelTitle: snippet['channelTitle'] ?? '',
      thumbnailUrl: thumbnailUrl,
      duration: json['contentDetails']?['duration'],
    );
  }

  String get watchUrl => 'https://www.youtube.com/watch?v=$videoId';
}
