import 'package:flutter/material.dart';
import 'auth_viewmodels.dart';
import '../../../shared/constants/app_colors.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final ForgotPasswordViewModel _vm = ForgotPasswordViewModel();
  final _confirmCtrl = TextEditingController();
  final _otpCtrls = List.generate(4, (_) => TextEditingController());
  bool _obscure = true, _obscureConfirm = true;

  bool get _min8      => _vm.passCtrl.text.length >= 8;
  bool get _hasUpper  => RegExp(r'[A-Z]').hasMatch(_vm.passCtrl.text);
  bool get _hasNumber => RegExp(r'[0-9]').hasMatch(_vm.passCtrl.text);
  bool get _hasSpec   => RegExp(r'[!"#\$%&/\(\)=\?\.,@]').hasMatch(_vm.passCtrl.text);
  bool get _match     => _vm.passCtrl.text.isNotEmpty && _vm.passCtrl.text == _confirmCtrl.text;
  bool get _allOk     => _min8 && _hasUpper && _hasNumber && _hasSpec && _match;

  @override
  void initState() {
    super.initState();
    _vm.passCtrl.addListener(() { if (mounted) setState(() {}); });
    _confirmCtrl.addListener(() { if (mounted) setState(() {}); });
  }

  @override
  void dispose() { _vm.dispose(); _confirmCtrl.dispose(); for (final c in _otpCtrls) c.dispose(); super.dispose(); }

  void _snack(String msg, {bool error = true}) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: error ? Colors.red : Colors.green),
  );

  final _border = OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.primary,
      appBar: AppBar(title: const Text('Recuperar Contraseña'), backgroundColor: AppColors.primary, elevation: 0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ValueListenableBuilder<int>(
            valueListenable: _vm.step,
            builder: (_, step, __) => SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                if (step == 0) ..._step0(),
                if (step == 1) ..._step1(),
                if (step == 2) ..._step2(),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _step0() => [
    const Text('Ingresa el correo asociado a tu cuenta.', style: TextStyle(color: Colors.white), textAlign: TextAlign.center),
    const SizedBox(height: 20),
    TextField(controller: _vm.emailCtrl, keyboardType: TextInputType.emailAddress, style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(labelText: 'Correo Institucional', labelStyle: const TextStyle(color: Colors.white70), prefixIcon: const Icon(Icons.email, color: Colors.white), border: _border, enabledBorder: _border, focusedBorder: _border.copyWith(borderSide: const BorderSide(color: Colors.white)))),
    const SizedBox(height: 20),
    _actionBtn('Enviar Código', () async {
      final err = await _vm.sendOtp();
      if (err != null && mounted) _snack(err);
    }),
  ];

  List<Widget> _step1() => [
    const Text('Ingresa el código de 4 dígitos enviado a tu correo.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white)),
    const SizedBox(height: 30),
    _otpRow(),
    const SizedBox(height: 20),
    _actionBtn('Verificar', () async {
      final err = await _vm.verifyOtp();
      if (err != null && mounted) _snack(err);
    }),
  ];

  List<Widget> _step2() => [
    const Text('Crea una nueva contraseña segura.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
    const SizedBox(height: 16),
    TextField(controller: _vm.passCtrl, obscureText: _obscure, style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(labelText: 'Nueva contraseña', labelStyle: const TextStyle(color: Colors.white), prefixIcon: const Icon(Icons.lock_outline, color: Colors.white), border: _border, enabledBorder: _border, focusedBorder: _border.copyWith(borderSide: const BorderSide(color: Colors.white)),
        suffixIcon: IconButton(onPressed: () => setState(() => _obscure = !_obscure), icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off, color: Colors.white)))),
    const SizedBox(height: 12),
    TextField(controller: _confirmCtrl, obscureText: _obscureConfirm, style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(labelText: 'Confirmar contraseña', labelStyle: const TextStyle(color: Colors.white), prefixIcon: const Icon(Icons.lock_outline, color: Colors.white), border: _border, enabledBorder: _border, focusedBorder: _border.copyWith(borderSide: const BorderSide(color: Colors.white)),
        suffixIcon: IconButton(onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm), icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off, color: Colors.white)))),
    const SizedBox(height: 14),
    _RequirementCard(items: [
      _ReqItem(ok: _min8,     text: 'Mínimo 8 caracteres'),
      _ReqItem(ok: _hasUpper, text: 'Al menos 1 mayúscula'),
      _ReqItem(ok: _hasNumber,text: 'Al menos 1 número'),
      _ReqItem(ok: _hasSpec,  text: r'Al menos 1 especial: !"#$%&/()=?.,@'),
      _ReqItem(ok: _match,    text: 'Las contraseñas coinciden'),
    ]),
    const SizedBox(height: 18),
    ValueListenableBuilder<bool>(
      valueListenable: _vm.loading,
      builder: (_, loading, __) {
        final disabled = loading || !_allOk;
        return SizedBox(width: double.infinity, height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: disabled ? Colors.grey.shade300 : AppColors.accent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: disabled ? null : () async {
              final err = await _vm.updatePassword();
              if (!mounted) return;
              if (err != null) { _snack(err); return; }
              _snack('Contraseña actualizada con éxito', error: false);
              Navigator.pop(context);
            },
            child: loading ? const CircularProgressIndicator(color: Colors.white) : Text('Actualizar contraseña', style: TextStyle(color: disabled ? Colors.black54 : Colors.black, fontWeight: FontWeight.bold)),
          ),
        );
      },
    ),
  ];

  Widget _actionBtn(String text, VoidCallback onPressed) => ValueListenableBuilder<bool>(
    valueListenable: _vm.loading,
    builder: (_, loading, __) => SizedBox(width: double.infinity, height: 54,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        child: loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black)) : Text(text, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    ),
  );

  Widget _otpRow() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: List.generate(4, (i) => SizedBox(width: 60, height: 60,
      child: TextField(
        controller: _otpCtrls[i], autofocus: i == 0, keyboardType: TextInputType.number, textAlign: TextAlign.center, maxLength: 1,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        decoration: InputDecoration(counterText: '', contentPadding: const EdgeInsets.symmetric(vertical: 10),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accent, width: 2)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accent, width: 2))),
        onChanged: (v) {
          if (v.length == 1 && i < 3) FocusScope.of(context).nextFocus();
          else if (v.isEmpty && i > 0) FocusScope.of(context).previousFocus();
          _vm.otpCtrl.text = _otpCtrls.map((c) => c.text).join();
          if (_vm.otpCtrl.text.length == 4) { FocusScope.of(context).unfocus(); _vm.verifyOtp().then((e) { if (e != null && mounted) _snack(e); }); }
        },
      ),
    )),
  );
}

class _ReqItem { final bool ok; final String text; const _ReqItem({required this.ok, required this.text}); }

class _RequirementCard extends StatelessWidget {
  final List<_ReqItem> items;
  const _RequirementCard({required this.items});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.primary)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: items.map((it) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(it.ok ? Icons.check_circle : Icons.cancel, size: 18, color: it.ok ? Colors.green : Colors.red),
        const SizedBox(width: 8),
        Expanded(child: Text(it.text, style: TextStyle(color: it.ok ? Colors.green.shade700 : Colors.red.shade700, fontWeight: FontWeight.w600, fontSize: 13))),
      ]),
    )).toList()),
  );
}
