import 'package:flutter/material.dart';

/// Standardized toast/snackbar — every "action confirmed" moment (add to
/// cart, etc.) calls this instead of building an ad hoc SnackBar. Generalizes
/// the original shell's inline `_showAdded` helper.
void showSwToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
}
