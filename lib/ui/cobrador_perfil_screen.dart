import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers.dart';
import '../core/theme/app_theme.dart';

class CobradorPerfilScreen extends ConsumerWidget {
  const CobradorPerfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfil = ref.watch(usuarioActualProvider);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                      color: isDark ? AppColors.darkJade50 : AppColors.lightJade50,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkJade : AppColors.brandJade,
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
                    'Cobrador · desde $desde',
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
                          label: 'Asignadas',
                          value: '$totalAsignadas',
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoTile(
                          label: 'Teléfono',
                          value: perfil.telefono.isNotEmpty ? perfil.telefono : '—',
                          isDark: isDark,
                          small: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Quincena gradient card ─────────────────────────────
            _QuincenaCard(isDark: isDark),

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

  Future<void> _confirmarCerrarSesion(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
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

class _QuincenaCard extends StatelessWidget {
  final bool isDark;
  const _QuincenaCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    // Compute current quincena period label (1–15 or 16–end of month)
    final now = DateTime.now();
    final isFirstHalf = now.day <= 15;
    final start = isFirstHalf ? 1 : 16;
    final end = isFirstHalf ? 15 : DateUtils.getDaysInMonth(now.year, now.month);
    final daysLeft = end - now.day + 1;
    final daysDone = now.day - start + 1;
    final totalDays = end - start + 1;
    final progress = (daysDone / totalDays).clamp(0.0, 1.0);
    final monthName = const [
      '', 'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ][now.month];

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brandGradStart, AppColors.brandGradEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x471F9DA0),
            blurRadius: 36,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circle
          Positioned(
            right: -40, top: -40,
            child: Container(
              width: 140, height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(15),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'MI QUINCENA · $start → $end $monthName'.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.08,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(46),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '$daysLeft días',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${(progress * 100).toStringAsFixed(0)}% completado · pago el día $end',
                style: TextStyle(
                  fontSize: 11.5,
                  color: Colors.white.withAlpha(230),
                ),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withAlpha(46),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final bool small;

  const _InfoTile({
    required this.label,
    required this.value,
    required this.isDark,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkInk100 : AppColors.lightInk100,
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
              fontSize: small ? 14 : 22,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkJade : AppColors.brandJade,
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
