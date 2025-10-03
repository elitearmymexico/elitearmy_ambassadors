// Elite Ambassadors – perfil.dart
// v0.3.3 (live, sin userRepo)
// - Lee nombre/código/activo desde Firestore (por correo actual).
// - Usa FirebaseAuth solo para conocer el correo logueado.
// - Botón Guardar es solo visual (no persiste) para evitar dependencias a userRepo.
// - Cerrar sesión REAL con FirebaseAuth.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'core/locator.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});
  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _photoCtrl = TextEditingController();
  final _networkNameCtrl = TextEditingController();
  bool _notifications = true;
  bool _saving = false;

  @override
  void dispose() {
    _photoCtrl.dispose();
    _networkNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authUser = FirebaseAuth.instance.currentUser;
    final fallbackName = (authUser?.displayName?.trim().isNotEmpty ?? false)
        ? authUser!.displayName!.trim()
        : (authUser?.email?.split('@').first ?? 'Embajador');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ========= Encabezado (Firestore tiene prioridad) =========
          StreamBuilder<Map<String, dynamic>?>(
            stream: Locator.I.embajadorRepo.streamActual(),
            builder: (context, snap) {
              final d = snap.data;
              final nombreFs = (d?['nombre'] ?? '') as String;
              final rangoFs  = (d?['rango']  ?? '') as String;
              final activo   = (d?['boton'] ?? d?['activo'] ?? false) as bool;

              final nombre = nombreFs.isNotEmpty ? nombreFs : fallbackName;
              final rango  = rangoFs.isNotEmpty ? rangoFs : 'Cabo';

              return Row(
                children: [
                  const CircleAvatar(radius: 36, child: Icon(Icons.person)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nombre,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 18)),
                        const SizedBox(height: 2),
                        Text('Rango: $rango',
                            style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 6),
                        _EstadoChip(
                          activo: activo,
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Estatus mostrado es de lectura (luego se conecta a CrossHero).'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          // ========= Tarjeta: código + copiar =========
          StreamBuilder<Map<String, dynamic>?>(
            stream: Locator.I.embajadorRepo.streamActual(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: LinearProgressIndicator(),
                );
              }
              final d = snap.data;
              if (d == null) {
                return const Text(
                  'No se encontró tu ficha de embajador.',
                  style: TextStyle(color: Colors.white70),
                );
              }

              final codigo = (d['codigo'] ?? d['Codigo'] ?? '') as String;

              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.qr_code_2,
                        size: 20, color: Colors.white70),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        codigo.isEmpty
                            ? 'Sin código asignado'
                            : 'Tu código: $codigo',
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copiar',
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: codigo.isEmpty
                          ? null
                          : () async {
                              await Clipboard.setData(
                                  ClipboardData(text: codigo));
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Código copiado')),
                                );
                              }
                            },
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // ================== Campos cosméticos (no persisten aún) ===================
          TextField(
            controller: _photoCtrl,
            decoration: const InputDecoration(
              labelText: 'URL de foto (solo visual por ahora)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _networkNameCtrl,
            decoration: const InputDecoration(
              labelText: 'Nombre de tu red (cosmético)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          SwitchListTile(
            value: _notifications,
            onChanged: (v) => setState(() => _notifications = v),
            title: const Text('Notificaciones'),
            subtitle: const Text('Solo visual (no persiste)'),
          ),
          const SizedBox(height: 8),

          FilledButton(
            onPressed: _saving
                ? null
                : () async {
                    setState(() => _saving = true);
                    await Future.delayed(const Duration(milliseconds: 400));
                    if (!mounted) return;
                    setState(() => _saving = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Guardado visual. (Luego conectamos persistencia)')),
                    );
                  },
            child: _saving
                ? const SizedBox(
                    height: 20, width: 20, child: CircularProgressIndicator())
                : const Text('Guardar cambios'),
          ),

          const SizedBox(height: 16),

          // ========= Cerrar sesión =========
          OutlinedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesión'),
            onPressed: () async {
              try {
                await FirebaseAuth.instance.signOut();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al cerrar sesión: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

// ────────────────────────── UI helper ──────────────────────────

class _EstadoChip extends StatelessWidget {
  const _EstadoChip({required this.activo, required this.onPressed});

  final bool activo;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final bg = activo ? const Color(0xFF1E7F37) : const Color(0xFF912626);
    final label = activo ? 'Activo' : 'Inactivo';
    final icon = activo ? Icons.check_circle : Icons.cancel;

    return TextButton.icon(
      style: TextButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}
