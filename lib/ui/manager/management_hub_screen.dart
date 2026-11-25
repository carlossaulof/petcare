import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/app_data.dart';
import '../common/widgets.dart';
import '../staff/animals_screen.dart';
import '../staff/vet/vet_area_screen.dart';
import 'finance_screen.dart';
import 'hours_screen.dart';
import 'reports_screen.dart';
import 'services_screen.dart';
import 'team_screen.dart';

class ManagementHubScreen extends StatelessWidget {
  const ManagementHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    void go(Widget w) => Navigator.push(context, MaterialPageRoute(builder: (_) => w));
    final staffCount = data.staffMembers.where((s) => s.isFuncionario && s.ativo).length;
    final h = data.hours;
    final today = dateOnly(DateTime.now());
    final month = data.revenueBetween(DateTime(today.year, today.month), today.add(const Duration(days: 1)));

    return Scaffold(
      appBar: AppBar(title: const Text('Gestão')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          MenuTile(
            icon: Icons.spa_outlined,
            title: 'Serviços e preços',
            subtitle: '$staffCount profissionais · ${data.activeServices.length} serviços ativos',
            onTap: () => go(const ServicesScreen()),
          ),
          MenuTile(
            icon: Icons.schedule,
            title: 'Horários de funcionamento',
            subtitle: '${formatMinutesOfDay(h.aberturaMin)} às ${formatMinutesOfDay(h.fechamentoMin)} · '
                '${(h.diasFuncionamento.toList()..sort()).map((d) => weekdayShort[d]).join(', ')}',
            onTap: () => go(const HoursScreen()),
          ),
          MenuTile(
            icon: Icons.groups_outlined,
            title: 'Equipe e clientes',
            subtitle: 'Cadastro e permissões',
            onTap: () => go(const PeopleScreen()),
          ),
          MenuTile(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Financeiro',
            subtitle: 'Mês atual: ${formatMoney(month)} · pendente ${formatMoney(data.pendingAmount)}',
            color: AppColors.beige,
            onTap: () => go(const FinanceScreen()),
          ),
          MenuTile(
            icon: Icons.bar_chart,
            title: 'Relatórios',
            subtitle: 'Produtividade, cancelamentos e avaliações',
            onTap: () => go(const ReportsScreen()),
          ),
          MenuTile(
            icon: Icons.medical_services_outlined,
            title: 'Área veterinária',
            subtitle: 'Fichas clínicas, consultas e retornos',
            color: AppColors.lilac,
            onTap: () => go(const VetAreaScreen()),
          ),
          MenuTile(
            icon: Icons.pets,
            title: 'Animais',
            subtitle: '${data.activePets.length} cadastrados',
            onTap: () => go(const AnimalsScreen()),
          ),
        ],
      ),
    );
  }
}
