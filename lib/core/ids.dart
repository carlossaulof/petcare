import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

final _random = Random.secure();

String newId() {
  final t = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final r = _random.nextInt(0x7fffffff).toRadixString(36);
  return '$t$r';
}

String newSalt() {
  final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
  return base64UrlEncode(bytes);
}

String hashPassword(String password, String salt) {
  // Hash local (SHA-256 com salt, 1.000 iterações). Em produção a senha
  // fica no provedor de autenticação (ex.: Firebase Auth), nunca no app.
  List<int> digest = utf8.encode('$salt:$password');
  for (var i = 0; i < 1000; i++) {
    digest = sha256.convert(digest).bytes;
  }
  return base64Encode(digest);
}

String newNumericCode(int length) =>
    List.generate(length, (_) => _random.nextInt(10).toString()).join();
