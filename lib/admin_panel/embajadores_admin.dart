// lib/admin_panel/embajadores_admin.dart
import 'package:flutter/material.dart';
import 'admin_service.dart'; // servicio que llama a las Cloud Functions

class EmbajadoresAdminPage extends StatefulWidget {
  const EmbajadoresAdminPage({super.key});

  @override
  State<EmbajadoresAdminPage> createState() => _EmbajadoresAdminPageState();
}

class _EmbajadoresAdminPageState extends State<EmbajadoresAdminPage> {
  // --- Form: Crear cuenta (Auth + ficha en ambassadors_master con datos de CrossHero) ---
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _pass1Ctrl = TextEditingController();
  final _pass2Ctrl = TextEditingController();

  bool _show1 = false;
  bool _show2 = false;
  bool _busy = false;
  String? _msg;

  final _svc = AdminService();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pass1Ctrl.dispose();
    _pass2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _crearCuenta() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _msg = null;
    });
    try {
      final out = await _svc.createAmbassador(
        email: _emailCtrl.text.trim(),
        password: _pass1Ctrl.text,
      );
      final email = out['email'] ?? '—';
      final code  = out['code']  ?? '—';
      setState(() => _msg = '✅ Cuenta creada: $email (code: $code)');
    } catch (e) {
      setState(() => _msg = '❌ $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // --------- TARJETA ÚNICA: CREAR CUENTA EN AUTH (y ficha con CrossHero) ----------
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Crear cuenta de embajador (Auth)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Crea el usuario en Auth y, en el mismo paso, genera la ficha en ambassadors_master '
                      'buscando datos en CrossHero (nombre/teléfono).',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Correo del embajador',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (v) {
                        final s = v?.trim() ?? '';
                        if (s.isEmpty) return 'Ingresa un correo';
                        if (!s.contains('@')) return 'Correo inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _pass1Ctrl,
                      obscureText: !_show1,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _show1 = !_show1),
                          icon: Icon(_show1 ? Icons.visibility_off : Icons.visibility),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Ingresa una contraseña';
                        if (v.length < 6) return 'Mínimo 6 caracteres';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _pass2Ctrl,
                      obscureText: !_show2,
                      decoration: InputDecoration(
                        labelText: 'Confirmar contraseña',
                        prefixIcon: const Icon(Icons.lock_reset_outlined),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _show2 = !_show2),
                          icon: Icon(_show2 ? Icons.visibility_off : Icons.visibility),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Confirma la contraseña';
                        if (v != _pass1Ctrl.text) return 'No coincide';
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),
                    if (_msg != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _msg!,
                          style: TextStyle(
                            color: _msg!.startsWith('✅') ? Colors.greenAccent : Colors.redAccent,
                          ),
                        ),
                      ),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _busy ? null : _crearCuenta,
                        icon: _busy
                            ? const SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.person_add_alt_1),
                        label: const Text('Crear cuenta'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
