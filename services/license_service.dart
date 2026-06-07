
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/constants.dart';

class LicenseService {
  static const _sheetsUrl =
      'https://script.google.com/macros/s/AKfycbyCD2UjphebDijqxCOC76M0t6D-4LE7IT2aBUaur4wHp0PQbRVC4VREFIv7Bdp86PnNLQ/exec';
  static const _checkIntervalMs = 24 * 60 * 60 * 1000; // 24h

  /// Atgriež saglabāto auto numuru
  static Future<String> getSavedAutoNr() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(PrefKeys.autoNr) ?? '';
  }

  /// Saglabā auto numuru
  static Future<void> saveAutoNr(String autoNr) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(PrefKeys.autoNr, autoNr.trim().toUpperCase());
  }

  /// Vai licence ir derīga lokāli (bez interneta)
  static Future<bool> isLicensedLocally() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(PrefKeys.licensed) ?? false;
  }

  /// Unikāls ierīces ID (Android ID analogs)
  static Future<String> getDeviceId() async {
    try {
      // Izmanto SharedPreferences kā persistent ID
      final p = await SharedPreferences.getInstance();
      String? id = p.getString('device_id');
      if (id == null || id.isEmpty) {
        // Ģenerē un saglabā vienreizēju ID
        final ts = DateTime.now().millisecondsSinceEpoch.toRadixString(16);
        id = 'flutter_$ts';
        await p.setString('device_id', id);
      }
      return id;
    } catch (_) {
      return 'unknown';
    }
  }

  /// Pārbauda licenci serverī.
  /// Ja pēdējā pārbaude < 24h — izmanto kešu.
  /// Atgriež true ja licencēts.
  static Future<bool> checkLicense() async {
    final p = await SharedPreferences.getInstance();
    final autoNr = p.getString(PrefKeys.autoNr) ?? '';

    if (autoNr.isEmpty) return false;

    final lastCheck = p.getInt(PrefKeys.lastCheck) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Izmanto kešu ja pārbaude bija nesen
    if (now - lastCheck < _checkIntervalMs) {
      return p.getBool(PrefKeys.licensed) ?? false;
    }

    // Pārbauda serverī
    final deviceId = await getDeviceId();
    bool result = false;

    try {
      final uri = Uri.parse(_sheetsUrl).replace(queryParameters: {
        'auto_nr': autoNr,
        'device_id': deviceId,
        'version': Defaults.appVersion,
      });

      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      result = response.body.trim() == 'OK';
    } catch (_) {
      // Nav interneta — izmanto pēdējo zināmo rezultātu
      result = p.getBool(PrefKeys.licensed) ?? false;
    }

    await p.setBool(PrefKeys.licensed, result);
    await p.setInt(PrefKeys.lastCheck, now);
    return result;
  }

  /// Piespiedu pārbaude (notīra kešu)
  static Future<bool> forceCheck() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(PrefKeys.lastCheck, 0);
    return checkLicense();
  }
}
