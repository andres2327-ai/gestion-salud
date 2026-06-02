import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers.dart';
import '../utils/formato_helper.dart';
import '../core/theme/app_theme.dart';
import 'stat_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardControllerProvider);
    final stats = dashboardState.stats;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: dashboardState.cargando && stats == null
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : dashboardState.error != null
          ? _ErrorState(
              error: dashboardState.error!,
              onRetry: () =>
                  ref.read(dashboardControllerProvider.notifier).refrescar(),
            )
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(dashboardControllerProvider.notifier).refrescar(),
              color: cs.primary,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 52, 22, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Brand + title
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _BrandMark(),
                              const SizedBox(height: 16),
                              Text.rich(
                                TextSpan(
                                  text: 'Resumen del ',
                                  style: tt.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.015,
                                  ),
                                  children: const [
                                    TextSpan(
                                      text: 'día',
                                      style: TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.w400),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today_outlined, size: 12, color: cs.onSurfaceVariant),
                                  const SizedBox(width: 5),
                                  Text(
                                    DateFormat('EEEE d MMMM · y', 'es_ES').format(DateTime.now()),
                                    style: tt.bodySmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          // Avatar admin + refresh
                          Column(
                            children: [
                              _QSAvatar(
                                initial: 'A',
                                color: isDark ? AppColors.darkInk900 : AppColors.lightInk900,
                                size: 44,
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => ref.read(dashboardControllerProvider.notifier).refrescar(),
                                child: Icon(Icons.refresh_outlined, size: 18, color: cs.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Hero KPI card ──────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: _HeroCard(
                        label: 'Por cobrar · activo',
                        pill: '+8.2%',
                        bigValue: FormatoHelper.formatearMonto(stats?.montoPendienteTotal ?? 0),
                        sub: '${stats?.actividadReciente.length ?? 0} transacciones',
                        miniStats: [
                          _MiniStat('Hoy', FormatoHelper.formatearMonto(stats?.ventasHoy ?? 0)),
                          _MiniStat('Pendiente', FormatoHelper.formatearMonto(stats?.montoPendienteTotal ?? 0)),
                          _MiniStat('Devuelto', '\$0'),
                        ],
                        accentColor: cs.primary,
                        isDark: isDark,
                      ),
                    ),
                  ),

                  // ── KPI grid ──────────────────────────────────────────
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    sliver: SliverGrid.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.2,
                      children: [
                        StatCard(
                          title: 'Ventas hoy',
                          value: FormatoHelper.formatearMonto(stats?.ventasHoy ?? 0),
                          icon: Icons.trending_up_rounded,
                          iconColor: AppColors.brandJade,
                          subtitle: '${stats?.actividadReciente.length ?? 0} transacciones',
                        ),
                        StatCard(
                          title: 'Productos',
                          value: '${stats?.productosEnStock ?? 0}',
                          icon: Icons.inventory_2_outlined,
                          iconColor: AppColors.sky,
                          subtitle: 'En stock',
                          alert: (stats?.productosEnStock ?? 0) < 5,
                        ),
                        StatCard(
                          title: 'Asesoras',
                          value: '${stats?.asesorasActivas ?? 0}',
                          icon: Icons.people_alt_outlined,
                          iconColor: AppColors.violet,
                          subtitle: 'Activas',
                        ),
                        StatCard(
                          title: 'Devoluciones',
                          value: '${stats?.devolucionesHoy ?? 0}',
                          icon: Icons.assignment_return_outlined,
                          iconColor: AppColors.coral,
                          subtitle: 'Hoy',
                        ),
                      ],
                    ),
                  ),

                  // ── Actividad reciente ─────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 24, 22, 10),
                      child: Text(
                        'ACTIVIDAD RECIENTE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurfaceVariant,
                          letterSpacing: 0.08,
                        ),
                      ),
                    ),
                  ),

                  if (stats?.actividadReciente.isEmpty ?? true)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: cs.outline),
                          ),
                          child: Text(
                            'No hay actividad reciente',
                            style: tt.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList.separated(
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemCount: stats?.actividadReciente.length ?? 0,
                        itemBuilder: (context, index) {
                          final actividad = stats?.actividadReciente[index] ?? {};
                          final timestamp = actividad['fecha'] as dynamic;
                          final fecha = timestamp != null
                              ? DateTime.fromMillisecondsSinceEpoch(
                                  timestamp.millisecondsSinceEpoch)
                              : null;
                          return _ActivityRow(
                            title: actividad['descripcion'] ?? 'Sin descripción',
                            sub:
                                '${actividad['asesora'] ?? ''} · ${fecha != null ? DateFormat('HH:mm').format(fecha) : ''}',
                            amount: FormatoHelper.formatearMontoCompleto(
                                (actividad['monto'] ?? 0).toDouble()),
                            cs: cs,
                          );
                        },
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _BrandMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Image.asset(
          'assets/images/logo.png',
          width: 26,
          height: 26,
          errorBuilder: (_, _, _) =>
              Icon(Icons.favorite_rounded, color: cs.primary, size: 22),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'quiero',
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: cs.onSurface,
                height: 1,
              ),
            ),
            Text(
              'SALUD',
              style: TextStyle(
                fontSize: 7,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.18,
                color: cs.onSurfaceVariant,
                height: 1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniStat {
  final String label;
  final String value;
  const _MiniStat(this.label, this.value);
}

class _HeroCard extends StatelessWidget {
  final String label;
  final String pill;
  final String bigValue;
  final String sub;
  final List<_MiniStat> miniStats;
  final Color accentColor;
  final bool isDark;

  const _HeroCard({
    required this.label,
    required this.pill,
    required this.bigValue,
    required this.sub,
    required this.miniStats,
    required this.accentColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cs.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 50 : 5),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Stack(
        children: [
          // left brand gradient ribbon
          Positioned(
            left: 0, top: 0, bottom: 0,
            child: Container(
              width: 6,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.brandGradStart, AppColors.brandGradEnd],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(22),
                  bottomLeft: Radius.circular(22),
                ),
              ),
            ),
          ),
          // radial glow
          Positioned(
            right: -60,
            top: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [accentColor.withAlpha(30), Colors.transparent],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.08,
                        color: AppColors.lightInk500,
                      ),
                    ),
                    _Pill(label: pill, color: AppColors.brandJade),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  bigValue,
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.02,
                    color: accentColor,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(sub, style: const TextStyle(fontSize: 12, color: AppColors.lightInk500)),
                const SizedBox(height: 16),
                Divider(height: 1, color: cs.outline),
                const SizedBox(height: 12),
                Row(
                  children: List.generate(miniStats.length, (i) {
                    return Expanded(
                      child: Row(
                        children: [
                          if (i > 0) Container(width: 1, height: 28, color: cs.outline, margin: const EdgeInsets.only(right: 10)),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                miniStats[i].label.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.lightInk500,
                                  letterSpacing: 0.1,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                miniStats[i].value,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.01,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;

  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.trending_up, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _QSAvatar extends StatelessWidget {
  final String initial;
  final Color color;
  final double size;

  const _QSAvatar({required this.initial, required this.color, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withAlpha(50), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Center(
        child: Text(
          initial.toUpperCase(),
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final String title;
  final String sub;
  final String amount;
  final ColorScheme cs;

  const _ActivityRow({required this.title, required this.sub, required this.amount, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(sub, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            amount,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: cs.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: cs.error, size: 48),
            const SizedBox(height: 16),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
