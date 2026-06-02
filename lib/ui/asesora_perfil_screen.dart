import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers.dart';
import '../core/theme/app_theme.dart';

class AsesoraPerfilScreen extends ConsumerWidget {
  const AsesoraPerfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfil = ref.watch(usuarioActualProvider);
    final tarjetaState = ref.watch(tarjetaControllerProvider);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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

    final violetColor = isDark ? AppColors.darkViolet : AppColors.violet;
    final violetBg = isDark ? AppColors.darkViolet50 : AppColors.violet50;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            // Avatar card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.darkInk200 : AppColors.lightInk200,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: violetBg,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          color: violetColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    perfil.nombre,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.01,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Asesora · desde $desde',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoTile(
                          label: 'Ventas',
                          value: '$totalVentas',
                          color: violetColor,
                          bg: violetBg,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoTile(
                          label: 'Total vendido',
                          value: _compactCurrency(totalVendido, fmt),
                          color: violetColor,
                          bg: violetBg,
                          small: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'CUENTA',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: cs.onSurfaceVariant,
                letterSpacing: 0.06,
              ),
            ),
            const SizedBox(height: 10),

            _MenuItem(
              icon: Icons.settings_outlined,
              label: 'Configuración',
              onTap: () {},
              isDark: isDark,
              cs: cs,
            ),
            const SizedBox(height: 8),
            _MenuItem(
              icon: Icons.help_outline,
              label: 'Ayuda y Soporte',
              onTap: () {},
              isDark: isDark,
              cs: cs,
            ),
            const SizedBox(height: 8),
            _MenuItem(
              icon: Icons.logout,
              label: 'Cerrar Sesión',
              color: isDark ? AppColors.darkCoral : AppColors.coral,
              onTap: () => _confirmarCerrarSesion(context, ref),
              isDark: isDark,
              cs: cs,
            ),
          ],
        ),
      ),
    );
  }

  String _compactCurrency(double value, NumberFormat fmt) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    return fmt.format(value);
  }

  Future<void> _confirmarCerrarSesion(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: const Text('Se cerrará tu sesión actual.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Cerrar sesión',
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
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

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bg;
  final bool small;

  const _InfoTile({
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: cs.onSurfaceVariant,
              letterSpacing: 0.04,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: small ? 16 : 22,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: small ? 0 : -0.01,
            ),
            overflow: TextOverflow.ellipsis,
          ),
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
  final bool isDark;
  final ColorScheme cs;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
    required this.cs,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? cs.onSurface;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkInk200 : AppColors.lightInk200,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkInk100 : AppColors.lightInk100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: c, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: c,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: c.withAlpha(80),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
