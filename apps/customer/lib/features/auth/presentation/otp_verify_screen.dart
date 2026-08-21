import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/widgets/sw_toast.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../application/session_notifier.dart';

/// Ввод кода из SMS — второй шаг входа.
///
/// В моках и в dev-режиме бэкенда подходит код `0000`.
class OtpVerifyScreen extends ConsumerStatefulWidget {
  const OtpVerifyScreen({super.key, required this.phone, this.returnTo});

  final String phone;
  final String? returnTo;

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen> {
  final _controller = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final verified = await ref.read(sessionNotifierProvider.notifier).verifyOtp(widget.phone, _controller.text);
      if (!mounted) return;
      if (verified) {
        context.go(widget.returnTo ?? '/');
      } else {
        showSwToast(context, AppLocalizations.of(context).authOtpInvalid);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.authOtpTitle)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.authOtpSentTo(widget.phone)),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: InputDecoration(border: const OutlineInputBorder(), labelText: l10n.authOtpLabel),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l10n.authOtpConfirm),
            ),
          ],
        ),
      ),
    );
  }
}
