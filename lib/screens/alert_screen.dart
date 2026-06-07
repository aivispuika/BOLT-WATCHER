import 'package:flutter/material.dart';
import '../models/constants.dart';
import '../services/alert_service.dart';

/// Universāls brīdinājumu ekrāns.
/// Parādās virs Bolt lietotnes, automātiski aizveras pēc 20 sek.
class AlertScreen extends StatefulWidget {
  final AlertData alert;

  const AlertScreen({super.key, required this.alert});

  @override
  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> {
  @override
  void initState() {
    super.initState();
    // Auto aizvēršana pēc 20 sek
    Future.delayed(const Duration(seconds: 20), () {
      if (mounted) _close();
    });
  }

  void _close() {
    AlertService.acknowledgeAlert(widget.alert.type, widget.alert.extra);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () {}, // neaizver ar tap ārpus kartes
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildCard(),
          ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    switch (widget.alert.type) {
      case AlertType.waitSave:
        return _WaitSaveCard(onClose: _close);
      case AlertType.outside:
        return _OutsideCard(alert: widget.alert, onClose: _close);
      case AlertType.reservedNew:
        return _ReservedCard(alert: widget.alert, onClose: _close);
      case AlertType.klondaika:
        return _KlondaikaCard(onClose: _close);
      case AlertType.lowValue:
        return _LowValueCard(alert: widget.alert, onClose: _close);
      default:
        return _WaitSaveCard(onClose: _close);
    }
  }
}

// ── Wait and Save — sarkans ─────────────────────────────────────────
class _WaitSaveCard extends StatelessWidget {
  final VoidCallback onClose;
  const _WaitSaveCard({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return _BaseCard(
      color: const Color(0xFFC62828),
      title: '⚠  WAIT AND SAVE!',
      message: 'Bolt pasūtījumā parādījās\n"Wait and Save"!',
      onClose: onClose,
    );
  }
}

// ── Ārpus pilsētas — oranžs ─────────────────────────────────────────
class _OutsideCard extends StatelessWidget {
  final AlertData alert;
  final VoidCallback onClose;
  const _OutsideCard({required this.alert, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final code = alert.outsideCode;
    final city = alert.outsideCity;
    final sub = code.isEmpty
        ? null
        : 'Pasta indekss: $code\n'
          '(${city.contains('Liep') ? 'Liepāja: LV-3401–3416' : 'Rīga: LV-1001–1109'})';
    return _BaseCard(
      color: const Color(0xFFBF360C),
      title: '⚠  ĀRPUS ${city.toUpperCase()}!',
      message: 'Adrese ir ārpus\n$city robežām!',
      sub: sub,
      onClose: onClose,
    );
  }
}

// ── Jauns rezervēts — zils ──────────────────────────────────────────
class _ReservedCard extends StatelessWidget {
  final AlertData alert;
  final VoidCallback onClose;
  const _ReservedCard({required this.alert, required this.onClose});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF1565C0);
    return _buildRoundedCard(
      color: bg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '⚠  JAUNS REZERVĒTS BRAUCIENS',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (alert.extra.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              alert.extra,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
          const SizedBox(height: 20),
          _CloseButton(color: bg, onClose: onClose),
        ],
      ),
    );
  }
}

// ── Klondaika — dzeltens ────────────────────────────────────────────
class _KlondaikaCard extends StatelessWidget {
  final VoidCallback onClose;
  const _KlondaikaCard({required this.onClose});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF9A825);
    return _buildRoundedCard(
      color: bg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '⚠  KLONDAIKA',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 20),
          _CloseButton(color: bg, onClose: onClose),
        ],
      ),
    );
  }
}

// ── Liels attālums — zaļš, pilns ekrāns ────────────────────────────
class _LowValueCard extends StatelessWidget {
  final AlertData alert;
  final VoidCallback onClose;
  const _LowValueCard({required this.alert, required this.onClose});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF2E7D32);
    return Container(
      width: double.infinity,
      color: bg,
      padding: const EdgeInsets.fromLTRB(32, 36, 32, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (alert.priceStr.isNotEmpty)
            _ValueRow(label: 'summa', value: alert.priceStr),
          if (alert.distStr.isNotEmpty)
            _ValueRow(label: 'attālums', value: alert.distStr),
          if (alert.destAddr.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              alert.destAddr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                color: Colors.white,
              ),
            ),
          ],
          const SizedBox(height: 20),
          _CloseButton(color: bg, onClose: onClose),
        ],
      ),
    );
  }
}

// ── Palīgloģikas veidņi ──────────────────────────────────────────────

class _BaseCard extends StatelessWidget {
  final Color color;
  final String title;
  final String message;
  final String? sub;
  final VoidCallback onClose;

  const _BaseCard({
    required this.color,
    required this.title,
    required this.message,
    this.sub,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return _buildRoundedCard(
      color: color,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, color: Colors.white, height: 1.5),
          ),
          if (sub != null) ...[
            const SizedBox(height: 8),
            Text(
              sub!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.white),
            ),
          ],
          const SizedBox(height: 20),
          _CloseButton(color: color, onClose: onClose),
        ],
      ),
    );
  }
}

Widget _buildRoundedCard({required Color color, required Widget child}) {
  return Container(
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
    ),
    padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
    child: child,
  );
}

class _CloseButton extends StatelessWidget {
  final Color color;
  final VoidCallback onClose;
  const _CloseButton({required this.color, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onClose,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          '✓  SAPRATU',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  final String label;
  final String value;
  const _ValueRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            '$label  ',
            style: const TextStyle(fontSize: 20, color: Colors.white),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 31,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
