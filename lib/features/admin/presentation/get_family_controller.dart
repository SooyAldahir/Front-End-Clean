import 'package:flutter/material.dart';
import '../../../features/family/data/family_repository.dart';

/// Thin controller wrapper used by GetFamilyPage and ReportesPage.
/// Delegates data loading to FamilyRepository.
class GetFamilyController {
  final FamilyRepository _repo = FamilyRepository();

  List<dynamic> _allFamilies = [];
  final families  = ValueNotifier<List<dynamic>>([]);
  final isLoading = ValueNotifier<bool>(false);

  late BuildContext context;

  Future<void> init(BuildContext ctx) async {
    context = ctx;
    await loadFamilies();
  }

  Future<void> loadFamilies() async {
    isLoading.value = true;
    try {
      final data = await _repo.getAvailable();
      _allFamilies   = List<dynamic>.from(data);
      families.value = _allFamilies;
    } catch (e) {
      debugPrint('Error cargando familias: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void onSearchChanged(String query) {
    if (query.isEmpty) { families.value = _allFamilies; return; }
    final lower = query.toLowerCase();
    families.value = _allFamilies.where((f) {
      final nombre = (f['nombre_familia'] ?? '').toString().toLowerCase();
      final padres = (f['padres']         ?? '').toString().toLowerCase();
      return nombre.contains(lower) || padres.contains(lower);
    }).toList();
  }

  void goToDetail(dynamic familia) {
    Navigator.pushNamed(context, 'family_detail', arguments: familia['id_familia'] as int?);
  }
}
