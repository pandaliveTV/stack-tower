import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/catalog.dart';
import '../game/stack_game.dart';
import '../services/ad_service.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';
import '../widgets/common.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final StorageService _storage = context.read<StorageService>();
  late final AdService _ads = context.read<AdService>();
  late final AudioService _audio = context.read<AudioService>();
  late final StackGame _game;

  int _score = 0;
  int _runCoins = 0;
  bool _over = false;
  bool _newBest = false;
  bool _doubled = false;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _game = StackGame(
      skin: skinById(_storage.skin),
      theme: themeById(_storage.theme),
      onDrop: _onDrop,
      onGameOver: _onGameOver,
    );
  }

  void _onDrop(DropResult r, int score, int streak) {
    switch (r) {
      case DropResult.perfect:
        _audio.play('perfect');
        _audio.heavy();
        _runCoins += 2 + (streak >= StackGame.growAfterPerfects ? 1 : 0);
      case DropResult.placed:
        _audio.play('place');
        _audio.tap();
        _runCoins += 1;
      case DropResult.missed:
        break;
    }
    setState(() {
      _score = score;
      _started = true;
    });
  }

  void _onGameOver(int score) {
    _audio.play('gameover');
    _audio.heavy();
    setState(() {
      _over = true;
      _newBest = _storage.submitScore(score);
    });
  }

  /// Banks coins and counts the attempt for interstitial pacing.
  void _finishRun() {
    _storage.addCoins(_runCoins * (_doubled ? 2 : 1));
    _ads.onAttemptFinished();
  }

  Future<void> _continueWithAd() async {
    if (await _ads.showRewarded() && mounted) {
      setState(() => _over = false);
      _game.revive();
    }
  }

  Future<void> _doubleCoins() async {
    if (await _ads.showRewarded() && mounted) {
      setState(() => _doubled = true);
      _audio.play('coin');
    }
  }

  void _restart() {
    _finishRun();
    setState(() {
      _over = false;
      _score = 0;
      _runCoins = 0;
      _doubled = false;
      _newBest = false;
      _started = false;
    });
    _game.reset();
  }

  void _home() {
    _finishRun();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _home();
      },
      child: Scaffold(
        body: Stack(
          children: [
            GameWidget(game: _game),
            SafeArea(
              child: IgnorePointer(
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      '$_score',
                      style: const TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        shadows: [Shadow(blurRadius: 8)],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.monetization_on,
                          color: Colors.amber,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '+$_runCoins',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (!_started && !_over)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 80),
                        child: Text(
                          'TAP TO DROP',
                          style: TextStyle(
                            fontSize: 20,
                            letterSpacing: 3,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (_over) _gameOverPanel(),
          ],
        ),
      ),
    );
  }

  Widget _gameOverPanel() {
    final canContinue = !_game.continued && _ads.canShowRewarded;
    return Container(
      color: Colors.black54,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _newBest ? 'NEW BEST!' : 'GAME OVER',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: _newBest ? Colors.amber : Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$_score',
            style: const TextStyle(fontSize: 72, fontWeight: FontWeight.w900),
          ),
          Text(
            'Best ${_storage.best}',
            style: const TextStyle(color: Colors.white70, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Coins +${_runCoins * (_doubled ? 2 : 1)}',
            style: const TextStyle(color: Colors.amber, fontSize: 18),
          ),
          const SizedBox(height: 24),
          if (canContinue) ...[
            BigButton(
              'CONTINUE',
              icon: Icons.ondemand_video,
              color: Colors.greenAccent,
              onPressed: _continueWithAd,
            ),
            const SizedBox(height: 12),
          ],
          if (!_doubled && _runCoins > 0 && _ads.canShowRewarded) ...[
            BigButton(
              'x2 COINS',
              icon: Icons.ondemand_video,
              color: Colors.amber,
              onPressed: _doubleCoins,
            ),
            const SizedBox(height: 12),
          ],
          BigButton('RETRY', icon: Icons.refresh, onPressed: _restart),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _home,
            icon: const Icon(Icons.home),
            label: const Text('Home'),
          ),
        ],
      ),
    );
  }
}
