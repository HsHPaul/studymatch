import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeModeNotifier extends StateNotifier<bool> {
  static const _storage = FlutterSecureStorage();
  static const _key = 'dark_mode';

  ThemeModeNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final val = await _storage.read(key: _key);
    if (mounted) state = val == 'true';
  }

  Future<void> toggle() async {
    state = !state;
    await _storage.write(key: _key, value: state.toString());
  }
}

final isDarkModeProvider =
    StateNotifierProvider<ThemeModeNotifier, bool>(
  (ref) => ThemeModeNotifier(),
);
