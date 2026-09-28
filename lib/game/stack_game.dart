import 'dart:math';
import 'dart:ui';

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart' show HSLColor;

import '../data/catalog.dart';

class _Block {
  double x; // center
  double width;
  final int level;
  _Block(this.x, this.width, this.level);
}

class _Debris {
  double x, y, width, vx, spin;
  double vy = 0, angle = 0;
  final int level;
  _Debris(this.x, this.y, this.width, this.vx, this.level, {this.spin = 0});
}

class _Popup {
  final String text;
  double y;
  double life = 1;
  _Popup(this.text, this.y);
}

enum DropResult { placed, perfect, missed }

/// One-tap stacking game. World units: x centred at 0, y grows upward.
class StackGame extends FlameGame with TapCallbacks {
  StackGame({
    required this.skin,
    required this.theme,
    required this.onDrop,
    required this.onGameOver,
  });

  final BlockSkin skin;
  final ColorTheme theme;
  final void Function(DropResult result, int score, int perfectStreak) onDrop;
  final void Function(int score) onGameOver;

  static const blockH = 34.0;
  static const perfectTolerance = 5.0;
  static const growAfterPerfects = 3;

  final _tower = <_Block>[];
  final _debris = <_Debris>[];
  final _popups = <_Popup>[];
  late _Block _moving;
  double _dir = 1;
  double _speed = 0;
  double _cameraY = 0;
  double _time = 0;
  double _flash = 0;
  bool running = false;
  bool continued = false;
  int score = 0;
  int perfectStreak = 0;

  double get baseWidth => size.x * 0.62;
  double get _range => size.x * 0.55;

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async => reset();

  void reset() {
    _tower
      ..clear()
      ..add(_Block(0, baseWidth, 0));
    _debris.clear();
    _popups.clear();
    score = 0;
    perfectStreak = 0;
    continued = false;
    _cameraY = 0;
    _spawn();
    running = true;
  }

  void _spawn() {
    final top = _tower.last;
    _dir = _tower.length.isOdd ? 1 : -1;
    _moving = _Block(-_dir * _range, top.width, top.level + 1);
    _speed = min(160 + score * 7.0, 520);
  }

  /// Revives after a missed drop (rewarded ad). Only allowed once.
  void revive() {
    continued = true;
    running = true;
    _spawn();
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (running) drop();
  }

  void drop() {
    final top = _tower.last;
    final m = _moving;
    final dx = m.x - top.x;
    final overlap = top.width - dx.abs();

    if (overlap <= 0) {
      running = false;
      perfectStreak = 0;
      _debris.add(_Debris(m.x, _levelY(m.level), m.width, _dir * 60, m.level));
      onDrop(DropResult.missed, score, 0);
      onGameOver(score);
      return;
    }

    DropResult result;
    if (dx.abs() <= perfectTolerance) {
      perfectStreak++;
      m.x = top.x;
      if (perfectStreak >= growAfterPerfects) {
        m.width = min(m.width + baseWidth * 0.08, baseWidth);
      }
      _flash = 1;
      _popups.add(
        _Popup(
          perfectStreak > 1 ? 'PERFECT x$perfectStreak' : 'PERFECT',
          _levelY(m.level),
        ),
      );
      result = DropResult.perfect;
    } else {
      perfectStreak = 0;
      final cutW = dx.abs();
      final newX = top.x + dx / 2;
      final cutX = dx > 0
          ? newX + overlap / 2 + cutW / 2
          : newX - overlap / 2 - cutW / 2;
      _debris.add(
        _Debris(
          cutX,
          _levelY(m.level),
          cutW,
          dx.sign * 80,
          m.level,
          spin: dx.sign * 2.5,
        ),
      );
      m
        ..x = newX
        ..width = overlap;
      result = DropResult.placed;
    }
    _tower.add(m);
    score++;
    onDrop(result, score, perfectStreak);
    _spawn();
  }

