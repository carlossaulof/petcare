import 'enums.dart';

/// Etapa de um procedimento (ex.: Banho, Secagem, Escovação).
class ProcedureStep {
  String nome;
  StepStatus status;
  DateTime? inicio;
  DateTime? fim;
  String? responsavelId;
  String? responsavelNome;

  ProcedureStep({
    required this.nome,
    this.status = StepStatus.pendente,
    this.inicio,
    this.fim,
    this.responsavelId,
    this.responsavelNome,
  });

  Map<String, dynamic> toJson() => {
        'nome': nome,
        'status': status.name,
        'inicio': inicio?.toIso8601String(),
        'fim': fim?.toIso8601String(),
        'responsavelId': responsavelId,
        'responsavelNome': responsavelNome,
      };

  factory ProcedureStep.fromJson(Map<String, dynamic> j) => ProcedureStep(
        nome: j['nome'] as String,
        status: enumByName(StepStatus.values, j['status'], StepStatus.pendente),
        inicio: parseDt(j['inicio']),
        fim: parseDt(j['fim']),
        responsavelId: j['responsavelId'] as String?,
        responsavelNome: j['responsavelNome'] as String?,
      );
}

class AppointmentNote {
  final String id;
  NoteType tipo;
  String texto;
  String autorId;
  String autorNome;
  DateTime data;

  AppointmentNote({
    required this.id,
    required this.tipo,
    required this.texto,
    required this.autorId,
    required this.autorNome,
    required this.data,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'tipo': tipo.name,
        'texto': texto,
        'autorId': autorId,
        'autorNome': autorNome,
        'data': data.toIso8601String(),
      };

  factory AppointmentNote.fromJson(Map<String, dynamic> j) => AppointmentNote(
        id: j['id'] as String,
        tipo: enumByName(NoteType.values, j['tipo'], NoteType.observacao),
        texto: j['texto'] as String,
        autorId: j['autorId'] as String,
        autorNome: (j['autorNome'] ?? '') as String,
        data: parseDt(j['data']) ?? DateTime.now(),
      );
}

/// Serviço adicional solicitado pela equipe — exige autorização do cliente.
class AdditionalRequest {
  final String id;
  String servicoId;
  String nome;
  double preco;
  int duracaoMin;
  String justificativa;
  AdditionalStatus status;
  String solicitadoPorId;
  String solicitadoPorNome;
  DateTime solicitadoEm;
  DateTime? respondidoEm;

  AdditionalRequest({
    required this.id,
    required this.servicoId,
    required this.nome,
    required this.preco,
    required this.duracaoMin,
    required this.justificativa,
    this.status = AdditionalStatus.pendente,
    required this.solicitadoPorId,
    required this.solicitadoPorNome,
    required this.solicitadoEm,
    this.respondidoEm,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'servicoId': servicoId,
        'nome': nome,
        'preco': preco,
        'duracaoMin': duracaoMin,
        'justificativa': justificativa,
        'status': status.name,
        'solicitadoPorId': solicitadoPorId,
        'solicitadoPorNome': solicitadoPorNome,
        'solicitadoEm': solicitadoEm.toIso8601String(),
        'respondidoEm': respondidoEm?.toIso8601String(),
      };

  factory AdditionalRequest.fromJson(Map<String, dynamic> j) => AdditionalRequest(
        id: j['id'] as String,
        servicoId: j['servicoId'] as String,
        nome: j['nome'] as String,
        preco: (j['preco'] as num).toDouble(),
        duracaoMin: (j['duracaoMin'] as num?)?.toInt() ?? 0,
        justificativa: (j['justificativa'] ?? '') as String,
        status: enumByName(AdditionalStatus.values, j['status'], AdditionalStatus.pendente),
        solicitadoPorId: j['solicitadoPorId'] as String,
        solicitadoPorNome: (j['solicitadoPorNome'] ?? '') as String,
        solicitadoEm: parseDt(j['solicitadoEm']) ?? DateTime.now(),
        respondidoEm: parseDt(j['respondidoEm']),
      );
}

/// Registro de auditoria exibido na linha do tempo.
class AppointmentEvent {
  DateTime data;
  String descricao;
  String autorNome;

  AppointmentEvent({required this.data, required this.descricao, required this.autorNome});

  Map<String, dynamic> toJson() => {
        'data': data.toIso8601String(),
        'descricao': descricao,
        'autorNome': autorNome,
      };

  factory AppointmentEvent.fromJson(Map<String, dynamic> j) => AppointmentEvent(
        data: parseDt(j['data']) ?? DateTime.now(),
        descricao: j['descricao'] as String,
        autorNome: (j['autorNome'] ?? '') as String,
      );
}

class Appointment {
  final String id;
  String clienteId;
  String petId;
  String servicoId;
  String servicoNome;
  ServiceCategory categoria;
  String? funcionarioId;
  DateTime inicio;
  int duracaoMin;
  double preco;
  AppointmentStatus status;
  String observacaoCliente;
  List<ProcedureStep> etapas;
  List<AppointmentNote> notas;
  List<AdditionalRequest> adicionais;
  List<AppointmentEvent> eventos;
  DateTime? iniciadoEm;
  DateTime? concluidoEm;
  DateTime? previsaoManual;
  String? motivoCancelamento;
  int reagendamentos;
  final DateTime criadoEm;

