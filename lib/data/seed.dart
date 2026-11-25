import '../core/formatters.dart';
import '../core/ids.dart';
import 'models/models.dart';
import 'store_base.dart';

/// Contas de demonstração exibidas na tela de login.
class DemoAccount {
  final String label;
  final String email;
  final String senha;
  const DemoAccount(this.label, this.email, this.senha);
}

const demoAccounts = [
  DemoAccount('Cliente', 'cliente@petcare.app', 'cliente123'),
  DemoAccount('Funcionário (banho e tosa)', 'func@petcare.app', 'func123'),
  DemoAccount('Veterinária', 'vet@petcare.app', 'vet123'),
  DemoAccount('Gerente', 'gerente@petcare.app', 'gerente123'),
];

/// Popula a base local na primeira execução com dados coerentes para que
/// todos os fluxos possam ser testados. Datas são relativas a "hoje".
void seedDemoData(StoreBase s) {
  final now = DateTime.now();
  final today = dateOnly(now);

  UserModel user(String nome, String email, String tel, String senha, UserRole role,
      [StaffSpecialty? esp]) {
    final salt = newSalt();
    final u = UserModel(
      id: newId(),
      nome: nome,
      email: email,
      telefone: tel,
      role: role,
      especialidade: esp,
      senhaHash: hashPassword(senha, salt),
      salt: salt,
      criadoEm: today.subtract(const Duration(days: 60)),
    );
    s.users.add(u);
    return u;
  }

  final gerente = user('Marina Costa', 'gerente@petcare.app', '(86) 99999-0001', 'gerente123', UserRole.gerente);
  final carlos = user('Carlos Lima', 'func@petcare.app', '(86) 99999-0002', 'func123', UserRole.funcionario,
      StaffSpecialty.banhoTosa);
  final bruna = user('Bruna Rocha', 'bruna@petcare.app', '(86) 99999-0005', 'bruna123', UserRole.funcionario,
      StaffSpecialty.banhoTosa);
  final helena = user('Dra. Helena Martins', 'vet@petcare.app', '(86) 99999-0003', 'vet123',
      UserRole.funcionario, StaffSpecialty.veterinario);
  final ana = user('Ana Souza', 'cliente@petcare.app', '(86) 98888-1111', 'cliente123', UserRole.cliente);
  final diego = user('Diego Alves', 'diego@petcare.app', '(86) 98888-2222', 'diego123', UserRole.cliente);

  // ------------------------------------------------------------- serviços
  ServiceModel svc(String nome, String desc, ServiceCategory cat, double preco, int dur, List<String> etapas) {
    final x = ServiceModel(
        id: newId(), nome: nome, descricao: desc, categoria: cat, preco: preco, duracaoMin: dur, etapas: etapas);
    s.services.add(x);
    return x;
  }

  final banho = svc('Banho completo', 'Banho com shampoo neutro, secagem, escovação e perfume.',
      ServiceCategory.banho, 89, 90, ['Recepção', 'Banho', 'Secagem', 'Escovação', 'Finalização']);
  final tosaHig = svc('Tosa higiênica', 'Limpeza de patas, barriga e região íntima.', ServiceCategory.tosa, 120, 120,
      ['Recepção', 'Banho', 'Tosa', 'Secagem', 'Finalização']);
  svc('Tosa completa', 'Banho + tosa na tesoura ou máquina conforme a raça.', ServiceCategory.tosa, 150, 150,
      ['Recepção', 'Banho', 'Tosa', 'Secagem', 'Acabamento']);
  final consulta = svc('Consulta veterinária', 'Avaliação clínica completa com a veterinária.',
      ServiceCategory.veterinario, 180, 40, ['Triagem', 'Consulta', 'Orientações']);
  svc('Vacinação', 'Aplicação de vacina com avaliação prévia.', ServiceCategory.veterinario, 120, 20,
      ['Triagem', 'Aplicação']);
  final hidrat = svc('Hidratação de pelagem', 'Máscara hidratante para pelos ressecados.', ServiceCategory.outro, 45,
      30, ['Aplicação', 'Enxágue']);
  svc('Corte de unhas', 'Corte e lixamento das unhas.', ServiceCategory.outro, 25, 15, ['Corte']);

  // ----------------------------------------------------------------- pets
  Pet pet(UserModel tutor, String nome, Species sp, String raca, PetSex sexo, PetSize porte, int idadeAnos,
      double peso,
      {String alergias = '', List<Vaccine>? vacinas, bool castrado = false}) {
    final p = Pet(
      id: newId(),
      tutorId: tutor.id,
      nome: nome,
      especie: sp,
      raca: raca,
      sexo: sexo,
      porte: porte,
      nascimento: DateTime(today.year - idadeAnos, today.month, 1),
      peso: peso,
      castrado: castrado,
      alergias: alergias,
      vacinas: vacinas,
      criadoEm: today.subtract(const Duration(days: 50)),
    );
    s.pets.add(p);
    return p;
  }

  final thor = pet(ana, 'Thor', Species.cachorro, 'Golden Retriever', PetSex.macho, PetSize.grande, 5, 28.5,
      vacinas: [
        Vaccine(nome: 'V10', data: today.subtract(const Duration(days: 200)),
            proxima: today.add(const Duration(days: 165))),
        Vaccine(nome: 'Antirrábica', data: today.subtract(const Duration(days: 120)),
            proxima: today.add(const Duration(days: 245))),
      ],
      castrado: true);
  final luna = pet(ana, 'Luna', Species.gato, 'Siamês', PetSex.femea, PetSize.pequeno, 4, 4.2,
      alergias: 'Frango', castrado: true);
  final bob = pet(ana, 'Bob', Species.cachorro, 'Pinscher', PetSex.macho, PetSize.pequeno, 3, 3.1);
  final mel = pet(diego, 'Mel', Species.cachorro, 'Shih Tzu', PetSex.femea, PetSize.pequeno, 2, 5.4);

  // --------------------------------------------------------- agendamentos
  Appointment appt(Pet p, ServiceModel sv, UserModel staff, DateTime inicio, AppointmentStatus st) {
    final a = Appointment(
      id: newId(),
      clienteId: p.tutorId,
      petId: p.id,
      servicoId: sv.id,
      servicoNome: sv.nome,
      categoria: sv.categoria,
      funcionarioId: staff.id,
      inicio: inicio,
      duracaoMin: sv.duracaoMin,
      preco: sv.preco,
      status: st,
      etapas: sv.etapas.map((e) => ProcedureStep(nome: e)).toList(),
      criadoEm: inicio.subtract(const Duration(days: 2)),
    );
    a.eventos.add(AppointmentEvent(
        data: a.criadoEm, descricao: 'Agendamento criado para ${formatDateTime(inicio)}', autorNome: 'Sistema'));
    s.appointments.add(a);
    return a;
  }

  void completeAll(Appointment a, UserModel staff) {
    var t = a.inicio;
    final per = a.duracaoMin ~/ a.etapas.length;
    for (final e in a.etapas) {
      e.status = StepStatus.concluido;
      e.inicio = t;
      t = t.add(Duration(minutes: per));
      e.fim = t;
      e.responsavelId = staff.id;
      e.responsavelNome = staff.nome;
    }
    a.iniciadoEm = a.inicio;
    a.concluidoEm = t;
  }

  // Histórico: atendimentos concluídos nos últimos dias (alimentam gráficos).
  final history = <(Pet, ServiceModel, UserModel, int, int, int, PaymentMethod)>[
    (thor, banho, carlos, 1, 9, 5, PaymentMethod.pix),
    (mel, tosaHig, bruna, 2, 14, 5, PaymentMethod.cartaoCredito),
    (luna, consulta, helena, 3, 10, 5, PaymentMethod.pix),
    (bob, banho, bruna, 4, 11, 4, PaymentMethod.dinheiro),
    (mel, banho, carlos, 5, 15, 5, PaymentMethod.cartaoDebito),
    (thor, hidrat, carlos, 6, 16, 4, PaymentMethod.pix),
  ];
  for (final h in history) {
    final day = today.subtract(Duration(days: h.$4));
    final a = appt(h.$1, h.$2, h.$3, DateTime(day.year, day.month, day.day, h.$5), AppointmentStatus.concluido);
    completeAll(a, h.$3);
    a.eventos.add(AppointmentEvent(data: a.concluidoEm!, descricao: 'Atendimento concluído', autorNome: h.$3.nome));
    s.payments.add(Payment(
      id: newId(),
      agendamentoId: a.id,
      clienteId: a.clienteId,
      valor: a.valorTotal,
      metodo: h.$7,
      status: PaymentStatus.pago,
      criadoEm: a.concluidoEm!,
      pagoEm: a.concluidoEm!.add(const Duration(minutes: 10)),
      confirmadoPorId: gerente.id,
    ));
    s.reviews.add(Review(
      id: newId(),
      agendamentoId: a.id,
      clienteId: a.clienteId,
      funcionarioId: h.$3.id,
      servicoId: h.$2.id,
      nota: h.$6,
      comentario: h.$6 == 5 ? 'Atendimento excelente!' : 'Gostei, mas atrasou um pouco.',
      data: a.concluidoEm!.add(const Duration(hours: 2)),
    ));
  }
  s.clinicalEntries.add(ClinicalEntry(
    id: newId(),
    petId: luna.id,
    veterinarioId: helena.id,
    veterinarioNome: helena.nome,
    data: today.subtract(const Duration(days: 3)).add(const Duration(hours: 10)),
    queixa: 'Vômitos ocasionais',
    anamnese: 'Apetite normal, sem alterações de comportamento. Alergia a frango informada pela tutora.',
    diagnostico: 'Gastrite leve',
    prescricao: 'Ração hipoalergênica por 30 dias. Omeprazol 1 mg/kg, 1x ao dia, por 7 dias.',
    peso: 4.2,
    temperatura: 38.6,
    retorno: today.add(const Duration(days: 1)),
  ));

  // Hoje: um atendimento em andamento, outro em andamento e um agendado amanhã.
  final inicioThor = now.subtract(const Duration(minutes: 40));
  final aThor = appt(thor, banho, carlos, inicioThor, AppointmentStatus.emAndamento);
  aThor.iniciadoEm = inicioThor;
  final steps = aThor.etapas;
  steps[0]
    ..status = StepStatus.concluido
    ..inicio = inicioThor
    ..fim = inicioThor.add(const Duration(minutes: 10))
    ..responsavelId = carlos.id
    ..responsavelNome = carlos.nome;
  steps[1]
    ..status = StepStatus.concluido
    ..inicio = inicioThor.add(const Duration(minutes: 10))
    ..fim = inicioThor.add(const Duration(minutes: 35))
    ..responsavelId = carlos.id
    ..responsavelNome = carlos.nome;
  steps[2]
    ..status = StepStatus.emAndamento
    ..inicio = inicioThor.add(const Duration(minutes: 35))
    ..responsavelId = carlos.id
    ..responsavelNome = carlos.nome;
  aThor.notas.add(AppointmentNote(
    id: newId(),
    tipo: NoteType.observacao,
    texto: 'Thor está calmo e colaborativo. Pelagem com alguns nós na região das orelhas.',
    autorId: carlos.id,
    autorNome: carlos.nome,
    data: inicioThor.add(const Duration(minutes: 15)),
  ));
  aThor.eventos.add(AppointmentEvent(data: inicioThor, descricao: 'Atendimento iniciado', autorNome: carlos.nome));

  final inicioMel = now.subtract(const Duration(minutes: 20));
  final aMel = appt(mel, tosaHig, bruna, inicioMel, AppointmentStatus.emAndamento);
  aMel.iniciadoEm = inicioMel;
  aMel.etapas[0]
    ..status = StepStatus.emAndamento
    ..inicio = inicioMel
    ..responsavelId = bruna.id
    ..responsavelNome = bruna.nome;

  final amanha = today.add(const Duration(days: 1));
  final aLuna = appt(luna, consulta, helena, DateTime(amanha.year, amanha.month, amanha.day, 14),
      AppointmentStatus.agendado);
  aLuna.observacaoCliente = 'Retorno da consulta da gastrite.';

  // ---------------------------------------------------------- notificações
  void notif(UserModel u, String t, String m, Appointment? a, Duration ago, {bool lida = false}) {
    s.notifications.add(AppNotification(
      id: newId(),
      userId: u.id,
      titulo: t,
      mensagem: m,
      data: now.subtract(ago),
      lida: lida,
      agendamentoId: a?.id,
    ));
  }

  notif(ana, 'Consulta da Luna confirmada', 'Amanhã às 14:00 com ${helena.nome}.', aLuna, const Duration(hours: 20),
      lida: true);
  notif(ana, 'Thor está na secagem',
      'Etapa iniciada. Previsão de conclusão às ${formatTime(aThor.fimPrevisto)}.', aThor, const Duration(minutes: 5));
  notif(carlos, 'Novo atendimento atribuído', 'Thor · Banho completo hoje.', aThor, const Duration(hours: 22));
  notif(helena, 'Novo atendimento atribuído', 'Luna · Consulta veterinária amanhã às 14:00.', aLuna,
      const Duration(hours: 20));
  notif(gerente, 'Novo agendamento', 'Luna · Consulta veterinária amanhã às 14:00.', aLuna, const Duration(hours: 20));
}
