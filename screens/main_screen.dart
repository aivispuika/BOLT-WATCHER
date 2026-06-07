import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/constants.dart';
import '../widgets/section_label.dart';
import '../widgets/limit_row.dart';
import '../widgets/info_accordion.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  static const _accessibilityChannel =
      MethodChannel('com.boltwatcher/accessibility');

  bool _accessibilityEnabled = false;
  String _city = City.liepaja;

  // ── Krāsu palete — Wolt zils ─────────────────────────────────────────
  static const _accent     = Color(0xFF5BC8F0); // gaišs zils
  static const _accentDeep = Color(0xFF2AAED6); // vidēji zils teksts/border
  static const _accentBg   = Color(0xFFEAF6FD); // ļoti gaišs zils
  static const _bg         = Color(0xFFF4FBFF); // lapas fons
  static const _surface    = Colors.white;
  static const _border     = Color(0xFFCCE9F7);
  static const _textPrim   = Color(0xFF1A4A5E); // galvenais teksts
  static const _textMut    = Color(0xFF4A8BA8); // sekundārais teksts
  static const _textSub    = Color(0xFF8AC4DC); // gaišs hints

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkAccessibility();
  }

  Future<void> _loadState() async {
    final p = await SharedPreferences.getInstance();
    setState(() => _city = p.getString(PrefKeys.city) ?? City.liepaja);
    _checkAccessibility();
  }

  Future<void> _checkAccessibility() async {
    try {
      final enabled =
          await _accessibilityChannel.invokeMethod<bool>('isEnabled') ?? false;
      if (mounted) setState(() => _accessibilityEnabled = enabled);
    } catch (_) {}
  }

  Future<void> _setCity(String city) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(PrefKeys.city, city);
    setState(() => _city = city);
  }

  void _openAccessibilitySettings() =>
      _accessibilityChannel.invokeMethod('openSettings');

  @override
  Widget build(BuildContext context) {
    // Statusa joslas krāsa — tirkīza kā Bolt
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: const Color(0xFFEAF6FD),
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('DARBA PILSĒTA'),
                  _buildCitySelector(),
                  const SizedBox(height: 22),
                  _sectionLabel('UZRAUDZĪBA'),
                  _buildStatusCard(),
                  if (_city == City.liepaja) ...[
                    const SizedBox(height: 22),
                    _sectionLabel('BRĪDINĀJUMU LIMITI'),
                    _buildLimitsCard(),
                  ],
                  const SizedBox(height: 22),
                  _buildInfoCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Augšējā josla ar tirkīza fonu ────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      color: _accent,
      child: SafeArea(
        bottom: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          color: _accent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.directions_car_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bolt Watcher',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Pasūtījumu uzraugs',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Statusa indikators augšā
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: _accessibilityEnabled
                                ? const Color(0xFF7EFFC3)
                                : const Color(0xFFFF8A8A),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _accessibilityEnabled ? 'Aktīvs' : 'Izslēgts',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sadaļas uzraksts ─────────────────────────────────────────────────
  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _textSub,
          letterSpacing: 1.3,
        ),
      ),
    );
  }

  // ── Pilsētas izvēle ──────────────────────────────────────────────────
  Widget _buildCitySelector() {
    return Row(
      children: [
        Expanded(child: _cityBtn('Liepāja', City.liepaja)),
        const SizedBox(width: 10),
        Expanded(child: _cityBtn('Rīga', City.riga)),
      ],
    );
  }

  Widget _cityBtn(String label, String value) {
    final active = _city == value;
    return GestureDetector(
      onTap: () => _setCity(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 50,
        decoration: BoxDecoration(
          color: active ? _accent : _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? _accent : _border,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : _textMut,
            ),
          ),
        ),
      ),
    );
  }

  // ── Uzraudzības kartīte ──────────────────────────────────────────────
  Widget _buildStatusCard() {
    final active = _accessibilityEnabled;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFFE0FAF0)
                      : const Color(0xFFFFEEEE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  active
                      ? Icons.shield_outlined
                      : Icons.shield_outlined,
                  color: active
                      ? const Color(0xFF18B870)
                      : const Color(0xFFFF4444),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    active ? 'Uzraudzība aktīva' : 'Nav iespējota',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _textPrim,
                    ),
                  ),
                  Text(
                    active
                        ? 'Bolt Driver tiek uzraudzīts'
                        : 'Pieslēdz pieejamības servisā',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _textMut,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _actionButton(
            label: active ? 'Izslēgt uzraudzību' : 'Ieslēgt uzraudzību',
            icon: active
                ? Icons.stop_circle_outlined
                : Icons.play_circle_outline,
            filled: !active,
            danger: active,
            onTap: _openAccessibilitySettings,
          ),
        ],
      ),
    );
  }

  // ── Limitu kartīte ───────────────────────────────────────────────────
  Widget _buildLimitsCard() {
    return _card(
      child: LimitRow(
        label: 'Attālums līdz klientam',
        prefKey: PrefKeys.maxKm,
        defaultVal: Defaults.maxPickupKm,
        step: 0.5,
        min: 1.0,
        max: 20.0,
        formatValue: (v) =>
            '${v.toStringAsFixed(1).replaceAll('.', ',')} km',
      ),
    );
  }

  // ── Ko uzrauga (accordion) ───────────────────────────────────────────
  Widget _buildInfoCard() {
    return _card(child: InfoAccordion(city: _city));
  }

  // ── Kartīte ──────────────────────────────────────────────────────────
  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: child,
    );
  }

  // ── Darbības poga ────────────────────────────────────────────────────
  Widget _actionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool filled = false,
    bool danger = false,
  }) {
    final Color bg = filled ? _accent : _surface;
    final Color fg = danger
        ? const Color(0xFFFF4444)
        : (filled ? Colors.white : _accentDeep);
    final Color borderColor = danger
        ? const Color(0xFFFFDDDD)
        : (filled ? _accent : _border);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 50,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: fg),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
