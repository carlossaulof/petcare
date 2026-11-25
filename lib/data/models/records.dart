import 'enums.dart';

class Payment {
  final String id;
  String agendamentoId;
  String clienteId;
  double valor;
  PaymentMethod? metodo;
  PaymentChannel canal;
  PaymentStatus status;
  final DateTime criadoEm;
  DateTime? pagoEm;
  String? confirmadoPorId;
  String? referenciaExterna; // id da transação no gateway, quando houver

  Payment({
    required this.id,
    required this.agendamentoId,
    required this.clienteId,
    required this.valor,
    this.metodo,
    this.canal = PaymentChannel.presencial,
    this.status = PaymentStatus.pendente,
    required this.criadoEm,
    this.pagoEm,
    this.confirmadoPorId,
    this.referenciaExterna,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'agendamentoId': agendamentoId,
        'clienteId': clienteId,
        'valor': valor,
        'metodo': metodo?.name,
        'canal': canal.name,
        'status': status.name,
        'criadoEm': criadoEm.toIso8601String(),
        'pagoEm': pagoEm?.toIso8601String(),
        'confirmadoPorId': confirmadoPorId,
        'referenciaExterna': referenciaExterna,
      };

  factory Payment.fromJson(Map<String, dynamic> j) => Payment(
        id: j['id'] as String,
        agendamentoId: j['agendamentoId'] as String,
        clienteId: j['clienteId'] as String,
        valor: (j['valor'] as num).toDouble(),
        metodo: j['metodo'] == null
            ? null
            : enumByName(PaymentMethod.values, j['metodo'], PaymentMethod.dinheiro),
        canal: enumByName(PaymentChannel.values, j['canal'], PaymentChannel.presencial),
        status: enumByName(PaymentStatus.values, j['status'], PaymentStatus.pendente),
        criadoEm: parseDt(j['criadoEm']) ?? DateTime.now(),
        pagoEm: parseDt(j['pagoEm']),
        confirmadoPorId: j['confirmadoPorId'] as String?,
        referenciaExterna: j['referenciaExterna'] as String?,
      );
}

class Review {
  final String id;
  String agendamentoId;
  String clienteId;
  String? funcionarioId;
  String servicoId;
  int nota;
  String comentario;
  final DateTime data;

  Review({
    required this.id,
    required this.agendamentoId,
    required this.clienteId,
    this.funcionarioId,
    required this.servicoId,
    required this.nota,
    this.comentario = '',
    required this.data,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'agendamentoId': agendamentoId,
        'clienteId': clienteId,
        'funcionarioId': funcionarioId,
        'servicoId': servicoId,
        'nota': nota,
        'comentario': comentario,
        'data': data.toIso8601String(),
      };

  factory Review.fromJson(Map<String, dynamic> j) => Review(
        id: j['id'] as String,
        agendamentoId: j['agendamentoId'] as String,
        clienteId: j['clienteId'] as String,
        funcionarioId: j['funcionarioId'] as String?,
        servicoId: (j['servicoId'] ?? '') as String,
        nota: (j['nota'] as num).toInt(),
        comentario: (j['comentario'] ?? '') as String,
        data: parseDt(j['data']) ?? DateTime.now(),
      );
}

class AppNotification {
  final String id;
  String userId;
  String titulo;
  String mensagem;
  final DateTime data;
  bool lida;
  String? agendamentoId;

  AppNotification({
    required this.id,
    required this.userId,
    required this.titulo,
    required this.mensagem,
    required this.data,
    this.lida = false,
    this.agendamentoId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'titulo': titulo,
        'mensagem': mensagem,
        'data': data.toIso8601String(),
        'lida': lida,
        'agendamentoId': agendamentoId,
      };

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'] as String,
        userId: j['userId'] as String,
        titulo: j['titulo'] as String,
        mensagem: j['mensagem'] as String,
        data: parseDt(j['data']) ?? DateTime.now(),
        lida: (j['lida'] ?? false) as bool,
        agendamentoId: j['agendamentoId'] as String?,
      );
}

/// Ficha clínica — cada consulta veterinária registrada.
class ClinicalEntry {
  final String id;
  String petId;
  String? agendamentoId;
  String veterinarioId;
  String veterinarioNome;
  DateTime data;
  String queixa;
  String anamnese;
  String diagnostico;
  String prescricao;
  double? peso;
  double? temperatura;
  DateTime? retorno;

  ClinicalEntry({
    required this.id,
    required this.petId,
    this.agendamentoId,
    required this.veterinarioId,
    required this.veterinarioNome,
    required this.data,
    this.queixa = '',
    this.anamnese = '',
    required this.diagnostico,
    this.prescricao = '',
    this.peso,
    this.temperatura,
    this.retorno,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'petId': petId,
        'agendamentoId': agendamentoId,
        'veterinarioId': veterinarioId,
        'veterinarioNome': veterinarioNome,
        'data': data.toIso8601String(),
        'queixa': queixa,
        'anamnese': anamnese,
        'diagnostico': diagnostico,
        'prescricao': prescricao,
        'peso': peso,
        'temperatura': temperatura,
        'retorno': retorno?.toIso8601String(),
      };

  factory ClinicalEntry.fromJson(Map<String, dynamic> j) => ClinicalEntry(
        id: j['id'] as String,
        petId: j['petId'] as String,
        agendamentoId: j['agendamentoId'] as String?,
        veterinarioId: j['veterinarioId'] as String,
        veterinarioNome: (j['veterinarioNome'] ?? '') as String,
        data: parseDt(j['data']) ?? DateTime.now(),
        queixa: (j['queixa'] ?? '') as String,
        anamnese: (j['anamnese'] ?? '') as String,
        diagnostico: (j['diagnostico'] ?? '') as String,
        prescricao: (j['prescricao'] ?? '') as String,
        peso: (j['peso'] as num?)?.toDouble(),
        temperatura: (j['temperatura'] as num?)?.toDouble(),
        retorno: parseDt(j['retorno']),
      );
}
