import 'package:flutter/material.dart';

/// Visual style for the blocks.
enum BlockShape { flat, rounded, glossy, outlined, striped }

class BlockSkin {
  final String id;
  final String name;
  final BlockShape shape;
  final int price;
  const BlockSkin(this.id, this.name, this.shape, this.price);
}

class ColorTheme {
  final String id;
  final String name;

  /// Hue where the tower starts; hue drifts upward as the tower grows.
  final double baseHue;
  final double saturation;
  final List<Color> sky;
  final int price;
  const ColorTheme(
    this.id,
    this.name,
    this.baseHue,
    this.saturation,
    this.sky,
    this.price,
  );
}

const skins = <BlockSkin>[
  BlockSkin('flat', 'Classic', BlockShape.flat, 0),
  BlockSkin('rounded', 'Candy', BlockShape.rounded, 150),
  BlockSkin('glossy', 'Glass', BlockShape.glossy, 300),
  BlockSkin('outlined', 'Neon', BlockShape.outlined, 500),
  BlockSkin('striped', 'Stripes', BlockShape.striped, 800),
];

const themes = <ColorTheme>[
  ColorTheme('sunset', 'Sunset', 10, 0.65, [
    Color(0xFF2B1055),
    Color(0xFFD53369),
  ], 0),
  ColorTheme('ocean', 'Ocean', 190, 0.6, [
    Color(0xFF0F2027),
    Color(0xFF2C5364),
  ], 200),
  ColorTheme('forest', 'Forest', 100, 0.55, [
    Color(0xFF134E5E),
    Color(0xFF71B280),
  ], 400),
  ColorTheme('candy', 'Candy', 300, 0.55, [
    Color(0xFFFC5C7D),
    Color(0xFF6A82FB),
  ], 600),
  ColorTheme('mono', 'Midnight', 230, 0.15, [
    Color(0xFF000000),
    Color(0xFF434343),
  ], 1000),
];

BlockSkin skinById(String id) =>
    skins.firstWhere((s) => s.id == id, orElse: () => skins.first);
ColorTheme themeById(String id) =>
    themes.firstWhere((t) => t.id == id, orElse: () => themes.first);
