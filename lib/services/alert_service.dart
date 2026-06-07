import 'package:flutter/services.dart';

/// Flutter ↔ Native sakaru kanāls brīdinājumiem.
/// Native Android puse (BoltAccessibilityService) sazinās ar Flutter
/// caur MethodChannel un EventChannel.
class AlertService {
  static const _channel = MethodChannel('com.boltwatcher/alerts');
  static const _eventChannel = EventChannel('com.boltwatcher/alert_events');

  // Acknowledged stāvokļi (sinhronizēti ar native pusi)
  static String acknowledgedWaitSave  = '';
  static String acknowledgedOutside   = '';
  static String acknowledgedLowValue  = '';
  static String acknowledgedKlondaika = '';
  static int    acknowledgedReservedCount = -1;
  static bool   alertIsShowing = false;

  /// Klausās brīdinājumu eventi no native servisa
  static Stream<Map<String, dynamic>> get alertStream {
    return _eventChannel
        .receiveBroadcastStream()
        .map((event) => Map<String, dynamic>.from(event as Map));
  }

  /// Paziņo native pusei ka brīdinājums apstiprināts
  static Future<void> acknowledgeAlert(String type, String extra) async {
    try {
      await _channel.invokeMethod('acknowledgeAlert', {
        'type': type,
        'extra': extra,
      });
    } catch (_) {}
    alertIsShowing = false;
  }

  /// Nolasa pašreizējos iestatījumus no native servisa
  static Future<Map<String, dynamic>> getServiceStatus() async {
    try {
      final result = await _channel.invokeMethod('getStatus');
      return Map<String, dynamic>.from(result as Map);
    } catch (_) {
      return {};
    }
  }
}
