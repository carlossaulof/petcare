import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_data.dart';
import '../common/helpers.dart';
import '../common/widgets.dart';
import '../shared/notifications_screen.dart';
import '../shared/profile_screen.dart';
import 'client_appointments_screen.dart';
import 'client_home_screen.dart';
import 'pets_screen.dart';

class ClientShell extends StatefulWidget {
  const ClientShell({super.key});

  @override
  State<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends State<ClientShell> {
  int _index = 0;

  void goTo(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final me = currentUser(context);
    final unread = data.unreadCount(me.id);

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          ClientHomeScreen(onNavigate: goTo),
          const PetsScreen(),
          const ClientAppointmentsScreen(),
          const NotificationsScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: goTo,
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Início'),
          const NavigationDestination(icon: Icon(Icons.pets_outlined), selectedIcon: Icon(Icons.pets), label: 'Pets'),
          const NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Agenda'),
          NavigationDestination(
              icon: BadgeIcon(icon: Icons.notifications_none, count: unread),
              selectedIcon: BadgeIcon(icon: Icons.notifications, count: unread),
              label: 'Avisos'),
          const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
