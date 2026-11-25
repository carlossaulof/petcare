import '../../core/ids.dart';
import '../models/models.dart';
import '../store_base.dart';

mixin UserRepository on StoreBase {
  List<UserModel> get clients => users.where((u) => u.isCliente).toList()
    ..sort((a, b) => a.nome.compareTo(b.nome));

  List<UserModel> get staffMembers => users.where((u) => u.isStaff).toList()
    ..sort((a, b) => a.nome.compareTo(b.nome));

  List<UserModel> staffWithSpecialty(StaffSpecialty s) =>
      users.where((u) => u.isFuncionario && u.ativo && u.especialidade == s).toList();

  UserModel? findByEmail(String email) {
    final e = email.trim().toLowerCase();
    for (final u in users) {
      if (u.email.toLowerCase() == e) return u;
    }
    return null;
  }

  bool verifyPassword(UserModel user, String password) =>
      hashPassword(password, user.salt) == user.senhaHash;

  UserModel _newUser({
    required String nome,
    required String email,
    required String telefone,
    required String senha,
    required UserRole role,
    StaffSpecialty? especialidade,
  }) {
    if (findByEmail(email) != null) {
      throw BusinessException('Já existe uma conta com este e-mail.');
    }
    final salt = newSalt();
    final u = UserModel(
      id: newId(),
      nome: nome.trim(),
      email: email.trim().toLowerCase(),
      telefone: telefone.trim(),
      role: role,
      especialidade: role == UserRole.funcionario ? (especialidade ?? StaffSpecialty.banhoTosa) : null,
      senhaHash: hashPassword(senha, salt),
      salt: salt,
      criadoEm: DateTime.now(),
    );
    users.add(u);
    return u;
  }

  /// Cadastro público: sempre cria um CLIENTE.
  UserModel registerClient({
    required String nome,
    required String email,
    required String telefone,
    required String senha,
  }) {
    final u = _newUser(
      nome: nome,
      email: email,
      telefone: telefone,
      senha: senha,
      role: UserRole.cliente,
    );
    pushNotification(u.id, 'Bem-vindo(a) ao PetCare!',
        'Cadastre seus pets e agende o primeiro atendimento.');
    notifyManagers('Novo cliente', '${u.nome} criou uma conta.');
    commit();
    return u;
  }

  /// Funcionários e gerentes só podem ser cadastrados por um gerente.
  UserModel createUserByManager(
    UserModel actor, {
    required String nome,
    required String email,
    required String telefone,
    required String senha,
    required UserRole role,
    StaffSpecialty? especialidade,
  }) {
    ensureActive(actor);
    ensure(actor.isGerente, 'Somente gerentes podem cadastrar usuários.');
    final u = _newUser(
      nome: nome,
      email: email,
      telefone: telefone,
      senha: senha,
      role: role,
      especialidade: especialidade,
    );
    pushNotification(u.id, 'Conta criada', 'Sua conta de ${u.role.label} foi criada por ${actor.nome}.');
    commit();
    return u;
  }

  void updateProfile(UserModel actor, String userId, {required String nome, required String telefone}) {
    ensureActive(actor);
    ensure(actor.id == userId || actor.isGerente);
    final u = userById(userId);
    if (u == null) throw BusinessException('Usuário não encontrado.');
    u.nome = nome.trim();
    u.telefone = telefone.trim();
    commit();
  }

  void updateStaffRole(UserModel actor, String userId,
      {required UserRole role, StaffSpecialty? especialidade}) {
    ensure(actor.isGerente);
    final u = userById(userId);
    if (u == null || u.isCliente) throw BusinessException('Funcionário não encontrado.');
    if (u.id == actor.id && role != UserRole.gerente) {
      throw BusinessException('Você não pode remover seu próprio acesso de gerente.');
    }
    ensure(role != UserRole.cliente, 'Use o cadastro de clientes para contas de cliente.');
    u.role = role;
    u.especialidade = role == UserRole.funcionario ? (especialidade ?? StaffSpecialty.banhoTosa) : null;
    commit();
  }

  void setUserActive(UserModel actor, String userId, bool ativo) {
    ensure(actor.isGerente);
    if (actor.id == userId) throw BusinessException('Você não pode desativar a própria conta.');
    final u = userById(userId);
    if (u == null) throw BusinessException('Usuário não encontrado.');
    u.ativo = ativo;
    commit();
  }

  void changePassword(UserModel actor, {required String atual, required String nova}) {
    if (!verifyPassword(actor, atual)) throw BusinessException('Senha atual incorreta.');
    actor.salt = newSalt();
    actor.senhaHash = hashPassword(nova, actor.salt);
    commit();
  }

  /// Gera um código de 6 dígitos válido por 15 minutos.
  /// Retorna o código em texto puro para que a camada de apresentação o envie
  /// por e-mail (se configurado) ou o exiba no modo local.
  String? createPasswordResetCode(String email) {
    final u = findByEmail(email);
    if (u == null || !u.ativo) return null;
    final code = newNumericCode(6);
    u.resetCodeHash = hashPassword(code, u.salt);
    u.resetExpira = DateTime.now().add(const Duration(minutes: 15));
    commit();
    return code;
  }

  void resetPassword({required String email, required String code, required String nova}) {
    final u = findByEmail(email);
    if (u == null || u.resetCodeHash == null || u.resetExpira == null) {
      throw BusinessException('Código inválido ou expirado.');
    }
    if (DateTime.now().isAfter(u.resetExpira!) || hashPassword(code.trim(), u.salt) != u.resetCodeHash) {
      throw BusinessException('Código inválido ou expirado.');
    }
    u.salt = newSalt();
    u.senhaHash = hashPassword(nova, u.salt);
    u.resetCodeHash = null;
    u.resetExpira = null;
    commit();
  }
}
