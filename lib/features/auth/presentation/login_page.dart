import 'package:flutter/material.dart';
import 'auth_viewmodels.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_routes.dart';
import '../../../shared/widgets/app_widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final LoginViewModel _vm = LoginViewModel();
  bool _obscure = true;

  @override
  void dispose() { _vm.dispose(); super.dispose(); }

  Future<void> _login() async {
    final error = await _vm.login();
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), behavior: SnackBarBehavior.floating));
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: ResponsiveContent(
          child: SingleChildScrollView(
            child: Column(children: [
              const Padding(
                padding: EdgeInsets.only(left: 40, right: 40, top: 100),
                child: Image(image: AssetImage('assets/img/logo_edi.png'), width: 225, height: 225),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text('Iniciar Sesión', style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.w400)),
              ),
              _field(controller: _vm.emailCtrl, hint: 'Correo institucional', icon: Icons.person, keyboard: TextInputType.emailAddress),
              _passwordField(),
              _loginButton(),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, AppRoutes.forgotPassword),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text('¿Olvidaste tu contraseña?', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('¿No tienes cuenta?', style: TextStyle(color: Colors.white)),
                  const SizedBox(width: 15),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, AppRoutes.register),
                    child: const Text('Registrarse', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _field({required TextEditingController controller, required String hint, required IconData icon, TextInputType keyboard = TextInputType.text}) =>
    Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.accent, width: 2))),
      child: TextField(
        controller: controller, keyboardType: keyboard,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: Colors.white70), border: InputBorder.none, contentPadding: const EdgeInsets.all(15), prefixIcon: Icon(icon, color: Colors.white)),
      ),
    );

  Widget _passwordField() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.accent, width: 2))),
    child: TextField(
      controller: _vm.passCtrl, obscureText: _obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Contraseña', hintStyle: const TextStyle(color: Colors.white70), border: InputBorder.none, contentPadding: const EdgeInsets.all(15),
        prefixIcon: const Icon(Icons.key, color: Colors.white),
        suffixIcon: IconButton(onPressed: () => setState(() => _obscure = !_obscure), icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off, color: Colors.white)),
      ),
    ),
  );

  Widget _loginButton() => Container(
    width: double.infinity, margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
    child: ValueListenableBuilder<bool>(
      valueListenable: _vm.loading,
      builder: (_, loading, __) => ElevatedButton(
        onPressed: loading ? null : _login,
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), padding: const EdgeInsets.symmetric(vertical: 15)),
        child: loading
            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
            : const Text('INGRESAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
      ),
    ),
  );
}
