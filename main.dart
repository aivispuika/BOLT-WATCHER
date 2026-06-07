import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/main_screen.dart';
import 'widgets/alert_overlay.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Color(0xFFEAF6FD),
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const BoltWatcherApp());
}

class BoltWatcherApp extends StatelessWidget {
  const BoltWatcherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bolt Watcher',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF5BC8F0),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF4FBFF),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const AlertOverlay(
        child: MainScreen(),
      ),
    );
  }
}
