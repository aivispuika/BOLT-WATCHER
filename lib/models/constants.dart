// Brīdinājumu tipi
class AlertType {
  static const String waitSave    = 'wait_and_save';
  static const String outside     = 'outside_city';
  static const String lowValue    = 'low_value';
  static const String reserved    = 'reserved_available';
  static const String reservedNew = 'reserved_new';
  static const String klondaika   = 'klondaika';
}

// Noklusējuma limiti
class Defaults {
  static const double minPriceEur = 3.50;
  static const double maxPickupKm = 3.0;
  static const double reservedHighPrice = 15.0;
}

// SharedPreferences atslēgas
class PrefKeys {
  static const String city   = 'selected_city';
  static const String maxKm  = 'max_km';
  static const String minEur = 'min_eur';
}

// Pilsētas
class City {
  static const String liepaja = 'liepaja';
  static const String riga    = 'riga';
}

// Brīdinājuma datu modelis
class AlertData {
  final String type;
  final String extra;

  const AlertData({required this.type, required this.extra});

  // Low value extra: "DIST|PRICE|DEST"
  String get distStr  => extra.split('|').length > 0 ? extra.split('|')[0] : '';
  String get priceStr => extra.split('|').length > 1 ? extra.split('|')[1] : '';
  String get destAddr => extra.split('|').length > 2 ? extra.split('|')[2] : '';

  // Outside extra: "CODE|CITY"
  String get outsideCode => extra.split('|').length > 0 ? extra.split('|')[0] : '';
  String get outsideCity => extra.split('|').length > 1 ? extra.split('|')[1] : '';
}
