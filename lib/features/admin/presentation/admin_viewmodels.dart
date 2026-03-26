import 'package:flutter/material.dart';
import '../../family/data/family_repository.dart';
import '../data/admin_repository.dart';
import '../../../shared/models/search_result.dart';
import '../../../shared/models/family.dart';

// ─── AddFamilyViewModel ───────────────────────────────────────────────────────
class AddFamilyViewModel {
  final AdminRepository _repo      = AdminRepository();
  final _searchRepo                = AdminRepository();

  final familyName         = ValueNotifier<String>('');
  final internalResidence  = ValueNotifier<bool>(true);
  final addressCtrl        = TextEditingController();
  final fatherCtrl         = TextEditingController();
  final motherCtrl         = TextEditingController();
  final fatherResults      = ValueNotifier<List<UserMiniModel>>([]);
  final motherResults      = ValueNotifier<List<UserMiniModel>>([]);
  final childResults       = ValueNotifier<List<UserMiniModel>>([]);
  final children           = ValueNotifier<List<UserMiniModel>>([]);
  final loading            = ValueNotifier<bool>(false);

  UserMiniModel? _pickedFather;
  UserMiniModel? _pickedMother;

  String _firstSurname(String? full) {
    if (full == null || full.trim().isEmpty) return '';
    final parts = full.trim().replaceAll(RegExp(r'\s+'), ' ').split(' ');
    final lower = parts.map((e) => e.toLowerCase()).toList();
    if (parts.length >= 3 && (lower[0] == 'de' || lower[0] == 'del')) {
      return '${parts[0]} ${parts[1]} ${parts[2]}';
    }
    if (parts.length >= 2 && (lower[0] == 'de' || lower[0] == 'del')) {
      return '${parts[0]} ${parts[1]}';
    }
    return parts.first;
  }

  void _recomputeFamilyName() {
    final f = _firstSurname(_pickedFather?.apellido);
    final m = _firstSurname(_pickedMother?.apellido);
    final base = [f, m].where((e) => e.isNotEmpty).join(' ');
    familyName.value = base.isEmpty ? '' : 'Familia $base';
  }

