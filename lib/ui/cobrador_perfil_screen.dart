import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers.dart';

class CobradorPerfilScreen extends ConsumerWidget {
  const CobradorPerfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfil = ref.watch(usuarioActualProvider);
    if (perfil == null) return const SizedBox();

    final initials = perfil.nombre
        .split(' ')
        .take(2)
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
        .join();

    final cobroState = ref.watch(cobroControllerProvider);
    final totalAsignadas = cobroState.asignaciones.length;
    final desde = DateFormat('MMM yyyy', 'es_ES').format(perfil.fechaCreacion);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1123),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 20),
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.blueAccent,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: Text(
                perfil.nombre,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Center(
              child: Text(
                'Cobrador desde $desde',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Asignadas',
                    value: '$totalAsignadas',
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _StatCard(
                    label: 'Teléfono',
                    value: perfil.telefono,
                    small: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _MenuItem(
              icon: Icons.settings_outlined,
              label: 'Configuración',
              onTap: () {},
            ),
            const SizedBox(height: 10),
            _MenuItem(
              icon: Icons.help_outline,
              label: 'Ayuda y Soporte',
              onTap: () {},
            ),
            const SizedBox(height: 10),
            _MenuItem(
              icon: Icons.logout,
              label: 'Cerrar Sesión',
              color: Colors.redAccent,
              onTap: () => _confirmarCerrarSesion(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarCerrarSesion(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1C3A),
        title: const Text(
          '¿Cerrar sesión?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(authControllerProvider.notifier).signOut();
    }
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final bool small;

  const _StatCard({
    required this.label,
    required this.value,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1C3A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: Colors.blueAccent,
              fontSize: small ? 16 : 22,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1C3A),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: c, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: c, fontSize: 15),
              ),
            ),
            Icon(Icons.chevron_right, color: c.withAlpha(120), size: 20),
          ],
        ),
      ),
    );
  }
}
