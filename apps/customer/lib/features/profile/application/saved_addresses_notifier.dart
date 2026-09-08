import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/delivery.dart';
import '../../../core/models/saved_address.dart';
import '../../../core/providers.dart';

const _storageKey = 'silkway.addresses.v1';

/// Адресная книга покупателя: несколько сохранённых адресов доставки, один
/// из которых может быть отмечен адресом по умолчанию. Хранится локально
/// через LocalKv (тот же приём, что и в [ProfileNotifier]) — как и профиль,
/// не привязано к customerId и не синхронизируется с бэкендом; этого
/// достаточно для одного устройства на пользователя.
class SavedAddressesNotifier extends AsyncNotifier<List<SavedAddress>> {
  @override
  Future<List<SavedAddress>> build() async {
    final raw = await ref.watch(localKvProvider).getString(_storageKey);
    if (raw == null) return const [];
    try {
      return (jsonDecode(raw) as List<dynamic>).map((e) => SavedAddress.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _persist(List<SavedAddress> addresses) async {
    await ref.read(localKvProvider).setString(_storageKey, jsonEncode(addresses.map((a) => a.toJson()).toList()));
    state = AsyncData(addresses);
  }

  /// Первый сохранённый адрес автоматически становится адресом по
  /// умолчанию — иначе он был бы бесполезен, пока пользователь не зайдёт
  /// отдельно отметить его вручную.
  Future<SavedAddress> add(DeliveryAddress address) async {
    final current = state.valueOrNull ?? const [];
    final saved = SavedAddress(id: const Uuid().v4(), address: address, isDefault: current.isEmpty);
    await _persist([...current, saved]);
    return saved;
  }

  Future<void> remove(String id) async {
    final current = state.valueOrNull ?? const [];
    final removedWasDefault = current.any((a) => a.id == id && a.isDefault);
    var next = current.where((a) => a.id != id).toList();
    // Без адреса по умолчанию первый оставшийся становится им — иначе книга
    // могла бы остаться вовсе без дефолта после удаления.
    if (removedWasDefault && next.isNotEmpty) {
      next = [next.first.copyWith(isDefault: true), ...next.skip(1)];
    }
    await _persist(next);
  }

  Future<void> setDefault(String id) async {
    final current = state.valueOrNull ?? const [];
    await _persist([for (final a in current) a.copyWith(isDefault: a.id == id)]);
  }
}

final savedAddressesProvider = AsyncNotifierProvider<SavedAddressesNotifier, List<SavedAddress>>(SavedAddressesNotifier.new);
