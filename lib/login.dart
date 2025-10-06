// Elite Ambassadors – login.dart
// Version: v0.3.1
// - Conecta login real a FirebaseAuth (sin navegación manual; AuthGate decide)

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 👈 NUEVO

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _LogoMarca(),
                  const SizedBox(height: 32),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _Input(
                          label: 'Email',
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Ingresa tu email';
                            final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v);
                            if (!ok) return 'Email no válido';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _Input(
                          label: 'Password',
                          controller: _passCtrl,
                          obscureText: _obscure,
                          suffix: IconButton(
                            onPressed: () => setState(() => _obscure = !_obscure),
                            icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: Colors.white54),
                          ),
                          validator: (v) => (v == null || v.isEmpty) ? 'Ingresa tu contraseña' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _loading ? null : _onForgotPass, // 👈 CAMBIO (antes demo)
                      child: const Text('Forgot password?'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFBF0A30),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      ),
                      onPressed: _loading ? null : _onLogin, // 👈 CAMBIO (ahora login real)
                      child: _loading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator())
                          : const Text('LOG IN', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final email = _emailCtrl.text.trim();
      final pass  = _passCtrl.text;

      // 👇 NUEVO: Autenticación REAL con Firebase
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pass,
      );

      // ✅ SIN Navigator: el AuthGate en main.dart detecta el user y muestra el dashboard.

    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'invalid-credential' || 'wrong-password' => 'Correo o contraseña incorrectos.',
        'user-not-found' => 'No existe una cuenta con este correo.',
        'too-many-requests' => 'Demasiados intentos. Intenta de nuevo más tarde.',
        'network-request-failed' => 'Sin conexión. Revisa tu internet.',
        _ => 'No se pudo iniciar sesión (${e.code}).'
      };
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error inesperado al iniciar sesión.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onForgotPass() async { // 👈 NUEVO
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe tu email para recuperar la contraseña')),
      );
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Te enviamos un correo para restablecer la contraseña.')),
        );
      }
    } on FirebaseAuthException catch (e) {
      final msg = (e.code == 'user-not-found')
          ? 'No existe una cuenta con ese correo.'
          : 'No se pudo enviar el correo (${e.code}).';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error inesperado.')),
        );
      }
    }
  }
}

class _LogoMarca extends StatelessWidget {
  const _LogoMarca();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tu logo. Si no lo encuentra, muestra un ícono.
        Image.asset(
          'assets/images/logo.png',
          height: 96,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.military_tech, color: Colors.white, size: 64),
        ),
        const SizedBox(height: 12),
        const Text(
          'ELITE ARMY',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _Input extends StatelessWidget {
  const _Input({
    required this.label,
    required this.controller,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.suffix,
  });

  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF111111),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Colors.white24)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Colors.white24)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Colors.white54)),
        suffixIcon: suffix,
      ),
    );
  }
}