  Future<void> searchEmployee(String q, {required bool isFather}) async {
    if (q.trim().isEmpty) { (isFather ? fatherResults : motherResults).value = []; return; }
    final raw = await _searchRepo.searchUsers(q: q, tipo: 'EMPLEADO');
    final results = raw.map((e) => UserMiniModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    (isFather ? fatherResults : motherResults).value = results;
  }

  void pickFather(UserMiniModel u) {
    _pickedFather = u;
    fatherCtrl.text = u.fullName;
    fatherResults.value = [];
    _recomputeFamilyName();
  }

  void pickMother(UserMiniModel u) {
    _pickedMother = u;
    motherCtrl.text = u.fullName;
    motherResults.value = [];
    _recomputeFamilyName();
  }

  Future<void> searchChild(String q) async {
    if (q.trim().isEmpty) { childResults.value = []; return; }
    final raw = await _searchRepo.searchUsers(q: q, tipo: 'ALUMNO');
    childResults.value = raw.map((e) => UserMiniModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  void addChild(UserMiniModel u) {
    if (!children.value.any((x) => x.id == u.id)) {
      children.value = [...children.value, u];
    }
  }

  void removeChild(int index) {
    final list = [...children.value]..removeAt(index);
    children.value = list;
  }

  Future<String?> save(BuildContext context) async {
    if (_pickedFather == null && _pickedMother == null) return 'Selecciona al menos Papá o Mamá';
    final isInternal = internalResidence.value;
    final direccion  = isInternal ? null : addressCtrl.text.trim();
    if (!isInternal && (direccion == null || direccion.isEmpty)) return 'La dirección es requerida';

    loading.value = true;
    try {
      await _repo.createFamily(
        nombreFamilia: familyName.value.trim().isEmpty ? 'Familia' : familyName.value.trim(),
        residencia:    isInternal ? 'INTERNA' : 'EXTERNA',
        direccion:     direccion,
        papaId:        _pickedFather?.id,
        mamaId:        _pickedMother?.id,
        hijos:         children.value.map((k) => k.id).toList(),
      );
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    } finally {
      loading.value = false;
    }
  }

  void dispose() {
    familyName.dispose(); internalResidence.dispose(); addressCtrl.dispose();
    fatherCtrl.dispose(); motherCtrl.dispose(); fatherResults.dispose();
    motherResults.dispose(); childResults.dispose(); children.dispose();
    loading.dispose();
  }
}

// ─── AddAlumnsViewModel ───────────────────────────────────────────────────────
class AddAlumnsViewModel {
  final AdminRepository _repo = AdminRepository();

  final loading         = ValueNotifier<bool>(false);
  final selectedFamily  = ValueNotifier<FamilyModel?>(null);
  final selectedAlumns  = ValueNotifier<List<UserMiniModel>>([]);
  final alumnResults    = ValueNotifier<List<UserMiniModel>>([]);

  Future<void> searchAlumns(String q) async {
    if (q.trim().isEmpty) { alumnResults.value = []; return; }
    final raw = await _repo.searchUsers(q: q, tipo: 'ALUMNO');
    final currentIds = selectedAlumns.value.map((a) => a.id).toSet();
    alumnResults.value = raw
        .map((e) => UserMiniModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .where((u) => !currentIds.contains(u.id))
        .toList();
  }

  void addAlumn(UserMiniModel u) {
    if (!selectedAlumns.value.any((a) => a.id == u.id)) {
      selectedAlumns.value = [...selectedAlumns.value, u];
    }
    alumnResults.value = [];
  }

  void removeAlumn(UserMiniModel u) {
    selectedAlumns.value = selectedAlumns.value.where((a) => a.id != u.id).toList();
  }

  Future<String?> saveAssignments() async {
    if (selectedFamily.value == null) return 'Selecciona una familia.';
    if (selectedAlumns.value.isEmpty) return 'Añade al menos un alumno.';
    loading.value = true;
    try {
      await _repo.addMembersBulk(
        idFamilia:   selectedFamily.value!.id!,
        idUsuarios:  selectedAlumns.value.map((a) => a.id).toList(),
      );
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    } finally {
      loading.value = false;
    }
  }

  void dispose() {
    loading.dispose(); selectedFamily.dispose();
    selectedAlumns.dispose(); alumnResults.dispose();
  }
}

// ─── AddTutorViewModel ────────────────────────────────────────────────────────
class AddTutorViewModel {
  final AdminRepository _repo = AdminRepository();

  final nombreCtrl      = TextEditingController();
  final apellidoCtrl    = TextEditingController();
  final correoCtrl      = TextEditingController();
  final contrasenaCtrl  = TextEditingController();
  final idRol           = ValueNotifier<int>(2);
  final loading         = ValueNotifier<bool>(false);

  Future<String?> save() async {
    if (nombreCtrl.text.trim().isEmpty || correoCtrl.text.trim().isEmpty || contrasenaCtrl.text.trim().isEmpty) {
      return 'Nombre, correo y contraseña son obligatorios';
    }
    loading.value = true;
    try {
      await _repo.registerExterno(
        nombre:     nombreCtrl.text.trim(),
        apellido:   apellidoCtrl.text.trim(),
        email:      correoCtrl.text.trim(),
        contrasena: contrasenaCtrl.text.trim(),
        idRol:      idRol.value,
      );
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    } finally {
      loading.value = false;
    }
  }

  void dispose() {
    nombreCtrl.dispose(); apellidoCtrl.dispose();
    correoCtrl.dispose(); contrasenaCtrl.dispose();
    idRol.dispose(); loading.dispose();
  }
}

// ─── GetFamilyViewModel ───────────────────────────────────────────────────────
class GetFamilyViewModel {
  final _familyRepo = FamilyRepository();

  List<dynamic>          _allFamilies = [];
  final families  = ValueNotifier<List<dynamic>>([]);
  final isLoading = ValueNotifier<bool>(false);

  Future<void> load() async {
    isLoading.value = true;
    try {
      final data = await _familyRepo.getAvailable();
      _allFamilies   = List<dynamic>.from(data);
      families.value = _allFamilies;
    } finally {
      isLoading.value = false;
    }
  }

  void onSearch(String q) {
    if (q.isEmpty) { families.value = _allFamilies; return; }
    final lower = q.toLowerCase();
    families.value = _allFamilies.where((f) {
      final nombre = (f['nombre_familia'] ?? '').toString().toLowerCase();
      final padres = (f['padres']         ?? '').toString().toLowerCase();
      return nombre.contains(lower) || padres.contains(lower);
    }).toList();
  }

  void dispose() { families.dispose(); isLoading.dispose(); }
}


