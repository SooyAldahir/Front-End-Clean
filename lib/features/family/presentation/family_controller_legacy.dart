import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/family_repository.dart';
import '../../../core/storage/session_storage.dart';

/// Legacy controller wrapper kept for compatibility with family_page.dart.
/// Delegates to FamilyRepository.
class FamilyController {
  BuildContext? context;
  final FamilyRepository _repo    = FamilyRepository();
  final SessionStorage   _session = SessionStorage();

  Future? init(BuildContext ctx) { context = ctx; return null; }

  Future<int?> resolveFamilyId() async {
    // 1. Try session cache
    final id = await _session.getFamiliaId();
    if (id != null) return id;
    // 2. Query API by document
    final user = await _session.getUser();
    if (user == null) return null;
    final mat = user['matricula'] is int ? user['matricula'] as int : int.tryParse(user['matricula']?.toString() ?? '');
    final emp = user['num_empleado'] is int ? user['num_empleado'] as int : int.tryParse(user['num_empleado']?.toString() ?? '');
    return _repo.resolveFamilyId(matricula: mat, numEmpleado: emp);
  }

  Future<void> goToEditPage(BuildContext ctx, {int? familyId}) async {
    final id = familyId ?? await resolveFamilyId();
    if (id == null || id <= 0) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('No se pudo identificar la familia del usuario.')));
      return;
    }
    Navigator.pushNamed(ctx, 'edit', arguments: id);
  }
}
