import 'package:comic_fest/screens/home/dashboard_screen.dart';
import 'package:comic_fest/screens/events/events_screen.dart';
import 'package:comic_fest/screens/map/map_screen.dart';
import 'package:comic_fest/screens/shop/shop_screen.dart';
import 'package:comic_fest/screens/profile/profile_screen.dart';
import 'package:comic_fest/screens/tickets/qr_scanner_screen.dart';
import 'package:flutter/material.dart';

class HomeNavScreen extends StatefulWidget {
  const HomeNavScreen({super.key});

  @override
  State<HomeNavScreen> createState() => _HomeNavScreenState();
}

class _HomeNavScreenState extends State<HomeNavScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    EventsScreen(),
    MapScreen(),
    ShopScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: colorScheme.onSurface),
            selectedIcon: Icon(Icons.home, color: colorScheme.primary),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined, color: colorScheme.onSurface),
            selectedIcon: Icon(Icons.calendar_today, color: colorScheme.primary),
            label: 'Agenda',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined, color: colorScheme.onSurface),
            selectedIcon: Icon(Icons.map, color: colorScheme.primary),
            label: 'Mapa',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined, color: colorScheme.onSurface),
            selectedIcon: Icon(Icons.shopping_bag, color: colorScheme.primary),
            label: 'Tienda',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined, color: colorScheme.onSurface),
            selectedIcon: Icon(Icons.person, color: colorScheme.primary),
            label: 'Perfil',
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: FloatingActionButton.large(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const QRScannerScreen()),
            );
          },
          elevation: 6,
          child: const Icon(Icons.qr_code_scanner, size: 32),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
