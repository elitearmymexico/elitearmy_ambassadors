// lib/admin_panel/embajadores_admin.dart
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

class EmbajadoresAdminPage extends StatefulWidget {
  const EmbajadoresAdminPage({super.key});

  @override
  State<EmbajadoresAdminPage> createState() => _EmbajadoresAdminPageState();
}

class _EmbajadoresAdminPageState extends State<EmbajadoresAdminPage> {
  // --- Form 1: Crear cuenta (Auth) ---
  final _f1 = GlobalKey<FormState>();
  final _email1 = TextEditingController();
  final _pass1 = TextEditingController();
  final _pass2 = TextEditingController();
  bool _show1 = false;
  bool _show2 = false;
  bool _busy1 = false;
  String? _msg1;

  // --- Form 2: Activar embajador (solo email) ---
  final _f2 = GlobalKey<FormState>();
  final _email2 = TextEditingController();
  bool _busy2 = false;
  String? _msg2;

  @override
  void dispose() {
    _email1.dispose();
    _pass1.dispose();
    _pass2.dispose();
    _email2.dispose();
    super.dispose();
  }

  FirebaseFunctions get _fn =>
      FirebaseFunctions.instanceFor(region: 'us-central1');

  Future<void> _crearCuenta() async {
    if (!_f1.currentState!.validate()) return;
    setState(() {
      _busy1 = true;
      _msg1 = null;
    });
    try {
      final callable = _fn.httpsCallable('createAmbassadorAccount');
      final res = await callable.call(<String, dynamic>{
        'email': _email1.text.trim(),
        'password': _pass1.text,
      });
      setState(() {
        _msg1 = '✅ Cuenta creada: ${res.data}';
      });
    } on FirebaseFunctionsException catch (e) {
      setState(() => _msg1 = '❌ ${e.code}: ${e.message}');
    } catch (e) {
      setState(() => _msg1 = '❌ $e');
    } finally {
      if (mounted) setState(() => _busy1 = false);
    }
  }

  Future<void> _activarEmbajador() async {
    if (!_f2.currentState!.validate()) return;
    setState(() {
      _busy2 = true;
      _msg2 = null;
    });
    try {
      final callable = _fn.httpsCallable('activateAmbassadorByEmail');
      final res = await callable.call(<String, dynamic>{
        'email': _email2.text.trim(),
      });
      setState(() => _msg2 = '✅ Activado: ${res.data}');
    } on FirebaseFunctionsException catch (e) {
      setState(() => _msg2 = '❌ ${e.code}: ${e.message}');
    } catch (e) {
      setState(() => _msg2 = '❌ $e');
    } finally {
      if (mounted) setState(() => _busy2 = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // --------- TARJETA 1: CREAR CUENTA EN AUTH ----------
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _f1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Crear cuenta de embajador (Auth)',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    const Text(
                      'Crea el usuario en Auth y a la vez su ficha en ambassadors_master (con UID).',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _email1,
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
                      controller: _pass1,
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
                      controller: _pass2,
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
                        if (v != _pass1.text) return 'No coincide';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_msg1 != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(_msg1!,
                            style: TextStyle(
                              color: _msg1!.startsWith('✅')
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                            )),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _busy1 ? null : _crearCuenta,
                        icon: _busy1
                            ? const SizedBox(
                                width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
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
        const SizedBox(height: 16),

        // --------- TARJETA 2: ACTIVAR EMBajador ----------
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _f2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Activar embajador por correo',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    const Text(
                      'Crea/actualiza la ficha en ambassadors_master y la deja activa.',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _email2,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Correo',
                        prefixIcon: Icon(Icons.mark_email_read_outlined),
                      ),
                      validator: (v) {
                        final s = v?.trim() ?? '';
                        if (s.isEmpty) return 'Ingresa un correo';
                        if (!s.contains('@')) return 'Correo inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_msg2 != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(_msg2!,
                            style: TextStyle(
                              color: _msg2!.startsWith('✅')
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                            )),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonalIcon(
                        onPressed: _busy2 ? null : _activarEmbajador,
                        icon: _busy2
                            ? const SizedBox(
                                width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.verified_user_outlined),
                        label: const Text('Activar embajador'),
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
