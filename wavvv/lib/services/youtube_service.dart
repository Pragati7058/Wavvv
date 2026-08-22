import '../models/youtube_video_model.dart';
import 'api_service.dart';
import '../core/constants/api_constants.dart';

class YoutubeService {
  Future<List<YouTubeVideoModel>> search(String query) async {
    try {
      final response = await apiService.get(
        ApiConstants.youtubeSearch,
        params: {'q': query},
      );
      final items = response.data as List<dynamic>;
      return items
          .map((e) => YouTubeVideoModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<YouTubeVideoModel?> getVideoDetails(String videoId) async {
    try {
      final response = await apiService.get('${ApiConstants.youtubeVideo}/$videoId');
      return YouTubeVideoModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }
}