  double _levelY(int level) => level * blockH;

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    if (running) {
      _moving.x += _dir * _speed * dt;
      if (_moving.x.abs() > _range) {
        _moving.x = _range * _moving.x.sign;
        _dir = -_dir;
      }
    }
    final target = max(0.0, _levelY(_tower.last.level) - size.y * 0.35);
    _cameraY += (target - _cameraY) * min(1, dt * 4);
    for (final d in _debris) {
      d.vy -= 1400 * dt;
      d.x += d.vx * dt;
      d.y += d.vy * dt;
      d.angle += d.spin * dt;
    }
    _debris.removeWhere((d) => d.y < _cameraY - size.y);
    for (final p in _popups) {
      p.life -= dt * 0.8;
      p.y += 40 * dt;
    }
    _popups.removeWhere((p) => p.life <= 0);
    _flash = max(0, _flash - dt * 3);
  }

  // ---------------- Rendering ----------------
  Color _blockColor(int level) {
    final hue = (theme.baseHue + level * 6) % 360;
    return HSLColor.fromAHSL(1, hue, theme.saturation, 0.58).toColor();
  }

  double _screenY(double worldY) => size.y * 0.78 - (worldY - _cameraY);

  @override
  void render(Canvas canvas) {
    _renderSky(canvas);
    for (final b in _tower) {
      if (_screenY(_levelY(b.level)) < -blockH) continue;
      _drawBlock(canvas, b.x, _levelY(b.level), b.width, b.level, 1);
    }
    for (final d in _debris) {
      canvas.save();
      final cx = size.x / 2 + d.x;
      final cy = _screenY(d.y) - blockH / 2;
      canvas.translate(cx, cy);
      canvas.rotate(d.angle);
      canvas.translate(-cx, -cy);
      _drawBlock(canvas, d.x, d.y, d.width, d.level, 0.9);
      canvas.restore();
    }
    if (running) {
      _drawBlock(
        canvas,
        _moving.x,
        _levelY(_moving.level),
        _moving.width,
        _moving.level,
        1,
      );
    }
    if (_flash > 0) {
      final top = _tower.last;
      final r = _blockRect(
        top.x,
        _levelY(top.level),
        top.width,
      ).inflate(6 * _flash);
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(6)),
        Paint()
          ..color = const Color(0xFFFFFFFF).withValues(alpha: _flash * 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
    for (final p in _popups) {
      _drawText(
        canvas,
        p.text,
        Offset(size.x / 2, _screenY(p.y) - 70),
        22,
        const Color(0xFFFFFFFF).withValues(alpha: p.life.clamp(0, 1)),
      );
    }
    super.render(canvas);
  }

  void _renderSky(Canvas canvas) {
    // Gradient hue drifts as the camera climbs.
    final shift = (_cameraY / 40) % 360;
    Color tint(Color c) {
      final h = HSLColor.fromColor(c);
      return h.withHue((h.hue + shift) % 360).toColor();
    }

    final rect = Offset.zero & Size(size.x, size.y);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = Gradient.linear(Offset.zero, Offset(0, size.y), [
          tint(theme.sky[0]),
          tint(theme.sky[1]),
        ]),
    );
    // Subtle stars/particles for depth.
    final p = Paint()..color = const Color(0x22FFFFFF);
    for (var i = 0; i < 24; i++) {
      final x = (i * 97.0) % size.x;
      final y = ((i * 211.0) + _cameraY * 0.3 + sin(_time + i) * 4) % size.y;
      canvas.drawCircle(Offset(x, y), 1.5 + (i % 3), p);
    }
  }

  Rect _blockRect(double x, double worldY, double w) => Rect.fromLTWH(
    size.x / 2 + x - w / 2,
    _screenY(worldY) - blockH,
    w,
    blockH,
  );

  void _drawBlock(
    Canvas canvas,
    double x,
    double worldY,
    double w,
    int level,
    double opacity,
  ) {
    final rect = _blockRect(x, worldY, w);
    final color = _blockColor(level).withValues(alpha: opacity);
    final side = HSLColor.fromColor(color)
        .withLightness(0.4)
        .toColor()
        .withValues(alpha: opacity);
    // Base "3D" lip.
    canvas.drawRect(
      Rect.fromLTWH(rect.left, rect.bottom - 6, rect.width, 6),
      Paint()..color = side,
    );
    final body = Rect.fromLTWH(
      rect.left,
      rect.top,
      rect.width,
      rect.height - 6,
    );
    final paint = Paint()..color = color;
    switch (skin.shape) {
      case BlockShape.flat:
        canvas.drawRect(body, paint);
      case BlockShape.rounded:
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(10)),
          paint,
        );
      case BlockShape.glossy:
        canvas.drawRect(body, paint);
        canvas.drawRect(
          Rect.fromLTWH(body.left, body.top, body.width, body.height * 0.4),
          Paint()..color = const Color(0x55FFFFFF),
        );
      case BlockShape.outlined:
        canvas.drawRect(body, Paint()..color = const Color(0x33000000));
        canvas.drawRect(
          body.deflate(1.5),
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
      case BlockShape.striped:
        canvas.drawRect(body, paint);
        canvas.save();
        canvas.clipRect(body);
        final sp = Paint()
          ..color = const Color(0x33FFFFFF)
          ..strokeWidth = 6;
        for (var sx = body.left - body.height; sx < body.right; sx += 16) {
          canvas.drawLine(
            Offset(sx, body.bottom),
            Offset(sx + body.height, body.top),
            sp,
          );
        }
        canvas.restore();
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset center,
    double fontSize,
    Color color,
  ) {
    final pb =
        ParagraphBuilder(
            ParagraphStyle(
              textAlign: TextAlign.center,
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
            ),
          )
          ..pushStyle(TextStyle(color: color))
          ..addText(text);
    final para = pb.build()..layout(ParagraphConstraints(width: size.x));
    canvas.drawParagraph(para, Offset(0, center.dy - para.height / 2));
  }
}
