import 'formatters.dart';

class Validators {
  static String? required(String? v, [String campo = 'Campo']) {
    if (v == null || v.trim().isEmpty) return '$campo obrigatório';
    return null;
  }

  static String? name(String? v) {
    if (v == null || v.trim().length < 3) return 'Informe o nome completo (mín. 3 letras)';
    return null;
  }

  static final _emailRe = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Informe o e-mail';
    if (!_emailRe.hasMatch(v.trim())) return 'E-mail inválido';
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Informe a senha';
    if (v.length < 6) return 'A senha deve ter pelo menos 6 caracteres';
    return null;
  }

  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Informe o telefone';
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10 || digits.length > 11) return 'Telefone inválido (DDD + número)';
    return null;
  }

  static String? money(String? v) {
    final value = parseMoney(v ?? '');
    if (value == null) return 'Valor inválido';
    if (value <= 0) return 'O valor deve ser maior que zero';
    return null;
  }

  static String? positiveDecimal(String? v, {bool optional = false, String campo = 'Valor'}) {
    if ((v == null || v.trim().isEmpty) && optional) return null;
    final value = parseDecimal(v ?? '');
    if (value == null || value <= 0) return '$campo inválido';
    return null;
  }

  static String? positiveInt(String? v, {String campo = 'Valor'}) {
    final value = int.tryParse((v ?? '').trim());
    if (value == null || value <= 0) return '$campo inválido';
    return null;
  }

  static String? date(String? v, {bool optional = false, bool notFuture = false}) {
    if ((v == null || v.trim().isEmpty) && optional) return null;
    final d = parseDate(v ?? '');
    if (d == null) return 'Use o formato DD/MM/AAAA';
    if (notFuture && d.isAfter(DateTime.now())) return 'A data não pode ser futura';
    return null;
  }
}
