import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../application/session_notifier.dart';

/// Ввод телефона — первый шаг входа по SMS-коду.
///
/// `returnTo` хранит адрес, куда вернуть пользователя после успешного входа:
/// на экран входа обычно попадают не сами по себе, а с гейта на оформлении.
class PhoneEntryScreen extends ConsumerStatefulWidget {
  const PhoneEntryScreen({super.key, this.returnTo});

  final String? returnTo;

  @override
  ConsumerState<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends ConsumerState<PhoneEntryScreen> {
  final _controller = TextEditingController(text: '+7');
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await ref.read(sessionNotifierProvider.notifier).requestOtp(_controller.text);
      if (!mounted) return;
      final query = <String, String>{
        'phone': _controller.text,
        if (widget.returnTo != null) 'returnTo': widget.returnTo!,
      };
      context.push(Uri(path: '/auth/otp', queryParameters: query).toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.authPhoneTitle)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.authPhonePrompt, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(border: const OutlineInputBorder(), labelText: l10n.authPhoneLabel),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l10n.authPhoneNext),
            ),
          ],
        ),
      ),
    );
  }
}
