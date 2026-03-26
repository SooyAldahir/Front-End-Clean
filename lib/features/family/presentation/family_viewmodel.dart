import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/family_repository.dart';
import '../../../core/storage/session_storage.dart';
import '../../../shared/models/family.dart';
import '../../../tools/media_picker.dart';

class FamilyViewModel {
  final FamilyRepository _repo    = FamilyRepository();
  final SessionStorage   _session = SessionStorage();

  final loading       = ValueNotifier<bool>(false);
  final family        = ValueNotifier<FamilyModel?>(null);
  final available     = ValueNotifier<List<dynamic>>([]);

  Future<void> loadFamily() async {
    loading.value = true;
    try {
      final id = await _session.getFamiliaId();
      if (id == null) {
        await loadAvailable();
        return;
      }
      family.value = await _repo.getById(id);
    } finally {
      loading.value = false;
    }
  }

  Future<void> loadAvailable() async {
    final data = await _repo.getAvailable();
    data.sort((a, b) => ((a['num_alumnos'] ?? 0) as int).compareTo((b['num_alumnos'] ?? 0) as int));
    available.value = data;
  }

  void dispose() {
    loading.dispose();
    family.dispose();
    available.dispose();
  }
}

// ─── EditFamilyViewModel ──────────────────────────────────────────────────────
class EditFamilyViewModel {
  final FamilyRepository _repo  = FamilyRepository();

  final profileImage         = ValueNotifier<XFile?>(null);
  final coverImage           = ValueNotifier<XFile?>(null);
  final isLoading            = ValueNotifier<bool>(false);
  final descripcionCtrl      = TextEditingController();
  final descripcionModificada = ValueNotifier<bool>(false);

  FamilyModel? _currentFamily;

  Future<void> init(int familyId) async {
    final data = await _repo.getById(familyId);
    _currentFamily = data;
    if (data != null) {
      descripcionCtrl.text = data.descripcion ?? '';
    }
  }

  FamilyModel? get currentFamily => _currentFamily;

  Future<void> selectProfileImage(BuildContext context) async {
    final f = await MediaPicker.pickImage(context);
    if (f != null) profileImage.value = f;
  }

  Future<void> selectCoverImage(BuildContext context) async {
    final f = await MediaPicker.pickImage(context);
    if (f != null) coverImage.value = f;
  }

  Future<String?> saveChanges(int familyId) async {
    final hasImages      = profileImage.value != null || coverImage.value != null;
    final hasDescripcion = descripcionModificada.value;

    if (!hasImages && !hasDescripcion) return 'No hay cambios para guardar';

    isLoading.value = true;
    try {
      if (hasDescripcion) {
        await _repo.updateDescripcion(familyId: familyId, descripcion: descripcionCtrl.text.trim());
      }
      if (hasImages) {
        await _repo.updateFotos(
          familyId:     familyId,
          profileImage: profileImage.value != null ? File(profileImage.value!.path) : null,
          coverImage:   coverImage.value   != null ? File(coverImage.value!.path)   : null,
        );
      }
      return null; // éxito
    } catch (e) {
      return e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  void dispose() {
    profileImage.dispose();
    coverImage.dispose();
    isLoading.dispose();
    descripcionCtrl.dispose();
    descripcionModificada.dispose();
  }
}
