import 'enums.dart';

class ServiceModel {
  final String id;
  String nome;
  String descricao;
  ServiceCategory categoria;
  double preco;
  int duracaoMin;
  List<String> etapas;
  bool ativo;

  ServiceModel({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.categoria,
    required this.preco,
    required this.duracaoMin,
    required this.etapas,
    this.ativo = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'descricao': descricao,
        'categoria': categoria.name,
        'preco': preco,
        'duracaoMin': duracaoMin,
        'etapas': etapas,
        'ativo': ativo,
      };

  factory ServiceModel.fromJson(Map<String, dynamic> j) => ServiceModel(
        id: j['id'] as String,
        nome: j['nome'] as String,
        descricao: (j['descricao'] ?? '') as String,
        categoria: enumByName(ServiceCategory.values, j['categoria'], ServiceCategory.outro),
        preco: (j['preco'] as num).toDouble(),
        duracaoMin: (j['duracaoMin'] as num).toInt(),
        etapas: List<String>.from((j['etapas'] ?? []) as List),
        ativo: (j['ativo'] ?? true) as bool,
      );
}

/// Horário de funcionamento do estabelecimento.
class BusinessHours {
  int aberturaMin; // minutos desde 00:00
  int fechamentoMin;
  Set<int> diasFuncionamento; // DateTime.weekday (1 = segunda ... 7 = domingo)
  int intervaloMin; // granularidade dos horários oferecidos
  int antecedenciaCancelamentoHoras;

  BusinessHours({
    this.aberturaMin = 8 * 60,
    this.fechamentoMin = 18 * 60,
    Set<int>? diasFuncionamento,
    this.intervaloMin = 30,
    this.antecedenciaCancelamentoHoras = 2,
  }) : diasFuncionamento = diasFuncionamento ?? {1, 2, 3, 4, 5, 6};

  Map<String, dynamic> toJson() => {
        'aberturaMin': aberturaMin,
        'fechamentoMin': fechamentoMin,
        'diasFuncionamento': diasFuncionamento.toList(),
        'intervaloMin': intervaloMin,
        'antecedenciaCancelamentoHoras': antecedenciaCancelamentoHoras,
      };

  factory BusinessHours.fromJson(Map<String, dynamic> j) => BusinessHours(
        aberturaMin: (j['aberturaMin'] ?? 480) as int,
        fechamentoMin: (j['fechamentoMin'] ?? 1080) as int,
        diasFuncionamento: Set<int>.from((j['diasFuncionamento'] ?? [1, 2, 3, 4, 5, 6]) as List),
        intervaloMin: (j['intervaloMin'] ?? 30) as int,
        antecedenciaCancelamentoHoras: (j['antecedenciaCancelamentoHoras'] ?? 2) as int,
      );
}
