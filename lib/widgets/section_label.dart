import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/constants.dart';

const _accent    = Color(0xFF4DC8E8);
const _border    = Color(0xFFCCEEF7);
const _textPrim  = Color(0xFF0D2B35);
const _textMut   = Color(0xFF5A8A98);
const _textSub   = Color(0xFF90BEC9);
const _surface   = Colors.white;
const _accentBg  = Color(0xFFE8F8FC);

// ── SectionLabel ────────────────────────────────────────────────────
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
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
}

// ── CitySelector ────────────────────────────────────────────────────
class CitySelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const CitySelector({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _CityBtn(
          label: 'Liepāja',
          active: selected == City.liepaja,
          onTap: () => onChanged(City.liepaja),
        )),
        const SizedBox(width: 10),
        Expanded(child: _CityBtn(
          label: 'Rīga',
          active: selected == City.riga,
          onTap: () => onChanged(City.riga),
        )),
      ],
    );
  }
}

class _CityBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _CityBtn({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
}

// ── LimitRow ────────────────────────────────────────────────────────
class LimitRow extends StatefulWidget {
  final String label;
  final String prefKey;
  final double defaultVal;
  final double step;
  final double min;
  final double max;
  final String Function(double) formatValue;

  const LimitRow({
    super.key,
    required this.label,
    required this.prefKey,
    required this.defaultVal,
    required this.step,
    required this.min,
    required this.max,
    required this.formatValue,
  });

  @override
  State<LimitRow> createState() => _LimitRowState();
}

class _LimitRowState extends State<LimitRow> {
  double _value = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() => _value = p.getDouble(widget.prefKey) ?? widget.defaultVal);
  }

  Future<void> _save(double v) async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble(widget.prefKey, v);
    setState(() => _value = v);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(fontSize: 13, color: _textMut),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StepBtn(
              icon: Icons.remove,
              onTap: () {
                final nv = ((_value - widget.step) * 10).round() / 10;
                if (nv >= widget.min) _save(nv);
              },
            ),
            Expanded(
              child: Center(
                child: Text(
                  widget.formatValue(_value),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: _textPrim,
                  ),
                ),
              ),
            ),
            _StepBtn(
              icon: Icons.add,
              onTap: () {
                final nv = ((_value + widget.step) * 10).round() / 10;
                if (nv <= widget.max) _save(nv);
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: _accentBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: Icon(icon, size: 20, color: _accent),
      ),
    );
  }
}

// ── InfoAccordion ───────────────────────────────────────────────────
class InfoAccordion extends StatefulWidget {
  final String city;
  const InfoAccordion({super.key, required this.city});

  @override
  State<InfoAccordion> createState() => _InfoAccordionState();
}

class _InfoAccordionState extends State<InfoAccordion> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _open = !_open),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ko uzrauga',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _textPrim,
                ),
              ),
              Icon(
                _open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: _accent,
                size: 22,
              ),
            ],
          ),
        ),
        if (_open) ...[
          const SizedBox(height: 14),
          const Divider(color: _border, height: 1),
          const SizedBox(height: 14),
          ..._alertItems(widget.city),
        ],
      ],
    );
  }

  List<Widget> _alertItems(String city) {
    final items = city == City.liepaja
        ? [
            _AlertItem(color: const Color(0xFFFF4444), label: 'Wait and Save', sub: 'Sarkans brīdinājums'),
            _AlertItem(color: const Color(0xFFFF7A00), label: 'Ārpus Liepājas', sub: 'Oranžs brīdinājums'),
            _AlertItem(color: const Color(0xFF18B870), label: 'Attālums > 3 km', sub: 'Zaļš brīdinājums'),
            _AlertItem(color: const Color(0xFF1565C0), label: 'Jauns rezervēts', sub: 'Zils brīdinājums'),
            _AlertItem(color: const Color(0xFFF9A825), label: 'Klondaika (00:00–12:00)', sub: 'Dzeltens brīdinājums'),
          ]
        : [
            _AlertItem(color: const Color(0xFFFF7A00), label: 'Ārpus Rīgas', sub: 'Oranžs brīdinājums'),
          ];
    return items.map((e) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: e,
    )).toList();
  }
}

class _AlertItem extends StatelessWidget {
  final Color color;
  final String label;
  final String sub;
  const _AlertItem({required this.color, required this.label, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w500, color: _textPrim)),
            Text(sub, style: const TextStyle(fontSize: 11, color: _textMut)),
          ],
        ),
      ],
    );
  }
}
