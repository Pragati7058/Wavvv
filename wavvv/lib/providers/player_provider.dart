import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';

enum SyncStatus { synced, drifting, resyncing }

class PlayerState {
  final bool isPlaying;
  final double positionSeconds;
  final SyncStatus syncStatus;
  final bool isHost;
  final String? videoId;

  const PlayerState({
    this.isPlaying = false,
    this.positionSeconds = 0,
    this.syncStatus = SyncStatus.synced,
    this.isHost = false,
    this.videoId,
  });

  PlayerState copyWith({
    bool? isPlaying,
    double? positionSeconds,
    SyncStatus? syncStatus,
    bool? isHost,
    String? videoId,
  }) =>
      PlayerState(
        isPlaying: isPlaying ?? this.isPlaying,
        positionSeconds: positionSeconds ?? this.positionSeconds,
        syncStatus: syncStatus ?? this.syncStatus,
        isHost: isHost ?? this.isHost,
        videoId: videoId ?? this.videoId,
      );
}

class PlayerNotifier extends StateNotifier<PlayerState> {
  DateTime? _lastSyncTime;

  PlayerNotifier() : super(const PlayerState());

  void setHost(bool isHost) => state = state.copyWith(isHost: isHost);

  void setVideoId(String videoId) => state = state.copyWith(videoId: videoId);

  void onLocalPositionUpdate(double position) {
    state = state.copyWith(positionSeconds: position);
  }

  /// Called by guests when receiving Firestore / socket state from host.
  /// Returns true if a seek is required (drift detected).
  bool onRemoteUpdate({required bool isPlaying, required double remotePosition}) {
    final drift = (remotePosition - state.positionSeconds).abs();
    final needsSeek = drift > AppConstants.driftThresholdSeconds;

    // Throttle sync events
    final now = DateTime.now();
    if (_lastSyncTime != null &&
        now.difference(_lastSyncTime!) < AppConstants.syncThrottleDuration) {
      return false;
    }

    if (needsSeek) {
      _lastSyncTime = now;
      state = state.copyWith(
        isPlaying: isPlaying,
        positionSeconds: remotePosition,
        syncStatus: SyncStatus.resyncing,
      );
      // After sync, mark as synced
      Future.delayed(const Duration(milliseconds: 600), () {
        state = state.copyWith(syncStatus: SyncStatus.synced);
      });
      return true;
    }

    // Update sync status
    final newStatus =
        drift > 1.0 ? SyncStatus.drifting : SyncStatus.synced;
    state = state.copyWith(isPlaying: isPlaying, syncStatus: newStatus);
    return false;
  }

  void play() => state = state.copyWith(isPlaying: true);
  void pause() => state = state.copyWith(isPlaying: false);
  void seek(double position) => state = state.copyWith(positionSeconds: position);
}

final playerNotifierProvider =
    StateNotifierProvider<PlayerNotifier, PlayerState>(
        (ref) => PlayerNotifier());
