import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LojaAtivaController extends StateNotifier<String?> {
  LojaAtivaController() : super(null) {
    _loadActiveStore();
  }

  static const String _prefsKey = 'active_store_id';

  Future<void> _loadActiveStore() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString(_prefsKey);
    state = savedId;
  }

  Future<void> setActiveStore(String? lojaId) async {
    state = lojaId;
    final prefs = await SharedPreferences.getInstance();
    if (lojaId == null || lojaId.isEmpty) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, lojaId);
    }
  }

  Future<void> clear() async {
    await setActiveStore(null);
  }
}

final lojaAtivaProvider = StateNotifierProvider<LojaAtivaController, String?>(
  (ref) => LojaAtivaController(),
);
