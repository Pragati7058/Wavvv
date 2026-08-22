import 'package:flutter_riverpod/flutter_riverpod.dart';

class FloatingEmoji {
  final String emoji;
  final double xOffset; // 0.0 - 1.0, horizontal position
  final String id;

  const FloatingEmoji({
    required this.emoji,
    required this.xOffset,
    required this.id,
  });
}

class ReactionsState {
  final bool showWaveOverlay;
  final String? waveUsername;
  final List<FloatingEmoji> floatingEmojis;

  const ReactionsState({
    this.showWaveOverlay = false,
    this.waveUsername,
    this.floatingEmojis = const [],
  });

  ReactionsState copyWith({
    bool? showWaveOverlay,
    String? waveUsername,
    List<FloatingEmoji>? floatingEmojis,
  }) =>
      ReactionsState(
        showWaveOverlay: showWaveOverlay ?? this.showWaveOverlay,
        waveUsername: waveUsername ?? this.waveUsername,
        floatingEmojis: floatingEmojis ?? this.floatingEmojis,
      );
}

class ReactionsNotifier extends StateNotifier<ReactionsState> {
  ReactionsNotifier() : super(const ReactionsState());

  void triggerWave(String username) {
    state = state.copyWith(showWaveOverlay: true, waveUsername: username);
    Future.delayed(const Duration(milliseconds: 700), () {
      state = state.copyWith(showWaveOverlay: false, waveUsername: null);
    });
  }

  void addFloatingEmoji(String emoji) {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final xOffset = 0.1 + (id.hashCode % 80) / 100.0;
    final newEmoji = FloatingEmoji(emoji: emoji, xOffset: xOffset, id: id);
    state = state.copyWith(floatingEmojis: [...state.floatingEmojis, newEmoji]);
    // Remove after animation completes
    Future.delayed(const Duration(milliseconds: 2200), () {
      state = state.copyWith(
        floatingEmojis: state.floatingEmojis.where((e) => e.id != id).toList(),
      );
    });
  }
}

final reactionsNotifierProvider =
    StateNotifierProvider<ReactionsNotifier, ReactionsState>(
        (ref) => ReactionsNotifier());
