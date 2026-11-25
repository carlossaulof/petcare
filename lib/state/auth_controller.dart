import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/app_data.dart';

/// Sessão do usuário. O usuário atual é sempre lido da [AppData], então
/// alterações (ex.: desativação pelo gerente) têm efeito imediato.
class AuthController extends ChangeNotifier {
  AuthController(this.data);

  final AppData data;
  static const _sessionKey = 'petcare_session_user';

  String? _userId;

  UserModel? get currentUser {
    final u = data.userById(_userId);
    if (u == null || !u.ativo) return null;
    return u;
  }

  bool get isLoggedIn => currentUser != null;

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString(_sessionKey);
    if (currentUser == null) _userId = null;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    if (_userId == null) {
      await prefs.remove(_sessionKey);
    } else {
      await prefs.setString(_sessionKey, _userId!);
    }
  }

  Future<void> login(String email, String senha) async {
    final u = data.findByEmail(email);
    if (u == null || !data.verifyPassword(u, senha)) {
      throw BusinessException('E-mail ou senha incorretos.');
    }
    if (!u.ativo) throw BusinessException('Conta desativada. Procure o petshop.');
    _userId = u.id;
    await _save();
    notifyListeners();
  }

  Future<void> register({
    required String nome,
    required String email,
    required String telefone,
    required String senha,
  }) async {
    final u = data.registerClient(nome: nome, email: email, telefone: telefone, senha: senha);
    _userId = u.id;
    await _save();
    notifyListeners();
  }

  Future<void> logout() async {
    _userId = null;
    await _save();
    notifyListeners();
  }
}
