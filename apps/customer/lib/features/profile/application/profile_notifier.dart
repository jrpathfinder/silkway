import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/profile.dart';
import '../../../core/providers.dart';

const _storageKey = 'silkway.profile.v1';

/// Имя/email покупателя — читаются и сохраняются через LocalKv. Профиль не
/// привязан к конкретному покупателю ключом (в приложении одна активная
/// сессия за раз), поэтому один и тот же локальный профиль просто
/// перезаписывается при смене номера — этого достаточно для одного
/// устройства на одного пользователя.
class ProfileNotifier extends AsyncNotifier<UserProfile> {
  @override
  Future<UserProfile> build() async {
    final raw = await ref.watch(localKvProvider).getString(_storageKey);
    if (raw == null) return const UserProfile();
    try {
      return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const UserProfile();
    }
  }

  Future<void> save({required String name, required String email}) async {
    final profile = UserProfile(name: name.trim(), email: email.trim());
    await ref.read(localKvProvider).setString(_storageKey, jsonEncode(profile.toJson()));
    state = AsyncData(profile);
  }
}

final profileNotifierProvider = AsyncNotifierProvider<ProfileNotifier, UserProfile>(ProfileNotifier.new);
