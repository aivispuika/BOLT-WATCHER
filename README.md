# BoltWatcher — Flutter versija

Android lietotne Bolt šoferu palīgam. Uzrauga Bolt Driver ekrānu un brīdina par svarīgiem notikumiem.

## Projekta struktūra

```
boltwatcher_flutter/
├── lib/
│   ├── main.dart                      # Lietotnes ieeja
│   ├── models/
│   │   └── constants.dart             # Konstantes, AlertData modelis
│   ├── services/
│   │   ├── license_service.dart       # Licences pārbaude (Dart)
│   │   └── alert_service.dart         # Flutter↔Native kanāls
│   ├── screens/
│   │   ├── main_screen.dart           # Galvenais iestatījumu skats
│   │   └── alert_screen.dart          # Visi brīdinājumu ekrāni
│   └── widgets/
│       ├── section_label.dart         # UI komponentes (visi widgets)
│       └── alert_overlay.dart         # Klausās native brīdinājumus
└── android/app/src/main/
    ├── AndroidManifest.xml
    ├── java/com/boltwatcher/
    │   ├── MainActivity.java           # Flutter host + MethodChannel/EventChannel
    │   ├── BoltAccessibilityService.java  # Galvenā loģika (nemainīta)
    │   ├── LicenseManager.java         # Licences pārbaude (Java)
    │   └── BootReceiver.java           # Boot paziņojums
    └── res/xml/
        └── accessibility_service_config.xml
```

## Arhitektūra: Flutter ↔ Native saziņa

```
BoltAccessibilityService (Java)
        │
        │ EventChannel "com.boltwatcher/alert_events"
        ▼
MainActivity.java  ←→  MethodChannel "com.boltwatcher/alerts"
        │
        │ Dart Stream
        ▼
AlertOverlay (Flutter) → AlertScreen → brīdinājuma logs
```

**EventChannel** — vienvirziena: native → Flutter (brīdinājumi)
**MethodChannel** — divvirzienu: Flutter izsauc native (ack, status, accessibility)

## Uzstādīšana

### Prasības
- Flutter 3.x vai jaunāks
- Android SDK 24+
- Java 11+

### 1. Atkarības
```bash
flutter pub get
```

### 2. Android build.gradle
`android/app/build.gradle` jāpievieno:
```gradle
android {
    compileSdkVersion 34
    defaultConfig {
        minSdkVersion 24
        targetSdkVersion 34
    }
}
dependencies {
    implementation 'androidx.core:core-ktx:1.12.0'
}
```

### 3. Strings resurss
`android/app/src/main/res/values/strings.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">Bolt Watcher</string>
    <string name="accessibility_service_description">
        Uzrauga Bolt Driver un brīdina par svarīgiem pasūtījumiem.
    </string>
</resources>
```

### 4. Build un palaišana
```bash
flutter run                    # debug
flutter build apk --release    # release APK
```

## Brīdinājumu veidi

| Krāsa   | Tips              | Apraksts                            |
|---------|-------------------|-------------------------------------|
| 🔴 Sarkans | wait_and_save  | Wait and Save (tikai Liepājā)       |
| 🟠 Oranžs  | outside_city   | Adrese ārpus pilsētas robežām       |
| 🟢 Zaļš    | low_value      | Liels attālums līdz klientam        |
| 🔵 Zils    | reserved_new   | Jauns rezervēts brauciens           |
| 🟡 Dzeltens| klondaika      | Klondaika nakts (00:00–12:00)       |

## Atšķirības no oriģināla (Java)

| Oriģināls | Flutter versija |
|-----------|----------------|
| `AlertActivity.java` | `alert_screen.dart` |
| `LowValueActivity.java` | `alert_screen.dart` (`_LowValueCard`) |
| `MainActivity.java` | `main_screen.dart` + `MainActivity.java` (host) |
| `LicenseManager.java` | `license_service.dart` + `LicenseManager.java` |
| `OverlayManager.java` | `alert_overlay.dart` (EventChannel) |
| `BoltAccessibilityService.java` | Nemainīts — native Android only |
