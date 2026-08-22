import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/atmosphere_service.dart';

final atmosphereServiceProvider =
    Provider<AtmosphereService>((ref) => AtmosphereService());

final atmosphereColorProvider = StateProvider<Color?>((ref) => null);

class AtmosphereNotifier extends StateNotifier<Color?> {
  final AtmosphereService _service;

  AtmosphereNotifier(this._service) : super(null);

  Future<void> updateFromThumbnail(String thumbnailUrl) async {
    final color = await _service.extractDominantColor(thumbnailUrl);
    if (color != null) {
      state = _service.atmosphereColor(color, opacity: 0.08);
    }
  }

  void clear() => state = null;
}

final atmosphereNotifierProvider =
    StateNotifierProvider<AtmosphereNotifier, Color?>((ref) {
  final service = ref.watch(atmosphereServiceProvider);
  return AtmosphereNotifier(service);
});
