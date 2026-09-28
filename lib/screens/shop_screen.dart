import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/catalog.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';
import '../widgets/common.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Shop'),
          actions: const [CoinBadge(), SizedBox(width: 12)],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Blocks'),
              Tab(text: 'Themes'),
            ],
          ),
        ),
        body: GradientBackground(
          child: Column(
            children: [
              Expanded(
                child: TabBarView(
                  children: [
                    _grid(context, [
                      for (final s in skins)
                        _Item(s.id, s.name, s.price, _SkinPreview(s.shape)),
                    ], isSkin: true),
                    _grid(context, [
                      for (final t in themes)
                        _Item(t.id, t.name, t.price, _ThemePreview(t)),
                    ], isSkin: false),
                  ],
                ),
              ),
              const BannerSlot(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _grid(
    BuildContext context,
    List<_Item> items, {
    required bool isSkin,
  }) {
    final s = context.watch<StorageService>();
    return GridView.count(
      padding: const EdgeInsets.all(16),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        for (final it in items)
          Builder(
            builder: (context) {
              final owned = (isSkin ? s.ownedSkins : s.ownedThemes).contains(
                it.id,
              );
              final selected = (isSkin ? s.skin : s.theme) == it.id;
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _onTap(context, s, it, owned, isSkin),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected ? Colors.amber : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Expanded(child: Center(child: it.preview)),
                      Text(
                        it.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      owned
                          ? Text(
                              selected ? 'SELECTED' : 'OWNED',
                              style: const TextStyle(color: Colors.white70),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.monetization_on,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text('${it.price}'),
                              ],
                            ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  void _onTap(
    BuildContext context,
    StorageService s,
    _Item it,
    bool owned,
    bool isSkin,
  ) {
    if (owned) {
      isSkin ? s.selectSkin(it.id) : s.selectTheme(it.id);
      return;
    }
    if (s.spend(it.price)) {
      isSkin ? s.unlockSkin(it.id) : s.unlockTheme(it.id);
      context.read<AudioService>().play('coin');
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Not enough coins')));
    }
  }
}

class _Item {
  final String id, name;
  final int price;
  final Widget preview;
  _Item(this.id, this.name, this.price, this.preview);
}

class _SkinPreview extends StatelessWidget {
  final BlockShape shape;
  const _SkinPreview(this.shape);

  @override
  Widget build(BuildContext context) {
    final rounded = shape == BlockShape.rounded;
    final outlined = shape == BlockShape.outlined;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final w in [50.0, 70.0, 90.0])
          Container(
            width: w,
            height: 18,
            margin: const EdgeInsets.only(bottom: 2),
            decoration: BoxDecoration(
              color: outlined ? Colors.black26 : Colors.pinkAccent,
              border: outlined
                  ? Border.all(color: Colors.pinkAccent, width: 2)
                  : null,
              borderRadius: BorderRadius.circular(rounded ? 8 : 0),
              gradient: shape == BlockShape.glossy
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFFF9EC4), Colors.pinkAccent],
                    )
                  : shape == BlockShape.striped
                  ? const LinearGradient(
                      colors: [Colors.pinkAccent, Color(0xFFFF9EC4)],
                      stops: [0.5, 0.5],
                      tileMode: TileMode.repeated,
                      end: Alignment(-0.8, 0),
                    )
                  : null,
            ),
          ),
      ],
    );
  }
}

class _ThemePreview extends StatelessWidget {
  final ColorTheme theme;
  const _ThemePreview(this.theme);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: theme.sky,
        ),
      ),
      alignment: Alignment.bottomCenter,
      child: Container(
        width: 40,
        height: 14,
        color: HSLColor.fromAHSL(
          1,
          theme.baseHue,
          theme.saturation,
          0.58,
        ).toColor(),
      ),
    );
  }
}
