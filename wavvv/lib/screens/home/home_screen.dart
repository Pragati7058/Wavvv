import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/room_provider.dart';
import '../../widgets/glassmorphic_container.dart';
import '../../core/utils/haptics.dart';
import '../../router/app_router.dart';
import '../../widgets/video_search_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final roomNotifier = ref.read(roomNotifierProvider.notifier);
    final router = ref.watch(appRouterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wavvv'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await HapticsUtil.light();
              await ref.read(authNotifierProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: GlassMorphicContainer(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Hi, ${user?.username ?? 'Guest'}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text('Create New Room'),
                onPressed: () async {
                  await HapticsUtil.light();
                  if (!context.mounted) return;
                  
                  final selectedVideo = await showVideoSearchSheet(context);
                  if (selectedVideo == null) return; // User cancelled

                  final room = await roomNotifier.createRoom(
                    videoId: selectedVideo.videoId,
                    videoTitle: selectedVideo.title,
                    videoThumbnail: selectedVideo.thumbnailUrl,
                    hostFirebaseUid: ref.read(currentUserProvider)!.firebaseUid,
                    hostUsername: ref.read(currentUserProvider)!.username,
                  );
                  if (room != null) {
                    router.go('/room/${room.id}');
                  } else {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to create room. Please try again.')),
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.search),
                label: const Text('Join Room by Code'),
                onPressed: () async {
                  await HapticsUtil.light();
                  if (!context.mounted) return;
                  final code = await _promptRoomCode(context);
                  if (code != null && code.isNotEmpty) {
                    final room = await roomNotifier.getRoomByCode(code);
                    if (room != null) {
                      router.go('/room/${room.id}');
                    } else {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Room not found')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _promptRoomCode(BuildContext context) async {
    final controller = TextEditingController();
    return await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Enter Room Code'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'e.g. ABCD'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(c).pop(controller.text.trim()), child: const Text('Join')),
        ],
      ),
    );
  }
}
