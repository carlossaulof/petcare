import 'enums.dart';

class UserModel {
  final String id;
  String nome;
  String email;
  String telefone;
  UserRole role;
  StaffSpecialty? especialidade;
  bool ativo;
  String senhaHash;
  String salt;
  final DateTime criadoEm;
  String? resetCodeHash;
  DateTime? resetExpira;

  UserModel({
    required this.id,
    required this.nome,
    required this.email,
    required this.telefone,
    required this.role,
    this.especialidade,
    this.ativo = true,
    required this.senhaHash,
    required this.salt,
    required this.criadoEm,
    this.resetCodeHash,
    this.resetExpira,
  });

  bool get isCliente => role == UserRole.cliente;
  bool get isFuncionario => role == UserRole.funcionario;
  bool get isGerente => role == UserRole.gerente;
  bool get isStaff => role != UserRole.cliente;
  bool get isVeterinario => especialidade == StaffSpecialty.veterinario;

  /// Acesso à área veterinária: veterinários e gerentes.
  bool get canAccessVetArea => isGerente || (isFuncionario && isVeterinario);

  String get firstName => nome.trim().split(' ').first;
  String get initials {
    final parts = nome.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  String get roleDescription =>
      isFuncionario && especialidade != null ? '${role.label} · ${especialidade!.label}' : role.label;

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'email': email,
        'telefone': telefone,
        'role': role.name,
        'especialidade': especialidade?.name,
        'ativo': ativo,
        'senhaHash': senhaHash,
        'salt': salt,
        'criadoEm': criadoEm.toIso8601String(),
        'resetCodeHash': resetCodeHash,
        'resetExpira': resetExpira?.toIso8601String(),
      };

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: j['id'] as String,
        nome: j['nome'] as String,
        email: j['email'] as String,
        telefone: (j['telefone'] ?? '') as String,
        role: enumByName(UserRole.values, j['role'], UserRole.cliente),
        especialidade: j['especialidade'] == null
            ? null
            : enumByName(StaffSpecialty.values, j['especialidade'], StaffSpecialty.banhoTosa),
        ativo: (j['ativo'] ?? true) as bool,
        senhaHash: j['senhaHash'] as String,
        salt: j['salt'] as String,
        criadoEm: parseDt(j['criadoEm']) ?? DateTime.now(),
        resetCodeHash: j['resetCodeHash'] as String?,
        resetExpira: parseDt(j['resetExpira']),
      );
}
