import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/storage_service.dart';
import '../widgets/common.dart';
import 'game_screen.dart';
import 'settings_screen.dart';
import 'shop_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final best = context.watch<StorageService>().best;
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const CoinBadge(),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const _Logo(),
              const SizedBox(height: 12),
              Text(
                'BEST  $best',
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              BigButton(
                'PLAY',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GameScreen()),
                ),
              ),
              const SizedBox(height: 14),
              BigButton(
                'SHOP',
                icon: Icons.storefront,
                color: Colors.white70,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ShopScreen()),
                ),
              ),
              const Spacer(),
              const BannerSlot(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    final widths = [70.0, 110.0, 150.0, 190.0];
    final colors = [
      Colors.pinkAccent,
      Colors.orangeAccent,
      Colors.amber,
      Colors.redAccent,
    ];
    return Column(
      children: [
        for (var i = 0; i < widths.length; i++)
          Container(width: widths[i], height: 22, color: colors[i]),
        const SizedBox(height: 18),
        const Text(
          'STACK TOWER',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}