  Appointment({
    required this.id,
    required this.clienteId,
    required this.petId,
    required this.servicoId,
    required this.servicoNome,
    required this.categoria,
    this.funcionarioId,
    required this.inicio,
    required this.duracaoMin,
    required this.preco,
    this.status = AppointmentStatus.agendado,
    this.observacaoCliente = '',
    required this.etapas,
    List<AppointmentNote>? notas,
    List<AdditionalRequest>? adicionais,
    List<AppointmentEvent>? eventos,
    this.iniciadoEm,
    this.concluidoEm,
    this.previsaoManual,
    this.motivoCancelamento,
    this.reagendamentos = 0,
    required this.criadoEm,
  })  : notas = notas ?? [],
        adicionais = adicionais ?? [],
        eventos = eventos ?? [];

  /// Duração total incluindo adicionais aprovados.
  int get duracaoTotalMin =>
      duracaoMin +
      adicionais
          .where((a) => a.status == AdditionalStatus.aprovado)
          .fold<int>(0, (s, a) => s + a.duracaoMin);

  DateTime get fimPrevisto => inicio.add(Duration(minutes: duracaoTotalMin));

  double get valorTotal =>
      preco +
      adicionais
          .where((a) => a.status == AdditionalStatus.aprovado)
          .fold<double>(0, (s, a) => s + a.preco);

  int get etapasConcluidas => etapas.where((e) => e.status == StepStatus.concluido).length;

  double get progresso {
    if (status == AppointmentStatus.concluido) return 1;
    if (etapas.isEmpty) return status == AppointmentStatus.emAndamento ? 0.5 : 0;
    final emAndamento = etapas.any((e) => e.status == StepStatus.emAndamento) ? 0.5 : 0;
    return (etapasConcluidas + emAndamento) / etapas.length;
  }

  ProcedureStep? get etapaAtual {
    for (final e in etapas) {
      if (e.status == StepStatus.emAndamento) return e;
    }
    for (final e in etapas) {
      if (e.status == StepStatus.pendente) return e;
    }
    return null;
  }

  /// Previsão de conclusão: manual (definida pela equipe) ou calculada pelo
  /// progresso das etapas em relação à duração contratada.
  DateTime get previsaoConclusao {
    if (previsaoManual != null) return previsaoManual!;
    if (status == AppointmentStatus.concluido && concluidoEm != null) return concluidoEm!;
    if (status != AppointmentStatus.emAndamento) return fimPrevisto;
    final restante = (duracaoTotalMin * (1 - progresso)).round();
    final calculada = DateTime.now().add(Duration(minutes: restante));
    final base = (iniciadoEm ?? inicio).add(Duration(minutes: duracaoTotalMin));
    return calculada.isAfter(base) ? calculada : base;
  }

  bool get temAdicionalPendente => adicionais.any((a) => a.status == AdditionalStatus.pendente);

  bool overlaps(DateTime start, int minutes) {
    final end = start.add(Duration(minutes: minutes));
    return start.isBefore(fimPrevisto) && end.isAfter(inicio);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'clienteId': clienteId,
        'petId': petId,
        'servicoId': servicoId,
        'servicoNome': servicoNome,
        'categoria': categoria.name,
        'funcionarioId': funcionarioId,
        'inicio': inicio.toIso8601String(),
        'duracaoMin': duracaoMin,
        'preco': preco,
        'status': status.name,
        'observacaoCliente': observacaoCliente,
        'etapas': etapas.map((e) => e.toJson()).toList(),
        'notas': notas.map((e) => e.toJson()).toList(),
        'adicionais': adicionais.map((e) => e.toJson()).toList(),
        'eventos': eventos.map((e) => e.toJson()).toList(),
        'iniciadoEm': iniciadoEm?.toIso8601String(),
        'concluidoEm': concluidoEm?.toIso8601String(),
        'previsaoManual': previsaoManual?.toIso8601String(),
        'motivoCancelamento': motivoCancelamento,
        'reagendamentos': reagendamentos,
        'criadoEm': criadoEm.toIso8601String(),
      };

  static List<T> _list<T>(Object? raw, T Function(Map<String, dynamic>) f) =>
      ((raw ?? []) as List).map((e) => f(Map<String, dynamic>.from(e as Map))).toList();

  factory Appointment.fromJson(Map<String, dynamic> j) => Appointment(
        id: j['id'] as String,
        clienteId: j['clienteId'] as String,
        petId: j['petId'] as String,
        servicoId: j['servicoId'] as String,
        servicoNome: j['servicoNome'] as String,
        categoria: enumByName(ServiceCategory.values, j['categoria'], ServiceCategory.outro),
        funcionarioId: j['funcionarioId'] as String?,
        inicio: parseDt(j['inicio']) ?? DateTime.now(),
        duracaoMin: (j['duracaoMin'] as num).toInt(),
        preco: (j['preco'] as num).toDouble(),
        status: enumByName(AppointmentStatus.values, j['status'], AppointmentStatus.agendado),
        observacaoCliente: (j['observacaoCliente'] ?? '') as String,
        etapas: _list(j['etapas'], ProcedureStep.fromJson),
        notas: _list(j['notas'], AppointmentNote.fromJson),
        adicionais: _list(j['adicionais'], AdditionalRequest.fromJson),
        eventos: _list(j['eventos'], AppointmentEvent.fromJson),
        iniciadoEm: parseDt(j['iniciadoEm']),
        concluidoEm: parseDt(j['concluidoEm']),
        previsaoManual: parseDt(j['previsaoManual']),
        motivoCancelamento: j['motivoCancelamento'] as String?,
        reagendamentos: (j['reagendamentos'] ?? 0) as int,
        criadoEm: parseDt(j['criadoEm']) ?? DateTime.now(),
      );
}
