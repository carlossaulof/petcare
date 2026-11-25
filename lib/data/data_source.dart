import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Abstração de persistência. A versão atual grava tudo localmente;
/// uma implementação remota (Firestore, Supabase, API própria) pode
/// substituir esta classe sem alterar telas nem regras de negócio.
abstract class PetCareDataSource {
  Future<Map<String, dynamic>?> load();
  Future<void> save(Map<String, dynamic> data);
  Future<void> clear();
}

class SharedPrefsDataSource implements PetCareDataSource {
  static const _key = 'petcare_db_v1';

  @override
  Future<Map<String, dynamic>?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null; // dado corrompido: recomeça com base de demonstração
    }
  }

  @override
  Future<void> save(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(data));
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

/// Usada nos testes.
class MemoryDataSource implements PetCareDataSource {
  Map<String, dynamic>? data;

  @override
  Future<Map<String, dynamic>?> load() async => data;

  @override
  Future<void> save(Map<String, dynamic> d) async => data = jsonDecode(jsonEncode(d)) as Map<String, dynamic>;

  @override
  Future<void> clear() async => data = null;
}
