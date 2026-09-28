import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/iap_service.dart';
import '../services/storage_service.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<StorageService>();
    final iap = context.read<IapService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: GradientBackground(
        child: ListView(
          children: [
            SwitchListTile(
              title: const Text('Sound'),
              secondary: Icon(s.muted ? Icons.volume_off : Icons.volume_up),
              value: !s.muted,
              onChanged: (v) => s.setMuted(!v),
            ),
            SwitchListTile(
              title: const Text('Vibration'),
              secondary: const Icon(Icons.vibration),
              value: s.vibration,
              onChanged: s.setVibration,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.block),
              title: Text(
                s.adsRemoved ? 'Ads removed — thank you!' : 'Remove Ads',
              ),
              subtitle: s.adsRemoved
                  ? null
                  : Text(
                      iap.product?.price ?? 'Removes banner & interstitial ads',
                    ),
              onTap: s.adsRemoved
                  ? null
                  : () async {
                      final ok = await iap.buyRemoveAds();
                      if (!ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Store not available right now'),
                          ),
                        );
                      }
                    },
            ),
            ListTile(
              leading: const Icon(Icons.restore),
              title: const Text('Restore purchases'),
              onTap: iap.restore,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('Privacy Policy'),
              onTap: () => launchUrl(
                Uri.parse(privacyPolicyUrl),
                mode: LaunchMode.externalApplication,
              ),
            ),
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Stack Tower by EliteP'),
              subtitle: Text('Version 1.0.0'),
            ),
          ],
        ),
      ),
    );
  }
}
