import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_data.dart';
import '../common/helpers.dart';
import '../common/widgets.dart';
import '../shared/notifications_screen.dart';
import '../shared/profile_screen.dart';
import 'management_hub_screen.dart';
import 'manager_agenda_screen.dart';
import 'manager_dashboard_screen.dart';

class ManagerShell extends StatefulWidget {
  const ManagerShell({super.key});

  @override
  State<ManagerShell> createState() => _ManagerShellState();
}

class _ManagerShellState extends State<ManagerShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final me = currentUser(context);
    final unread = data.unreadCount(me.id);

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          ManagerDashboardScreen(onNavigate: (i) => setState(() => _index = i)),
          const ManagerAgendaScreen(),
          const ManagementHubScreen(),
          const NotificationsScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Painel'),
          const NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Agenda'),
          const NavigationDestination(
              icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Gestão'),
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
