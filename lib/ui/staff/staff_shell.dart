import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_data.dart';
import '../common/helpers.dart';
import '../common/widgets.dart';
import '../shared/notifications_screen.dart';
import '../shared/profile_screen.dart';
import 'animals_screen.dart';
import 'staff_dashboard_screen.dart';
import 'vet/vet_area_screen.dart';

class StaffShell extends StatefulWidget {
  const StaffShell({super.key});

  @override
  State<StaffShell> createState() => _StaffShellState();
}

class _StaffShellState extends State<StaffShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final me = currentUser(context);
    final unread = data.unreadCount(me.id);
    final vet = me.canAccessVetArea;

    final pages = <Widget>[
      const StaffDashboardScreen(),
      const AnimalsScreen(),
      if (vet) const VetAreaScreen(),
      const NotificationsScreen(),
      const ProfileScreen(),
    ];
    final destinations = <NavigationDestination>[
      const NavigationDestination(
          icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Painel'),
      const NavigationDestination(icon: Icon(Icons.pets_outlined), selectedIcon: Icon(Icons.pets), label: 'Animais'),
      if (vet)
        const NavigationDestination(
            icon: Icon(Icons.medical_services_outlined), selectedIcon: Icon(Icons.medical_services), label: 'Vet'),
      NavigationDestination(
          icon: BadgeIcon(icon: Icons.notifications_none, count: unread),
          selectedIcon: BadgeIcon(icon: Icons.notifications, count: unread),
          label: 'Avisos'),
      const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
    ];
    final index = _index.clamp(0, pages.length - 1).toInt();

    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: destinations,
      ),
    );
  }
}
