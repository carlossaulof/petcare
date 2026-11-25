import '../../core/formatters.dart';
import '../../core/ids.dart';
import '../models/models.dart';
import '../store_base.dart';

mixin AppointmentRepository on StoreBase {
  // ------------------------------------------------------------ consultas

  List<Appointment> _sorted(Iterable<Appointment> it, {bool desc = false}) {
    final l = it.toList()..sort((a, b) => a.inicio.compareTo(b.inicio));
    return desc ? l.reversed.toList() : l;
  }

  List<Appointment> appointmentsOfClient(String clienteId) =>
      _sorted(appointments.where((a) => a.clienteId == clienteId));

  List<Appointment> openAppointmentsOfClient(String clienteId) =>
      _sorted(appointments.where((a) => a.clienteId == clienteId && a.status.isOpen));

  List<Appointment> historyOfClient(String clienteId) => _sorted(
      appointments.where((a) => a.clienteId == clienteId && !a.status.isOpen),
      desc: true);

  List<Appointment> appointmentsOfStaff(String staffId) =>
      _sorted(appointments.where((a) => a.funcionarioId == staffId));

  List<Appointment> appointmentsOnDay(DateTime day) =>
      _sorted(appointments.where((a) => isSameDay(a.inicio, day)));

  List<Appointment> petHistory(String petId) =>
      _sorted(appointments.where((a) => a.petId == petId), desc: true);

  List<Appointment> get inProgress =>
      _sorted(appointments.where((a) => a.status == AppointmentStatus.emAndamento));

  // ---------------------------------------------------------- disponibilidade

  List<UserModel> qualifiedStaff(ServiceCategory categoria) => users
      .where((u) => u.isFuncionario && u.ativo && u.especialidade == categoria.specialty)
      .toList();

  bool _isStaffFree(String staffId, DateTime start, int minutes, {String? ignoreId}) {
    return !appointments.any((a) =>
        a.id != ignoreId &&
        a.funcionarioId == staffId &&
        a.status.isOpen &&
        a.overlaps(start, minutes));
  }

  List<UserModel> freeStaffFor(DateTime start, int minutes, ServiceCategory categoria, {String? ignoreId}) =>
      qualifiedStaff(categoria)
          .where((s) => _isStaffFree(s.id, start, minutes, ignoreId: ignoreId))
          .toList();

  bool petIsBusy(String petId, DateTime start, int minutes, {String? ignoreId}) => appointments.any((a) =>
      a.id != ignoreId && a.petId == petId && a.status.isOpen && a.overlaps(start, minutes));

  /// Horários livres do dia para o serviço: dentro do expediente, no futuro e
  /// com pelo menos um profissional qualificado sem conflito.
  List<DateTime> availableSlots(DateTime day, ServiceModel service, {String? petId, String? ignoreId}) {
    if (!hours.diasFuncionamento.contains(day.weekday)) return [];
    final result = <DateTime>[];
    final minStart = DateTime.now().add(const Duration(minutes: 30));
    for (var m = hours.aberturaMin; m + service.duracaoMin <= hours.fechamentoMin; m += hours.intervaloMin) {
      final start = DateTime(day.year, day.month, day.day, m ~/ 60, m % 60);
      if (start.isBefore(minStart)) continue;
      if (petId != null && petIsBusy(petId, start, service.duracaoMin, ignoreId: ignoreId)) continue;
      if (freeStaffFor(start, service.duracaoMin, service.categoria, ignoreId: ignoreId).isNotEmpty) {
        result.add(start);
      }
    }
    return result;
  }

  UserModel? _pickStaff(DateTime start, int minutes, ServiceCategory categoria, {String? ignoreId}) {
    final free = freeStaffFor(start, minutes, categoria, ignoreId: ignoreId);
    if (free.isEmpty) return null;
    int load(UserModel s) => appointments
        .where((a) => a.funcionarioId == s.id && a.status.isOpen && isSameDay(a.inicio, start))
        .length;
    free.sort((a, b) => load(a).compareTo(load(b)));
    return free.first;
  }

  void _log(Appointment a, String descricao, UserModel? autor) {
    a.eventos.add(AppointmentEvent(data: DateTime.now(), descricao: descricao, autorNome: autor?.nome ?? 'Sistema'));
  }

  String _label(Appointment a) => '${petById(a.petId)?.nome ?? 'Pet'} · ${a.servicoNome}';

  void _ensureCanOperate(UserModel actor, Appointment a) {
    ensureActive(actor);
    ensure(actor.isGerente || (actor.isFuncionario && a.funcionarioId == actor.id),
        'Este atendimento não está atribuído a você.');
  }

  // ------------------------------------------------------------- agendar

  Appointment book(
    UserModel actor, {
    required String petId,
    required String servicoId,
    required DateTime inicio,
    String observacao = '',
  }) {
    ensureActive(actor);
    final pet = petById(petId);
    final service = serviceById(servicoId);
    if (pet == null || !pet.ativo) throw BusinessException('Selecione um pet válido.');
    if (service == null || !service.ativo) throw BusinessException('Serviço indisponível.');
    ensure(actor.isGerente || actor.id == pet.tutorId, 'Você só pode agendar para os seus pets.');
    if (inicio.isBefore(DateTime.now())) throw BusinessException('Escolha um horário futuro.');
    if (petIsBusy(petId, inicio, service.duracaoMin)) {
      throw BusinessException('${pet.nome} já tem um atendimento neste horário.');
    }
    final staff = _pickStaff(inicio, service.duracaoMin, service.categoria);
    if (staff == null) {
      throw BusinessException('Este horário acabou de ser ocupado. Escolha outro horário.');
    }
    final a = Appointment(
      id: newId(),
      clienteId: pet.tutorId,
      petId: pet.id,
      servicoId: service.id,
      servicoNome: service.nome,
      categoria: service.categoria,
      funcionarioId: staff.id,
      inicio: inicio,
      duracaoMin: service.duracaoMin,
      preco: service.preco,
      observacaoCliente: observacao.trim(),
      etapas: service.etapas.map((e) => ProcedureStep(nome: e)).toList(),
      criadoEm: DateTime.now(),
    );
    _log(a, 'Agendamento criado para ${formatDateTime(inicio)}', actor);
    appointments.add(a);
    final quando = '${formatDate(inicio)} às ${formatTime(inicio)}';
    pushNotification(pet.tutorId, 'Agendamento confirmado',
        '${service.nome} de ${pet.nome} em $quando com ${staff.nome}.',
        agendamentoId: a.id);
    pushNotification(staff.id, 'Novo atendimento atribuído', '${_label(a)} em $quando.', agendamentoId: a.id);
    notifyManagers('Novo agendamento', '${_label(a)} em $quando.', agendamentoId: a.id, exceptId: actor.id);
    commit();
    return a;
  }

  bool clientCanChange(Appointment a) =>
      a.status == AppointmentStatus.agendado &&
      a.inicio.difference(DateTime.now()).inMinutes >= hours.antecedenciaCancelamentoHoras * 60;

  void cancel(UserModel actor, String id, String motivo) {
    final a = requireAppointment(id);
    ensureActive(actor);
    if (!a.status.isOpen) throw BusinessException('Este agendamento já foi encerrado.');
    if (actor.isCliente) {
      ensure(a.clienteId == actor.id);
      if (!clientCanChange(a)) {
        throw BusinessException('Cancelamentos pelo app só até ${hours.antecedenciaCancelamentoHoras}h '
            'antes e antes do início. Fale com o petshop.');
      }
    } else {
      ensure(actor.isGerente, 'Somente o gerente pode cancelar atendimentos.');
    }
    a.status = AppointmentStatus.cancelado;
    a.motivoCancelamento = motivo.trim().isEmpty ? 'Sem motivo informado' : motivo.trim();
    _log(a, 'Cancelado: ${a.motivoCancelamento}', actor);
    final msg = '${_label(a)} de ${formatDateTime(a.inicio)} foi cancelado.';
    if (actor.id != a.clienteId) pushNotification(a.clienteId, 'Agendamento cancelado', msg, agendamentoId: a.id);
    if (a.funcionarioId != null) pushNotification(a.funcionarioId!, 'Atendimento cancelado', msg, agendamentoId: a.id);
    notifyManagers('Cancelamento', '$msg Motivo: ${a.motivoCancelamento}', agendamentoId: a.id, exceptId: actor.id);
    commit();
  }

  void reschedule(UserModel actor, String id, DateTime novoInicio) {
    final a = requireAppointment(id);
    ensureActive(actor);
    if (a.status != AppointmentStatus.agendado) {
      throw BusinessException('Só é possível reagendar atendimentos que ainda não começaram.');
    }
    if (actor.isCliente) {
      ensure(a.clienteId == actor.id);
      if (!clientCanChange(a)) {
        throw BusinessException('Reagendamentos pelo app só até ${hours.antecedenciaCancelamentoHoras}h antes.');
      }
    } else {
      ensure(actor.isGerente, 'Somente o gerente pode reagendar atendimentos.');
    }
    if (novoInicio.isBefore(DateTime.now())) throw BusinessException('Escolha um horário futuro.');
    if (petIsBusy(a.petId, novoInicio, a.duracaoTotalMin, ignoreId: a.id)) {
      throw BusinessException('O pet já tem outro atendimento neste horário.');
    }
    final anterior = a.funcionarioId;
    String? staffId;
    if (anterior != null && _isStaffFree(anterior, novoInicio, a.duracaoTotalMin, ignoreId: a.id)) {
      staffId = anterior;
    } else {
      staffId = _pickStaff(novoInicio, a.duracaoTotalMin, a.categoria, ignoreId: a.id)?.id;
    }
    if (staffId == null) throw BusinessException('Nenhum profissional livre neste horário.');
    final antigo = a.inicio;
    a.inicio = novoInicio;
    a.funcionarioId = staffId;
    a.reagendamentos++;
    _log(a, 'Reagendado de ${formatDateTime(antigo)} para ${formatDateTime(novoInicio)}', actor);
    final msg = '${_label(a)} passou para ${formatDate(novoInicio)} às ${formatTime(novoInicio)}.';
    if (actor.id != a.clienteId) pushNotification(a.clienteId, 'Agendamento reagendado', msg, agendamentoId: a.id);
    pushNotification(staffId, 'Atendimento reagendado', msg, agendamentoId: a.id);
    if (anterior != null && anterior != staffId) {
      pushNotification(anterior, 'Atendimento reatribuído', '${_label(a)} foi passado para outro profissional.',
          agendamentoId: a.id);
    }
    notifyManagers('Reagendamento', msg, agendamentoId: a.id, exceptId: actor.id);
    commit();
  }

  void assignStaff(UserModel actor, String id, String staffId) {
    ensure(actor.isGerente, 'Somente o gerente atribui funcionários.');
    final a = requireAppointment(id);
    if (!a.status.isOpen) throw BusinessException('Este atendimento já foi encerrado.');
    final staff = userById(staffId);
    if (staff == null || !staff.isFuncionario || !staff.ativo) throw BusinessException('Funcionário inválido.');
    if (staff.especialidade != a.categoria.specialty) {
      throw BusinessException('${staff.nome} não atende serviços de ${a.categoria.label}.');
    }
    if (!_isStaffFree(staffId, a.inicio, a.duracaoTotalMin, ignoreId: a.id)) {
      throw BusinessException('${staff.nome} já tem atendimento neste horário.');
    }
    final anterior = a.funcionarioId;
    a.funcionarioId = staffId;
    _log(a, 'Atribuído a ${staff.nome}', actor);
    pushNotification(staffId, 'Novo atendimento atribuído',
        '${_label(a)} em ${formatDateTime(a.inicio)}.', agendamentoId: a.id);
    if (anterior != null && anterior != staffId) {
      pushNotification(anterior, 'Atendimento reatribuído', '${_label(a)} foi passado para ${staff.nome}.',
          agendamentoId: a.id);
    }
    pushNotification(a.clienteId, 'Profissional definido', '${staff.nome} cuidará de ${_label(a)}.',
        agendamentoId: a.id);
    commit();
  }

  // ------------------------------------------------------ procedimentos

  void _startIfNeeded(UserModel actor, Appointment a) {
    if (a.status == AppointmentStatus.agendado) {
      a.status = AppointmentStatus.emAndamento;
      a.iniciadoEm = DateTime.now();
      _log(a, 'Atendimento iniciado', actor);
      pushNotification(a.clienteId, 'Atendimento iniciado',
          '${_label(a)} começou. Acompanhe as etapas em tempo real.', agendamentoId: a.id);
    }
  }

  void startStep(UserModel actor, String id, int index) {
    final a = requireAppointment(id);
    _ensureCanOperate(actor, a);
    if (!a.status.isOpen) throw BusinessException('Atendimento encerrado.');
    final step = a.etapas[index];
    if (step.status != StepStatus.pendente) throw BusinessException('Esta etapa já foi iniciada.');
    if (a.etapas.any((e) => e.status == StepStatus.emAndamento)) {
      throw BusinessException('Conclua a etapa em andamento antes de iniciar outra.');
    }
    _startIfNeeded(actor, a);
    step.status = StepStatus.emAndamento;
    step.inicio = DateTime.now();
    step.responsavelId = actor.id;
    step.responsavelNome = actor.nome;
    _log(a, 'Etapa "${step.nome}" iniciada', actor);
    final pet = petById(a.petId)?.nome ?? 'Seu pet';
    pushNotification(a.clienteId, '$pet: ${step.nome.toLowerCase()}',
        'Etapa iniciada às ${formatTime(step.inicio!)}. Previsão de conclusão: ${formatTime(a.previsaoConclusao)}.',
        agendamentoId: a.id);
    commit();
  }

  /// Conclui a etapa. Se [startNext] for verdadeiro, inicia a próxima pendente.
  void completeStep(UserModel actor, String id, int index, {bool startNext = true}) {
    final a = requireAppointment(id);
    _ensureCanOperate(actor, a);
    final step = a.etapas[index];
    if (step.status == StepStatus.concluido) return;
    _startIfNeeded(actor, a);
    step.inicio ??= DateTime.now();
    step.status = StepStatus.concluido;
    step.fim = DateTime.now();
    step.responsavelId ??= actor.id;
    step.responsavelNome ??= actor.nome;
    _log(a, 'Etapa "${step.nome}" concluída', actor);
    if (startNext) {
      for (final next in a.etapas) {
        if (next.status == StepStatus.pendente) {
          next.status = StepStatus.emAndamento;
          next.inicio = DateTime.now();
          next.responsavelId = actor.id;
          next.responsavelNome = actor.nome;
          _log(a, 'Etapa "${next.nome}" iniciada', actor);
          final pet = petById(a.petId)?.nome ?? 'Seu pet';
          pushNotification(a.clienteId, '$pet: ${next.nome.toLowerCase()}',
              'Previsão de conclusão às ${formatTime(a.previsaoConclusao)}.',
              agendamentoId: a.id);
          break;
        }
      }
    }
    commit();
  }

  void finishAppointment(UserModel actor, String id) {
    final a = requireAppointment(id);
    _ensureCanOperate(actor, a);
    if (!a.status.isOpen) throw BusinessException('Atendimento já encerrado.');
    if (a.temAdicionalPendente) {
      throw BusinessException('Há serviço adicional aguardando resposta do cliente.');
    }
    final now = DateTime.now();
    _startIfNeeded(actor, a);
    for (final e in a.etapas) {
      if (e.status != StepStatus.concluido) {
        e.inicio ??= now;
        e.fim = now;
        e.status = StepStatus.concluido;
        e.responsavelId ??= actor.id;
        e.responsavelNome ??= actor.nome;
      }
    }
    a.status = AppointmentStatus.concluido;
    a.concluidoEm = now;
    a.previsaoManual = null;
    _log(a, 'Atendimento concluído', actor);
    final exists = payments.any((p) => p.agendamentoId == a.id && p.status != PaymentStatus.estornado);
    if (!exists) {
      payments.add(Payment(
        id: newId(),
        agendamentoId: a.id,
        clienteId: a.clienteId,
        valor: a.valorTotal,
        criadoEm: now,
      ));
    }
    final pet = petById(a.petId)?.nome ?? 'Seu pet';
    pushNotification(a.clienteId, '$pet está pronto!',
        '${a.servicoNome} concluído às ${formatTime(now)}. Total: ${formatMoney(a.valorTotal)}. '
        'Conte como foi avaliando o atendimento.',
        agendamentoId: a.id);
    notifyManagers('Atendimento concluído', '${_label(a)} — ${formatMoney(a.valorTotal)}',
        agendamentoId: a.id, exceptId: actor.id);
    commit();
  }

  void setForecast(UserModel actor, String id, DateTime? previsao) {
    final a = requireAppointment(id);
    _ensureCanOperate(actor, a);
    a.previsaoManual = previsao;
    if (previsao != null) {
      _log(a, 'Previsão ajustada para ${formatTime(previsao)}', actor);
      pushNotification(a.clienteId, 'Nova previsão de conclusão',
          '${_label(a)}: previsão de retirada às ${formatTime(previsao)}.',
          agendamentoId: a.id);
    }
    commit();
  }

  void addNote(UserModel actor, String id, NoteType tipo, String texto) {
    final a = requireAppointment(id);
    _ensureCanOperate(actor, a);
    if (texto.trim().isEmpty) throw BusinessException('Escreva o texto da anotação.');
    a.notas.add(AppointmentNote(
      id: newId(),
      tipo: tipo,
      texto: texto.trim(),
      autorId: actor.id,
      autorNome: actor.nome,
      data: DateTime.now(),
    ));
    _log(a, '${tipo.label} registrada', actor);
    if (tipo == NoteType.ocorrencia) {
      pushNotification(a.clienteId, 'Ocorrência no atendimento', '${_label(a)}: ${texto.trim()}',
          agendamentoId: a.id);
      notifyManagers('Ocorrência registrada', '${_label(a)}: ${texto.trim()}', agendamentoId: a.id,
          exceptId: actor.id);
    } else {
      pushNotification(a.clienteId, 'Nova observação da equipe', '${_label(a)}: ${texto.trim()}',
          agendamentoId: a.id);
    }
    commit();
  }

  void requestAdditional(UserModel actor, String id, String servicoId, String justificativa) {
    final a = requireAppointment(id);
    _ensureCanOperate(actor, a);
    if (!a.status.isOpen) throw BusinessException('Atendimento encerrado.');
    final s = serviceById(servicoId);
    if (s == null || !s.ativo) throw BusinessException('Serviço inválido.');
    if (justificativa.trim().isEmpty) throw BusinessException('Explique ao cliente o motivo do adicional.');
    a.adicionais.add(AdditionalRequest(
      id: newId(),
      servicoId: s.id,
      nome: s.nome,
      preco: s.preco,
      duracaoMin: s.duracaoMin,
      justificativa: justificativa.trim(),
      solicitadoPorId: actor.id,
      solicitadoPorNome: actor.nome,
      solicitadoEm: DateTime.now(),
    ));
    _log(a, 'Adicional "${s.nome}" solicitado (${formatMoney(s.preco)})', actor);
    pushNotification(a.clienteId, 'Autorização necessária',
        '${actor.nome} sugere "${s.nome}" por ${formatMoney(s.preco)} para ${petById(a.petId)?.nome ?? 'seu pet'}. '
        'Toque para aprovar ou recusar.',
        agendamentoId: a.id);
    commit();
  }

  void respondAdditional(UserModel actor, String id, String additionalId, bool aprovado) {
    final a = requireAppointment(id);
    ensure(actor.id == a.clienteId, 'Somente o tutor pode autorizar serviços adicionais.');
    final add = a.adicionais.firstWhere((x) => x.id == additionalId,
        orElse: () => throw BusinessException('Solicitação não encontrada.'));
    if (add.status != AdditionalStatus.pendente) throw BusinessException('Solicitação já respondida.');
    if (!a.status.isOpen) throw BusinessException('Atendimento encerrado.');
    add.status = aprovado ? AdditionalStatus.aprovado : AdditionalStatus.recusado;
    add.respondidoEm = DateTime.now();
    if (aprovado) {
      a.etapas.add(ProcedureStep(nome: add.nome));
    }
    _log(a, 'Adicional "${add.nome}" ${aprovado ? 'aprovado' : 'recusado'} pelo tutor', actor);
    pushNotification(add.solicitadoPorId, 'Adicional ${aprovado ? 'aprovado' : 'recusado'}',
        '${actor.nome} ${aprovado ? 'aprovou' : 'recusou'} "${add.nome}" para ${_label(a)}.',
        agendamentoId: a.id);
    commit();
  }
}
