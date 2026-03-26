import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'family_viewmodel.dart';
import '../../../shared/models/family.dart';

/// Thin wrapper that delegates to EditFamilyViewModel.
/// Kept so edit_page.dart can call controller.init / controller.saveChanges
/// without changing its internal structure.
class EditController {
  BuildContext? context;
  int? familyId;

  final EditFamilyViewModel _vm = EditFamilyViewModel();

  ValueNotifier<XFile?>  get profileImage         => _vm.profileImage;
  ValueNotifier<XFile?>  get coverImage           => _vm.coverImage;
  ValueNotifier<bool>    get isLoading            => _vm.isLoading;
  TextEditingController  get descripcionCtrl      => _vm.descripcionCtrl;
  ValueNotifier<bool>    get descripcionModificada => _vm.descripcionModificada;

  FamilyModel? get currentFamily => _vm.currentFamily;

  Future<void> init(BuildContext ctx, int fid, void Function(FamilyModel?) onLoaded) async {
    context  = ctx;
    familyId = fid;
    await _vm.init(fid);
    onLoaded(_vm.currentFamily);
  }

  Future<void> selectProfileImage() async {
    if (context == null) return;
    await _vm.selectProfileImage(context!);
  }

  Future<void> selectCoverImage() async {
    if (context == null) return;
    await _vm.selectCoverImage(context!);
  }

  Future<void> saveChanges() async {
    if (familyId == null) return;
    final error = await _vm.saveChanges(familyId!);
    if (!context!.mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context!).showSnackBar(SnackBar(content: Text(error)));
    } else {
      ScaffoldMessenger.of(context!).showSnackBar(const SnackBar(content: Text('¡Cambios guardados con éxito!')));
      Navigator.pop(context!);
    }
  }

  void dispose() => _vm.dispose();
}
