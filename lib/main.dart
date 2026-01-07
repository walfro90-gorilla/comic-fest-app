import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:comic_fest/theme.dart';
import 'package:comic_fest/core/connectivity_service.dart';
import 'package:comic_fest/screens/splash_screen.dart';
import 'package:comic_fest/screens/tickets/tickets_list_screen.dart';
import 'package:comic_fest/screens/tickets/buy_tickets_screen.dart';
import 'package:comic_fest/screens/tickets/qr_scanner_screen.dart';
import 'package:comic_fest/screens/points/points_screen.dart';
import 'package:comic_fest/screens/webview_screen.dart';
import 'package:comic_fest/supabase/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Inicializar Supabase
  await SupabaseConfig.initialize();
  debugPrint('✅ Supabase inicializado correctamente');

  // Inicializar servicio de conectividad
  await ConnectivityService.instance.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Comic Fest',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
      routes: {
        '/my-tickets': (context) => const TicketsListScreen(),
        '/buy-tickets': (context) => const BuyTicketsScreen(),
        '/scan-tickets': (context) => const QRScannerScreen(),
        '/points': (context) => const PointsScreen(),
        '/webview': (context) => const WebViewScreen(),
      },
    );
  }
}
