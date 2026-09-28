import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists progress (coins, best score, settings, unlocks) locally.
class StorageService extends ChangeNotifier {
  late SharedPreferences _p;

  int coins = 0;
  int best = 0;
  bool muted = false;
  bool vibration = true;
  bool adsRemoved = false;
  String skin = 'flat';
  String theme = 'sunset';
  Set<String> ownedSkins = {'flat'};
  Set<String> ownedThemes = {'sunset'};

  /// Milliseconds since epoch of the very first launch.
  int firstLaunch = 0;

  Future<void> init() async {
    _p = await SharedPreferences.getInstance();
    coins = _p.getInt('coins') ?? 0;
    best = _p.getInt('best') ?? 0;
    muted = _p.getBool('muted') ?? false;
    vibration = _p.getBool('vibration') ?? true;
    adsRemoved = _p.getBool('adsRemoved') ?? false;
    skin = _p.getString('skin') ?? 'flat';
    theme = _p.getString('theme') ?? 'sunset';
    ownedSkins = (_p.getStringList('ownedSkins') ?? ['flat']).toSet();
    ownedThemes = (_p.getStringList('ownedThemes') ?? ['sunset']).toSet();
    firstLaunch = _p.getInt('firstLaunch') ?? 0;
    if (firstLaunch == 0) {
      firstLaunch = DateTime.now().millisecondsSinceEpoch;
      await _p.setInt('firstLaunch', firstLaunch);
    }
  }

  void addCoins(int n) {
    coins += n;
    _p.setInt('coins', coins);
    notifyListeners();
  }

  bool spend(int n) {
    if (coins < n) return false;
    addCoins(-n);
    return true;
  }

  /// Returns true when [score] is a new record.
  bool submitScore(int score) {
    if (score <= best) return false;
    best = score;
    _p.setInt('best', best);
    notifyListeners();
    return true;
  }

  void setMuted(bool v) {
    muted = v;
    _p.setBool('muted', v);
    notifyListeners();
  }

  void setVibration(bool v) {
    vibration = v;
    _p.setBool('vibration', v);
    notifyListeners();
  }

  void setAdsRemoved(bool v) {
    adsRemoved = v;
    _p.setBool('adsRemoved', v);
    notifyListeners();
  }

  void unlockSkin(String id) {
    ownedSkins.add(id);
    _p.setStringList('ownedSkins', ownedSkins.toList());
    selectSkin(id);
  }

  void unlockTheme(String id) {
    ownedThemes.add(id);
    _p.setStringList('ownedThemes', ownedThemes.toList());
    selectTheme(id);
  }

  void selectSkin(String id) {
    skin = id;
    _p.setString('skin', id);
    notifyListeners();
  }

  void selectTheme(String id) {
    theme = id;
    _p.setString('theme', id);
    notifyListeners();
  }
}
