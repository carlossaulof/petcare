import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/app_data.dart';
import '../common/helpers.dart';
import '../common/widgets.dart';
import 'navigation.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final me = currentUser(context);
    final list = data.notificationsOf(me.id);
    final unread = data.unreadCount(me.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
        actions: [
          if (unread > 0)
            IconButton(
              tooltip: 'Marcar todas como lidas',
              icon: const Icon(Icons.done_all),
              onPressed: () => data.markAllRead(me.id),
            ),
        ],
      ),
      body: list.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_none,
              title: 'Nenhuma notificação',
              message: 'Atualizações dos atendimentos aparecem aqui em tempo real.',
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final n = list[i];
                return AppCard(
                  color: n.lida ? Colors.white : AppColors.sageLight,
                  onTap: () {
                    data.markRead(n.id);
                    if (n.agendamentoId != null) openAppointment(context, n.agendamentoId!);
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(n.titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(n.mensagem, style: const TextStyle(fontSize: 13)),
                            const SizedBox(height: 6),
                            Text(formatDateTime(n.data), style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                          ],
                        ),
                      ),
                      if (!n.lida)
                        Container(
                          margin: const EdgeInsets.only(left: 8, top: 4),
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(color: AppColors.sage, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
