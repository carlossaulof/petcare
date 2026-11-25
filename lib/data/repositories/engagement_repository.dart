import '../../core/ids.dart';
import '../models/models.dart';
import '../store_base.dart';

/// Avaliações, notificações e ficha clínica.
mixin EngagementRepository on StoreBase {
  // ------------------------------------------------------------ avaliações

  Review? reviewFor(String agendamentoId) {
    for (final r in reviews) {
      if (r.agendamentoId == agendamentoId) return r;
    }
    return null;
  }

  void addReview(UserModel actor, String agendamentoId, int nota, String comentario) {
    final a = requireAppointment(agendamentoId);
    ensure(actor.id == a.clienteId, 'Somente o tutor pode avaliar.');
    if (a.status != AppointmentStatus.concluido) {
      throw BusinessException('A avaliação fica disponível após a conclusão do atendimento.');
    }
    if (reviewFor(agendamentoId) != null) throw BusinessException('Este atendimento já foi avaliado.');
    if (nota < 1 || nota > 5) throw BusinessException('Escolha de 1 a 5 estrelas.');
    reviews.add(Review(
      id: newId(),
      agendamentoId: a.id,
      clienteId: actor.id,
      funcionarioId: a.funcionarioId,
      servicoId: a.servicoId,
      nota: nota,
      comentario: comentario.trim(),
      data: DateTime.now(),
    ));
    final txt = '$nota★ para ${a.servicoNome}${comentario.trim().isEmpty ? '' : ': "${comentario.trim()}"'}';
    if (a.funcionarioId != null) {
      pushNotification(a.funcionarioId!, 'Nova avaliação', txt, agendamentoId: a.id);
    }
    notifyManagers('Nova avaliação de ${actor.nome}', txt, agendamentoId: a.id);
    commit();
  }

  double? averageRating({String? funcionarioId, DateTime? since}) {
    final list = reviews.where((r) =>
        (funcionarioId == null || r.funcionarioId == funcionarioId) &&
        (since == null || !r.data.isBefore(since)));
    if (list.isEmpty) return null;
    return list.fold<int>(0, (s, r) => s + r.nota) / list.length;
  }

  // ---------------------------------------------------------- notificações

  List<AppNotification> notificationsOf(String userId) =>
      notifications.where((n) => n.userId == userId).toList()..sort((a, b) => b.data.compareTo(a.data));

  int unreadCount(String userId) => notifications.where((n) => n.userId == userId && !n.lida).length;

  void markRead(String notificationId) {
    for (final n in notifications) {
      if (n.id == notificationId && !n.lida) {
        n.lida = true;
        commit();
        return;
      }
    }
  }

  void markAllRead(String userId) {
    var changed = false;
    for (final n in notifications) {
      if (n.userId == userId && !n.lida) {
        n.lida = true;
        changed = true;
      }
    }
    if (changed) commit();
  }

  // ---------------------------------------------------------- ficha clínica

  List<ClinicalEntry> clinicalOf(String petId) =>
      clinicalEntries.where((c) => c.petId == petId).toList()..sort((a, b) => b.data.compareTo(a.data));

  /// O tutor vê diagnóstico e prescrição do próprio pet; a área completa é
  /// restrita a veterinários e gerentes.
  bool canViewClinical(UserModel actor, Pet pet) => actor.canAccessVetArea || actor.id == pet.tutorId;

  void addClinicalEntry(UserModel actor, ClinicalEntry entry) {
    ensureActive(actor);
    ensure(actor.canAccessVetArea, 'Área restrita a veterinários.');
    final pet = petById(entry.petId);
    if (pet == null) throw BusinessException('Pet não encontrado.');
    if (entry.diagnostico.trim().isEmpty) throw BusinessException('Informe o diagnóstico.');
    clinicalEntries.add(entry);
    if (entry.peso != null && entry.peso! > 0) pet.peso = entry.peso!;
    pushNotification(pet.tutorId, 'Ficha clínica de ${pet.nome} atualizada',
        'Diagnóstico e orientações disponíveis em Meus Pets.', agendamentoId: entry.agendamentoId);
    commit();
  }
}
