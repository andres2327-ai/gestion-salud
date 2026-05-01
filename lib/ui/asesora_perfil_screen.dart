import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers.dart';

class AsesoraPerfilScreen extends ConsumerWidget {
  const AsesoraPerfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfil = ref.watch(usuarioActualProvider);
    final tarjetaState = ref.watch(tarjetaControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (perfil == null) return const SizedBox();

    final initials = perfil.nombre
        .split(' ')
        .take(2)
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
        .join();

    final totalVentas = tarjetaState.tarjetas
        .where((t) => t.asesoraUid == perfil.uid)
        .length;
    final totalVendido = tarjetaState.tarjetas
        .where((t) => t.asesoraUid == perfil.uid)
        .fold<double>(0, (s, t) => s + t.totalVenta);

    final fmt = NumberFormat('#,###', 'es_CO');
    final desde = DateFormat('MMM yyyy', 'es_ES').format(perfil.fechaCreacion);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 20),

            // Avatar
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: colorScheme.primaryContainer,
                child: Text(
                  initials,
                  style: TextStyle(
                    color: colorScheme.onPrimaryContainer,
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
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Center(
              child: Text(
                'Asesora desde $desde',
                style: textTheme.bodySmall,
              ),
            ),

            const SizedBox(height: 24),

            // Stats
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Ventas',
                    value: '$totalVentas',
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _StatCard(
                    label: 'Vendido',
                    value: '\$${_compactCurrency(totalVendido, fmt)}',
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
              color: colorScheme.error,
              onTap: () => _confirmarCerrarSesion(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  String _compactCurrency(double value, NumberFormat fmt) {
    if (value >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(1)}M';
    }
    return fmt.format(value);
  }

  Future<void> _confirmarCerrarSesion(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: const Text('Se cerrará tu sesión actual.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Cerrar sesión',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
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

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final cardColor =
        Theme.of(context).cardTheme.color ?? colorScheme.surface;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: textTheme.titleLarge?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: textTheme.bodySmall),
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final c = color ?? colorScheme.onSurface;
    final cardColor =
        Theme.of(context).cardTheme.color ?? colorScheme.surface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: c, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: textTheme.bodyLarge?.copyWith(
                  color: c,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: c.withValues(alpha: 0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
