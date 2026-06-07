import 'package:flutter/material.dart';

import '../models/constants.dart';
import '../services/alert_service.dart';
import '../screens/alert_screen.dart';

/// Klausās brīdinājumu strīmu no native AccessibilityService
/// un rāda atbilstošo brīdinājuma ekrānu.
/// Ietin ap galveno lietotnes saturu.
class AlertOverlay extends StatefulWidget {
  final Widget child;
  const AlertOverlay({super.key, required this.child});

  @override
  State<AlertOverlay> createState() => _AlertOverlayState();
}

class _AlertOverlayState extends State<AlertOverlay> {
  @override
  void initState() {
    super.initState();
    _listenForAlerts();
  }

  void _listenForAlerts() {
    AlertService.alertStream.listen(
      (data) {
        final type  = data['type'] as String? ?? '';
        final extra = data['extra'] as String? ?? '';
        if (!mounted) return;
        _showAlert(AlertData(type: type, extra: extra));
      },
      onError: (_) {},
    );
  }

  void _showAlert(AlertData alert) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      transitionBuilder: (ctx, anim, _, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          child: child,
        );
      },
      pageBuilder: (ctx, _, __) => AlertScreen(alert: alert),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
