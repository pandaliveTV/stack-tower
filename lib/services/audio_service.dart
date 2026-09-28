import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import 'storage_service.dart';

/// Short sound effects and light haptics, both respecting user settings.
class AudioService {
  final StorageService storage;
  final _pool = <String, AudioPlayer>{};

  AudioService(this.storage);

  Future<void> play(String name) async {
    if (storage.muted) return;
    try {
      final player = _pool.putIfAbsent(
        name,
        () => AudioPlayer()..setPlayerMode(PlayerMode.lowLatency),
      );
      await player.stop();
      await player.play(AssetSource('sounds/$name.wav'));
    } catch (_) {
      // Audio is non-critical.
    }
  }

  void tap() {
    if (storage.vibration) HapticFeedback.lightImpact();
  }

  void heavy() {
    if (storage.vibration) HapticFeedback.mediumImpact();
  }
}
