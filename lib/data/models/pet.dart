import 'enums.dart';

class Vaccine {
  String nome;
  DateTime data;
  DateTime? proxima;

  Vaccine({required this.nome, required this.data, this.proxima});

  Map<String, dynamic> toJson() => {
        'nome': nome,
        'data': data.toIso8601String(),
        'proxima': proxima?.toIso8601String(),
      };

  factory Vaccine.fromJson(Map<String, dynamic> j) => Vaccine(
        nome: j['nome'] as String,
        data: parseDt(j['data']) ?? DateTime.now(),
        proxima: parseDt(j['proxima']),
      );
}

class Pet {
  final String id;
  String tutorId;
  String nome;
  Species especie;
  String raca;
  PetSex sexo;
  PetSize porte;
  DateTime? nascimento;
  double peso;
  String? fotoBase64;
  bool castrado;
  String alergias;
  String condicoes;
  String medicacoes;
  String observacoes;
  List<Vaccine> vacinas;
  bool ativo;
  final DateTime criadoEm;

  Pet({
    required this.id,
    required this.tutorId,
    required this.nome,
    required this.especie,
    required this.raca,
    required this.sexo,
    required this.porte,
    this.nascimento,
    required this.peso,
    this.fotoBase64,
    this.castrado = false,
    this.alergias = '',
    this.condicoes = '',
    this.medicacoes = '',
    this.observacoes = '',
    List<Vaccine>? vacinas,
    this.ativo = true,
    required this.criadoEm,
  }) : vacinas = vacinas ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'tutorId': tutorId,
        'nome': nome,
        'especie': especie.name,
        'raca': raca,
        'sexo': sexo.name,
        'porte': porte.name,
        'nascimento': nascimento?.toIso8601String(),
        'peso': peso,
        'fotoBase64': fotoBase64,
        'castrado': castrado,
        'alergias': alergias,
        'condicoes': condicoes,
        'medicacoes': medicacoes,
        'observacoes': observacoes,
        'vacinas': vacinas.map((v) => v.toJson()).toList(),
        'ativo': ativo,
        'criadoEm': criadoEm.toIso8601String(),
      };

  factory Pet.fromJson(Map<String, dynamic> j) => Pet(
        id: j['id'] as String,
        tutorId: j['tutorId'] as String,
        nome: j['nome'] as String,
        especie: enumByName(Species.values, j['especie'], Species.outro),
        raca: (j['raca'] ?? '') as String,
        sexo: enumByName(PetSex.values, j['sexo'], PetSex.macho),
        porte: enumByName(PetSize.values, j['porte'], PetSize.medio),
        nascimento: parseDt(j['nascimento']),
        peso: (j['peso'] as num?)?.toDouble() ?? 0,
        fotoBase64: j['fotoBase64'] as String?,
        castrado: (j['castrado'] ?? false) as bool,
        alergias: (j['alergias'] ?? '') as String,
        condicoes: (j['condicoes'] ?? '') as String,
        medicacoes: (j['medicacoes'] ?? '') as String,
        observacoes: (j['observacoes'] ?? '') as String,
        vacinas: ((j['vacinas'] ?? []) as List)
            .map((e) => Vaccine.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        ativo: (j['ativo'] ?? true) as bool,
        criadoEm: parseDt(j['criadoEm']) ?? DateTime.now(),
      );
}
