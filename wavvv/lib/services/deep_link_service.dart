import 'package:share_plus/share_plus.dart';

class DeepLinkService {
  static const String _baseUrl = 'https://wavvv.app/room';

  /// Share a room invite link via the OS share sheet
  Future<void> shareRoom(String roomCode, String roomTitle) async {
    final link = '$_baseUrl/$roomCode';
    final text = roomTitle.isNotEmpty
        ? '🌊 Join me watching "$roomTitle" on Wavvv!\n$link'
        : '🌊 Join my Wavvv watch party!\n$link';
    await Share.share(text, subject: 'Wavvv Watch Party Invite');
  }

  /// Parse a deep link URI and extract the room code
  String? extractRoomCode(Uri uri) {
    try {
      final segments = uri.pathSegments;
      if (segments.length >= 2 && segments[0] == 'room') {
        return segments[1].toUpperCase();
      }
    } catch (_) {}
    return null;
  }
}
