// Elite Ambassadors – perfil.dart
// Version: v0.2.0
// - v0.2.0: Perfil con foto por URL, nombre de red y notificaciones (mock).

import 'package:flutter/material.dart';
import 'core/locator.dart';
import 'core/models.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});
  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  late Future<UserSummary> _future;
  final _photoCtrl = TextEditingController();
  final _networkNameCtrl = TextEditingController();
  bool _notifications = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _future = Locator.I.userRepo.getSummary().then((u) {
      _photoCtrl.text = u.photoUrl ?? '';
      _networkNameCtrl.text = u.networkName ?? '';
      _notifications = u.notificationsEnabled;
      return u;
    });
  }

  @override
  void dispose() {
    _photoCtrl.dispose();
    _networkNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserSummary>(
      future: _future,
      builder: (c, s) {
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        final u = s.data!;
        final avatar = u.photoUrl != null && u.photoUrl!.isNotEmpty
            ? CircleAvatar(radius: 36, backgroundImage: NetworkImage(u.photoUrl!))
            : const CircleAvatar(radius: 36, child: Icon(Icons.person));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              avatar,
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(u.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                Text('Rango: ${u.rank}', style: const TextStyle(color: Colors.grey)),
              ])),
            ]),
            const SizedBox(height: 16),

            // URL de foto
            TextField(
              controller: _photoCtrl,
              decoration: const InputDecoration(
                labelText: 'URL de foto (temporal, sin subir archivo)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Nombre de la red (cosmético)
            TextField(
              controller: _networkNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre de tu red (cosmético)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Notificaciones
            SwitchListTile(
              value: _notifications,
              onChanged: (v) => setState(() => _notifications = v),
              title: const Text('Notificaciones'),
              subtitle: const Text('Activa/desactiva avisos en la app'),
            ),
            const SizedBox(height: 8),

            // Acciones
            FilledButton(
              onPressed: _saving ? null : () async {
                setState(() => _saving = true);
                await Locator.I.userRepo.updatePhotoUrl(_photoCtrl.text.trim());
                await Locator.I.userRepo.updateNetworkName(_networkNameCtrl.text.trim());
                await Locator.I.userRepo.updateNotifications(_notifications);
                final refreshed = await Locator.I.userRepo.getSummary();
                if (!mounted) return;
                setState(() {
                  _future = Future.value(refreshed);
                  _saving = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil actualizado')));
              },
              child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator()) : const Text('Guardar cambios'),
            ),

            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cerrar sesión (demo)'))),
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar sesión'),
            ),
          ]),
        );
      },
    );
  }
}
