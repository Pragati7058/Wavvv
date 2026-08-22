import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../providers/player_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/queue_provider.dart';
import '../../providers/reactions_provider.dart';
import '../../providers/room_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/atmosphere_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/socket_events.dart';
import '../../core/utils/haptics.dart';
import '../../models/message_model.dart';
import '../../models/queue_item_model.dart';

import '../../widgets/video_search_sheet.dart';

// Neon-red palette
const _neonRed = Color(0xFFFF2D55);
const _neonRedDim = Color(0x33FF2D55);
const _neonRedBorder = Color(0x66FF2D55);

class RoomScreen extends ConsumerStatefulWidget {
  final String roomId;
  const RoomScreen({required this.roomId, super.key});

  @override
  ConsumerState<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends ConsumerState<RoomScreen> {
  late YoutubePlayerController _ytController;
  final _chatController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Allow landscape and portrait while in the room
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    final room = ref.read(currentRoomProvider);

    final initialId = room?.videoId ?? 'dQw4w9WgXcQ';

    _ytController = YoutubePlayerController(
      initialVideoId: initialId,
      flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
    );

    // Clear stale chat/queue from previous room
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatNotifierProvider.notifier).clear();
      ref.read(queueNotifierProvider.notifier).clear();
    });

    _connectSocket();
  }

  Future<void> _connectSocket() async {
    final socket = ref.read(socketServiceProvider);
    final token = await ref.read(authNotifierProvider.notifier).getIdToken();
    if (token != null) socket.connect(token);

    final user = ref.read(currentUserProvider);
    if (user != null) {
      socket.joinRoom(
        roomId: widget.roomId,
        userId: user.id,
        username: user.username,
      );
    }
    _setupSocketListeners(socket);
  }

  void _setupSocketListeners(dynamic socket) {
    // Room full — show error and navigate back
    socket.on('room:full', (data) {
      final message = data['message'] as String? ?? 'This room is full!';
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: _neonRed, width: 1),
            ),
            title: const Row(
              children: [
                Icon(Icons.people_alt_rounded, color: _neonRed),
                SizedBox(width: 10),
                Text('Room Full', style: TextStyle(color: Colors.white)),
              ],
            ),
            content: Text(message, style: const TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/');
                },
                child: const Text('Back to Home', style: TextStyle(color: _neonRed)),
              ),
            ],
          ),
        );
      }
    });

    socket.on(SocketEvents.videoChange, (data) {
      if (!mounted) return;
      final videoId = data['videoId'] as String;
      _ytController.load(videoId);
    });

    socket.on(SocketEvents.chatNewMessage, (data) {
      if (!mounted) return;
      ref.read(chatNotifierProvider.notifier).addMessage(
        MessageModel.fromJson(data as Map<String, dynamic>),
      );
    });

    // ✅ Load initial queue when joining a room
    socket.on(SocketEvents.roomState, (data) {
      final rawQueue = data['queue'] as List<dynamic>? ?? [];
      final items = rawQueue
          .map((e) => QueueItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) {
        ref.read(queueNotifierProvider.notifier).setQueue(items);
      }
    });

    // ✅ Listen for queue updates — server sends { queue: [...] }
    socket.on(SocketEvents.queueUpdated, (data) {
      final rawQueue = (data as Map<dynamic, dynamic>?)?['queue'] as List<dynamic>? ?? [];
      final items = rawQueue
          .map((e) => QueueItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) {
        ref.read(queueNotifierProvider.notifier).setQueue(items);
      }
    });

    socket.on(SocketEvents.serverReactionWave, (data) {
      if (!mounted) return;
      ref.read(reactionsNotifierProvider.notifier).triggerWave(data['username'] ?? '');
      HapticsUtil.wave();
    });

    socket.on(SocketEvents.serverReactionEmoji, (data) {
      if (!mounted) return;
      ref.read(reactionsNotifierProvider.notifier).addFloatingEmoji(data['emoji'] ?? '✨');
      HapticsUtil.medium();
    });

    socket.on(SocketEvents.playbackUpdate, (data) {
      if (!mounted) return;
      final isPlaying = data['isPlaying'] as bool? ?? false;
      final position = (data['positionSeconds'] ?? 0).toDouble();
      final needsSeek = ref.read(playerNotifierProvider.notifier).onRemoteUpdate(
        isPlaying: isPlaying,
        remotePosition: position,
      );
      if (needsSeek) {
        _ytController.seekTo(Duration(seconds: position.toInt()));
      }
      if (isPlaying) {
        _ytController.play();
      } else {
        _ytController.pause();
      }
    });
  }

  @override
  void dispose() {
    _chatController.dispose();
    _ytController.dispose();

    // Lock back to portrait when leaving the room
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    final socket = ref.read(socketServiceProvider);

    final user = ref.read(currentUserProvider);
    if (user != null) {
      socket.leaveRoom(widget.roomId, user.id);
    }
    socket.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerNotifierProvider);
    final chatMessages = ref.watch(chatNotifierProvider);
    final queue = ref.watch(queueNotifierProvider);
    final reactions = ref.watch(reactionsNotifierProvider);
    final atmosphereColor = ref.watch(atmosphereNotifierProvider);
    final user = ref.watch(currentUserProvider);
    final currentRoom = ref.watch(currentRoomProvider);
    final socket = ref.read(socketServiceProvider);

    return Scaffold(
      backgroundColor: WavvvTheme.darkTheme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: true,
        child: Stack(
          children: [
            // Atmosphere overlay
            if (atmosphereColor != null)
              Positioned.fill(child: Container(color: atmosphereColor)),

            // Main content
            Column(
              children: [
                // ── Custom Header ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                        onPressed: () {
                          HapticsUtil.light();
                          context.go('/');
                        },
                      ),
                      Expanded(
                        child: Center(
                          child: GestureDetector(
                            onTap: () async {
                              HapticsUtil.light();
                              if (currentRoom != null) {
                                await Clipboard.setData(ClipboardData(text: currentRoom.roomCode));
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(children: [
                                        const Icon(Icons.check_circle, color: Colors.white, size: 18),
                                        const SizedBox(width: 10),
                                        Text('Code ${currentRoom.roomCode} copied!'),
                                      ]),
                                      backgroundColor: _neonRed.withOpacity(0.9),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                              decoration: BoxDecoration(
                                color: _neonRedDim,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: _neonRedBorder, width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.group, color: _neonRed, size: 15),
                                  const SizedBox(width: 8),
                                  Text(
                                    currentRoom?.roomCode ?? '- - - -',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      letterSpacing: 3,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.copy_rounded, color: _neonRed, size: 14),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.ios_share_rounded, color: Colors.white70, size: 20),
                        onPressed: () async {
                          HapticsUtil.light();
                          if (currentRoom != null) {
                            await Clipboard.setData(ClipboardData(text: currentRoom.roomCode));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Room code ${currentRoom.roomCode} copied — share it!'),
                                  backgroundColor: _neonRed.withOpacity(0.9),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── Video Player ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _neonRedBorder, width: 1),
                      boxShadow: [BoxShadow(color: _neonRed.withOpacity(0.25), blurRadius: 20, spreadRadius: 1)],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: YoutubePlayer(controller: _ytController),
                      ),
                    ),
                  ),
                ),

                // ── Playback Controls ────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Rewind
                      _NeoButton(
                        color: Colors.white60,
                        onTap: () {
                          if (user != null) {
                            socket.triggerRewind(widget.roomId, user.id);
                            HapticsUtil.rewind();
                          }
                        },
                        child: const Icon(Icons.replay_10_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 20),
                      // Play / Pause (larger, red outline)
                      _NeoButton(
                        color: _neonRed,
                        size: 58,
                        onTap: () {
                          HapticsUtil.light();
                          final pos = _ytController.value.position.inSeconds.toDouble();
                          if (playerState.isPlaying) {
                            socket.pause(widget.roomId, pos);
                            _ytController.pause();
                            ref.read(playerNotifierProvider.notifier).pause();
                          } else {
                            socket.play(widget.roomId, pos);
                            _ytController.play();
                            ref.read(playerNotifierProvider.notifier).play();
                          }
                        },
                        child: Icon(
                          playerState.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Sync badge
                      _SyncBadge(status: playerState.syncStatus),
                    ],
                  ),
                ),

                // ── Queue (Up Next) ──────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _neonRedBorder, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 10, 8, 6),
                            child: Row(
                              children: [
                                const Icon(Icons.queue_music_rounded, color: _neonRed, size: 18),
                                const SizedBox(width: 8),
                                const Text('Up Next',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                const Spacer(),
                                // + Add button
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    backgroundColor: _neonRedDim,
                                    foregroundColor: _neonRed,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        side: const BorderSide(color: _neonRedBorder)),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('Add', style: TextStyle(fontSize: 13)),
                                  onPressed: () async {
                                    HapticsUtil.light();
                                    if (!context.mounted) return;
                                    final selectedVideo = await showVideoSearchSheet(context);
                                    if (selectedVideo != null && user != null) {
                                      socket.addToQueue(
                                        widget.roomId,
                                        user.id,
                                        user.username,
                                        selectedVideo.videoId,
                                        selectedVideo.title,
                                        selectedVideo.thumbnailUrl,
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          const Divider(color: _neonRedBorder, height: 1),
                          Expanded(
                            child: queue.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.video_library_outlined,
                                            color: Colors.white.withOpacity(0.15), size: 40),
                                        const SizedBox(height: 8),
                                        Text('Queue is empty  •  Tap Add',
                                            style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 13)),
                                      ],
                                    ),
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    itemCount: queue.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                                    itemBuilder: (_, i) {
                                      final item = queue[i];
                                      return InkWell(
                                        onTap: () {
                                          HapticsUtil.light();
                                          socket.changeVideo(widget.roomId, item.videoId,
                                              item.videoTitle, item.videoThumbnail);
                                        },
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.04),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                                          ),
                                          child: Row(
                                            children: [
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(6),
                                                child: Image.network(item.videoThumbnail,
                                                    width: 72, height: 40, fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) => Container(
                                                        width: 72,
                                                        height: 40,
                                                        color: Colors.white10,
                                                        child: const Icon(Icons.play_arrow,
                                                            color: Colors.white24))),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(item.videoTitle,
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                        color: Colors.white, fontSize: 12, height: 1.3)),
                                              ),
                                              const SizedBox(width: 6),
                                              Icon(Icons.play_circle_outline, color: _neonRed.withOpacity(0.7), size: 20),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Chat ─────────────────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    border: Border(top: BorderSide(color: _neonRed.withOpacity(0.25), width: 1)),
                  ),
                  child: Column(
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.18,
                          minHeight: 0,
                        ),
                        child: chatMessages.isEmpty
                            ? Center(
                                child: Text('Say hi! 👋',
                                    style: TextStyle(color: Colors.white.withOpacity(0.25))))
                            : ListView.builder(
                                reverse: true,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                itemCount: chatMessages.length,
                                itemBuilder: (_, i) {
                                  final msg = chatMessages[chatMessages.length - 1 - i];
                                  if (msg.isSystem) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 3),
                                      child: Center(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.05),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: Colors.white12),
                                          ),
                                          child: Text(msg.text,
                                              style: TextStyle(
                                                  color: Colors.white.withOpacity(0.4), fontSize: 11)),
                                        ),
                                      ),
                                    );
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 3),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.04),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          CircleAvatar(
                                            radius: 10,
                                            backgroundColor: Colors.primaries[
                                                    msg.username.hashCode % Colors.primaries.length]
                                                .withOpacity(0.8),
                                            child: Text(msg.username[0].toUpperCase(),
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold)),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: RichText(
                                              text: TextSpan(children: [
                                                TextSpan(
                                                    text: '${msg.username}  ',
                                                    style: TextStyle(
                                                        color: _neonRed.withOpacity(0.9),
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w600)),
                                                TextSpan(
                                                    text: msg.text,
                                                    style: const TextStyle(
                                                        color: Colors.white, fontSize: 13)),
                                              ]),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 6, 8, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: _neonRedBorder, width: 1),
                                ),
                                child: TextField(
                                  controller: _chatController,
                                  style: const TextStyle(color: Colors.white, fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: 'Message...',
                                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                                    border: InputBorder.none,
                                    contentPadding:
                                        const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                                    isDense: true,
                                  ),
                                  onSubmitted: (_) => _sendMessage(socket, user),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            _NeoButton(
                              color: _neonRed,
                              size: 40,
                              onTap: () => _sendMessage(socket, user),
                              child: const Icon(Icons.send_rounded, color: Colors.white, size: 17),
                            ),
                            const SizedBox(width: 6),
                            _NeoButton(
                              color: Colors.purpleAccent,
                              size: 40,
                              onTap: () {
                                if (user != null) {
                                  socket.sendWave(widget.roomId, user.id, user.username);
                                  ref.read(reactionsNotifierProvider.notifier).triggerWave(user.username);
                                  HapticsUtil.wave();
                                }
                              },
                              child: const Text('🌊', style: TextStyle(fontSize: 18)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ── Wave overlay ─────────────────────────────────────────────
            if (reactions.showWaveOverlay)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [_neonRed.withOpacity(0.15), Colors.transparent],
                        radius: 0.8,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🌊', style: TextStyle(fontSize: 56)),
                          const SizedBox(height: 8),
                          Text(
                            '${reactions.waveUsername} sent a wave!',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              shadows: [
                                Shadow(blurRadius: 20, color: _neonRed),
                                Shadow(blurRadius: 4, color: Colors.black54),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // ── Floating emojis ──────────────────────────────────────────
            ...reactions.floatingEmojis.map((e) => Positioned(
                  left: MediaQuery.of(context).size.width * e.xOffset,
                  bottom: 200,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: -120),
                    duration: const Duration(milliseconds: 2000),
                    builder: (_, value, child) => Transform.translate(
                      offset: Offset(0, value),
                      child: Opacity(opacity: (1 + value / 120).clamp(0, 1), child: child),
                    ),
                    child: Text(e.emoji, style: const TextStyle(fontSize: 28)),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  void _sendMessage(dynamic socket, dynamic user) {
    final text = _chatController.text.trim();
    if (text.isNotEmpty && user != null) {
      socket.sendMessage(widget.roomId, user.id, user.username, text);
      _chatController.clear();
    }
  }
}

// ── Neon Outline Button ───────────────────────────────────────────────────────
class _NeoButton extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;
  final Widget child;
  final double size;

  const _NeoButton({
    required this.color,
    required this.onTap,
    required this.child,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.12),
          border: Border.all(color: color.withOpacity(0.6), width: 1.5),
          boxShadow: [BoxShadow(color: color.withOpacity(0.25), blurRadius: 10)],
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ── Sync Badge ────────────────────────────────────────────────────────────────
class _SyncBadge extends StatelessWidget {
  final SyncStatus status;
  const _SyncBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (status) {
      SyncStatus.synced => (Icons.check_circle_rounded, Colors.greenAccent, 'Synced'),
      SyncStatus.drifting => (Icons.warning_amber_rounded, Colors.orangeAccent, 'Drifting'),
      SyncStatus.resyncing => (Icons.sync_rounded, Colors.cyanAccent, 'Resyncing'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
