import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/ids.dart';
import '../services/integrations.dart';
import 'data_source.dart';
import 'models/models.dart';
import 'seed.dart';

/// Ação não permitida para o perfil do usuário.
class PermissionDenied implements Exception {
  final String message;
  PermissionDenied([this.message = 'Você não tem permissão para esta ação.']);
  @override
  String toString() => message;
}

/// Regra de negócio violada (horário ocupado, dados inconsistentes etc.).
class BusinessException implements Exception {
  final String message;
  BusinessException(this.message);
  @override
  String toString() => message;
}

/// Base de dados em memória + persistência. Toda alteração chama [commit],
/// que notifica as telas (atualização em tempo real entre os três perfis)
/// e grava os dados.
abstract class StoreBase extends ChangeNotifier {
  StoreBase({
    required this.dataSource,
    this.paymentGateway = const UnconfiguredPaymentGateway(),
    this.pushGateway = const InAppOnlyPushGateway(),
    this.emailGateway = const UnconfiguredEmailGateway(),
  });

  final PetCareDataSource dataSource;
  final PaymentGateway paymentGateway;
  final PushGateway pushGateway;
  final EmailGateway emailGateway;

  final List<UserModel> users = [];
  final List<Pet> pets = [];
  final List<ServiceModel> services = [];
  final List<Appointment> appointments = [];
  final List<Payment> payments = [];
  final List<Review> reviews = [];
  final List<AppNotification> notifications = [];
  final List<ClinicalEntry> clinicalEntries = [];
  BusinessHours hours = BusinessHours();

  bool loaded = false;
  Timer? _saveTimer;
  Timer? _ticker;

  Future<void> load() async {
    final data = await dataSource.load();
    if (data == null) {
      seedDemoData(this);
      await persist();
    } else {
      _fromJson(data);
    }
    loaded = true;
    // Recalcula previsões e barras de progresso a cada minuto.
    _ticker ??= Timer.periodic(const Duration(minutes: 1), (_) => notifyListeners());
    notifyListeners();
  }

  /// Restaura a base de demonstração (apenas gerente, via tela de perfil).
  Future<void> resetDemoData() async {
    _clear();
    seedDemoData(this);
    await persist();
    notifyListeners();
  }

  void commit() {
    notifyListeners();
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 250), persist);
  }

  Future<void> persist() => dataSource.save(toJson());

  @override
  void dispose() {
    _saveTimer?.cancel();
    _ticker?.cancel();
    super.dispose();
  }

  void _clear() {
    users.clear();
    pets.clear();
    services.clear();
    appointments.clear();
    payments.clear();
    reviews.clear();
    notifications.clear();
    clinicalEntries.clear();
    hours = BusinessHours();
  }

  Map<String, dynamic> toJson() => {
        'schema': 1,
        'users': users.map((e) => e.toJson()).toList(),
        'pets': pets.map((e) => e.toJson()).toList(),
        'services': services.map((e) => e.toJson()).toList(),
        'appointments': appointments.map((e) => e.toJson()).toList(),
        'payments': payments.map((e) => e.toJson()).toList(),
        'reviews': reviews.map((e) => e.toJson()).toList(),
        'notifications': notifications.map((e) => e.toJson()).toList(),
        'clinicalEntries': clinicalEntries.map((e) => e.toJson()).toList(),
        'hours': hours.toJson(),
      };

  void _fromJson(Map<String, dynamic> j) {
    _clear();
    List<Map<String, dynamic>> list(String key) => ((j[key] ?? []) as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    users.addAll(list('users').map(UserModel.fromJson));
    pets.addAll(list('pets').map(Pet.fromJson));
    services.addAll(list('services').map(ServiceModel.fromJson));
    appointments.addAll(list('appointments').map(Appointment.fromJson));
    payments.addAll(list('payments').map(Payment.fromJson));
    reviews.addAll(list('reviews').map(Review.fromJson));
    notifications.addAll(list('notifications').map(AppNotification.fromJson));
    clinicalEntries.addAll(list('clinicalEntries').map(ClinicalEntry.fromJson));
    if (j['hours'] != null) {
      hours = BusinessHours.fromJson(Map<String, dynamic>.from(j['hours'] as Map));
    }
  }

  // ------------------------------------------------------------------ lookups

  UserModel? userById(String? id) {
    if (id == null) return null;
    for (final u in users) {
      if (u.id == id) return u;
    }
    return null;
  }

  Pet? petById(String? id) {
    if (id == null) return null;
    for (final p in pets) {
      if (p.id == id) return p;
    }
    return null;
  }

  ServiceModel? serviceById(String? id) {
    if (id == null) return null;
    for (final s in services) {
      if (s.id == id) return s;
    }
    return null;
  }

  Appointment? appointmentById(String? id) {
    if (id == null) return null;
    for (final a in appointments) {
      if (a.id == id) return a;
    }
    return null;
  }

  Appointment requireAppointment(String id) {
    final a = appointmentById(id);
    if (a == null) throw BusinessException('Agendamento não encontrado.');
    return a;
  }

  List<UserModel> get managers => users.where((u) => u.isGerente && u.ativo).toList();

  // ------------------------------------------------------------ permissões

  void ensure(bool condition, [String? message]) {
    if (!condition) {
      throw PermissionDenied(message ?? 'Você não tem permissão para esta ação.');
    }
  }

  void ensureActive(UserModel actor) {
    if (!actor.ativo) throw PermissionDenied('Usuário desativado.');
  }

  // ------------------------------------------------------------ notificações

  void pushNotification(String userId, String titulo, String mensagem, {String? agendamentoId}) {
    final n = AppNotification(
      id: newId(),
      userId: userId,
      titulo: titulo,
      mensagem: mensagem,
      data: DateTime.now(),
      agendamentoId: agendamentoId,
    );
    notifications.add(n);
    if (pushGateway.isConfigured) {
      pushGateway.send(n).catchError((Object e) {
        debugPrint('Falha ao enviar push: $e');
      });
    }
  }

  void notifyManagers(String titulo, String mensagem, {String? agendamentoId, String? exceptId}) {
    for (final m in managers) {
      if (m.id == exceptId) continue;
      pushNotification(m.id, titulo, mensagem, agendamentoId: agendamentoId);
    }
  }
}
