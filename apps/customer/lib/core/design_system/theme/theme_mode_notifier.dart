import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';

const _themeModeKey = 'sw.theme_mode';

/// Пользовательский выбор темы (System/Light/Dark) поверх системной темы
/// устройства — раньше приложение всегда следовало ThemeMode.system и
/// переключить вручную было нельзя. Хранится в LocalKv, читается один раз
/// при старте; app.dart падает обратно на system, пока значение грузится.
class ThemeModeNotifier extends AsyncNotifier<ThemeMode> {
  @override
  Future<ThemeMode> build() async {
    final stored = await ref.watch(localKvProvider).getString(_themeModeKey);
    return switch (stored) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = AsyncData(mode);
    await ref.read(localKvProvider).setString(_themeModeKey, mode.name);
  }
}

final themeModeProvider = AsyncNotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
