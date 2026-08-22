import 'package:flutter/material.dart';
import 'dart:async';
import '../services/youtube_service.dart';
import '../models/youtube_video_model.dart';


class VideoSearchSheet extends StatefulWidget {
  const VideoSearchSheet({super.key});

  @override
  State<VideoSearchSheet> createState() => _VideoSearchSheetState();
}

class _VideoSearchSheetState extends State<VideoSearchSheet> {
  final _searchController = TextEditingController();
  final _youtubeService = YoutubeService();
  Timer? _debounce;

  List<YouTubeVideoModel> _results = [];
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().isNotEmpty) {
        _performSearch(query.trim());
      } else {
        setState(() {
          _results = [];
          _error = null;
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await _youtubeService.search(query);
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to search videos. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Search Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search YouTube videos...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          
          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
                    : _results.isEmpty && _searchController.text.isNotEmpty
                        ? const Center(child: Text('No results found', style: TextStyle(color: Colors.white54)))
                        : _results.isEmpty
                            ? const Center(child: Text('Type to search', style: TextStyle(color: Colors.white24)))
                            : ListView.builder(
                                padding: const EdgeInsets.only(bottom: 24, top: 8),
                                itemCount: _results.length,
                                itemBuilder: (context, index) {
                                  final video = _results[index];
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        video.thumbnailUrl,
                                        width: 100,
                                        height: 56,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 100,
                                          height: 56,
                                          color: Colors.white12,
                                          child: const Icon(Icons.play_arrow, color: Colors.white24),
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      video.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.white, fontSize: 14),
                                    ),
                                    subtitle: Text(
                                      video.channelTitle,
                                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                                    ),
                                    onTap: () {
                                      Navigator.of(context).pop(video);
                                    },
                                  );
                                },
                              ),
          ),
        ],
      ),
    );
  }
}

Future<YouTubeVideoModel?> showVideoSearchSheet(BuildContext context) {
  return showModalBottomSheet<YouTubeVideoModel>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const VideoSearchSheet(),
  );
}
