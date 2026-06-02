import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers.dart';
import '../models/tarjeta_model.dart';
import '../core/theme/app_theme.dart';
import 'cobrador_tarjeta_detalle_screen.dart';
import 'prestamo_solicitud_screen.dart';

class CobradorHomeScreen extends ConsumerStatefulWidget {
  const CobradorHomeScreen({super.key});

  @override
  ConsumerState<CobradorHomeScreen> createState() => _CobradorHomeScreenState();
}

class _CobradorHomeScreenState extends ConsumerState<CobradorHomeScreen> {
  List<String> _idsAnteriores = [];
  bool _limpiandoHuerfanas = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final perfil = ref.read(usuarioActualProvider);
      if (perfil != null) {
        ref
            .read(cobroControllerProvider.notifier)
            .escucharAsignacionesCobrador(perfil.uid);
      }
    });
  }

  void _sincronizarTarjetas(List<String> nuevosIds) {
    if (nuevosIds.length == _idsAnteriores.length &&
        nuevosIds.every(_idsAnteriores.contains)) {
      return;
    }
    _idsAnteriores = List.from(nuevosIds);
    ref
        .read(tarjetaControllerProvider.notifier)
        .cargarTarjetasCobrador(nuevosIds);
  }

  Future<void> _limpiarHuerfanas(List<TarjetaModel> tarjetasEncontradas) async {
    if (_limpiandoHuerfanas || !mounted || _idsAnteriores.isEmpty) return;
    final idsEncontradas = tarjetasEncontradas.map((t) => t.tarjetaId).toSet();
    final huerfanos = _idsAnteriores.where((id) => !idsEncontradas.contains(id)).toList();
    if (huerfanos.isEmpty) return;

    _limpiandoHuerfanas = true;
    final asignaciones = ref.read(cobroControllerProvider).asignaciones;
    for (final id in huerfanos) {
      final asig = asignaciones.where((a) => a.tarjetaId == id).firstOrNull;
      if (asig != null) {
        await ref
            .read(cobroControllerProvider.notifier)
            .desactivarAsignacion(asig.asignacionId);
      }
    }
    _limpiandoHuerfanas = false;
  }

  @override
  Widget build(BuildContext context) {
    final perfil = ref.watch(usuarioActualProvider);
    final cobroState = ref.watch(cobroControllerProvider);
    final tarjetasCobrador =
        ref.watch(tarjetaControllerProvider).tarjetasCobrador;
    final fmt = NumberFormat('#,###', 'es_CO');
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (perfil == null) return const SizedBox();

    ref.listen(
      tarjetaControllerProvider.select((s) => s.tarjetasCobrador),
      (_, tarjetas) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _limpiarHuerfanas(tarjetas));
      },
    );

    final asignaciones = cobroState.asignaciones;
    final ids = asignaciones.map((a) => a.tarjetaId).toList();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sincronizarTarjetas(ids));

    final initials = perfil.nombre
        .split(' ')
        .take(2)
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
        .join();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Buenos días,',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                              letterSpacing: 0.06,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            perfil.nombre,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.01,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkJade50 : AppColors.lightJade50,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkJade : AppColors.brandJade,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Hero: Cobros del día ──────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _CobroHeroCard(
                  totalEsperado: asignaciones.fold<double>(
                    0,
                    (sum, a) {
                      final t = tarjetasCobrador
                          .where((t) => t.tarjetaId == a.tarjetaId)
                          .firstOrNull;
                      return sum + (t?.montoCuota ?? 0);
                    },
                  ),
                  pendientes: asignaciones.length,
                  isDark: isDark,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ── Solicitar préstamo ────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PrestamoSolicitudScreen(),
                    ),
                  ),
                  icon: const Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 17,
                  ),
                  label: const Text('Solicitar Préstamo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        isDark ? AppColors.darkJade : AppColors.brandJade,
                    side: BorderSide(
                      color: isDark ? AppColors.darkJade : AppColors.brandJade,
                    ),
                    minimumSize: const Size(double.infinity, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'MIS TARJETAS ACTIVAS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurfaceVariant,
                        letterSpacing: 0.06,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkJade50 : AppColors.lightJade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${asignaciones.length}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkJade : AppColors.brandJade,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            if (cobroState.cargando)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (asignaciones.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkInk100 : AppColors.lightInk100,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          Icons.assignment_outlined,
                          color: cs.onSurfaceVariant,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Sin tarjetas asignadas',
                        style: TextStyle(
                          fontSize: 14,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final asig = asignaciones[i];
                      final tarjeta = tarjetasCobrador
                          .where((t) => t.tarjetaId == asig.tarjetaId)
                          .firstOrNull;
                      return _CobradoCard(
                        asignacion: asig,
                        tarjeta: tarjeta,
                        fmt: fmt,
                        onTap: tarjeta != null
                            ? () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CobradorTarjetaDetalleScreen(
                                      tarjeta: tarjeta,
                                      cobradorUid: perfil.uid,
                                    ),
                                  ),
                                )
                            : null,
                      );
                    },
                    childCount: asignaciones.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _CobradoCard extends StatelessWidget {
  final dynamic asignacion;
  final TarjetaModel? tarjeta;
  final NumberFormat fmt;
  final VoidCallback? onTap;

  const _CobradoCard({
    required this.asignacion,
    required this.tarjeta,
    required this.fmt,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final saldo = tarjeta?.saldoPendiente ?? 0;
    final total = tarjeta?.totalVenta ?? 0;
    final pagado = total - saldo;
    final progreso = total > 0 ? (pagado / total).clamp(0.0, 1.0) : 0.0;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppColors.darkInk200 : AppColors.lightInk200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 40 : 6),
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    asignacion.nombreCliente as String,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.01,
                    ),
                  ),
                ),
                if (tarjeta != null) _EstadoBadge(estado: tarjeta!.estado),
              ],
            ),
            if (tarjeta != null) ...[
              const SizedBox(height: 5),
              if (tarjeta!.productos.isNotEmpty)
                Text(
                  tarjeta!.productos.map((p) => p.nombreProducto).join(', '),
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Saldo \$${fmt.format(saldo)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '\$${fmt.format(total)} total',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progreso,
                  backgroundColor: isDark ? AppColors.darkInk200 : AppColors.lightInk200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? AppColors.darkJade : AppColors.brandJade,
                  ),
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${(progreso * 100).toStringAsFixed(0)}% cobrado · '
                '${tarjeta!.numCuotas} cuotas ${tarjeta!.frecuenciaPago == FrecuenciaPago.diaria ? "diarias" : "semanales"} '
                '· \$${fmt.format(tarjeta!.montoCuota)} c/u',
                style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Cargando datos...',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Hero card: "Cobros del día" ───────────────────────────────────────────────
class _CobroHeroCard extends StatelessWidget {
  final double totalEsperado;
  final int pendientes;
  final bool isDark;

  const _CobroHeroCard({
    required this.totalEsperado,
    required this.pendientes,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final jade = isDark ? AppColors.darkJade : AppColors.brandJade;
    final ink200 = isDark ? AppColors.darkInk200 : AppColors.lightInk200;
    final ink500 = isDark ? AppColors.darkInk500 : AppColors.lightInk500;
    final ink900 = isDark ? AppColors.darkInk900 : AppColors.lightInk900;
    final fmt = NumberFormat('#,###', 'es_CO');

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ink200),
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
          // Left brand gradient ribbon
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
          // Radial jade halo
          Positioned(
            right: -80,
            top: -80,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [jade.withAlpha(30), Colors.transparent],
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
                      'COBROS DEL DÍA',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.08,
                        color: ink500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: jade.withAlpha(31),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6, height: 6,
                            decoration: BoxDecoration(color: jade, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'en ruta',
                            style: TextStyle(fontSize: 11, color: jade, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '\$${fmt.format(totalEsperado.toInt())}',
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.02,
                    color: jade,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'esperados hoy en $pendientes ${pendientes == 1 ? "visita" : "visitas"}',
                  style: TextStyle(fontSize: 12, color: ink500),
                ),
                const SizedBox(height: 16),
                Divider(height: 1, color: ink200),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _MiniStat(label: 'Pendientes', value: '$pendientes', color: ink900, ink200: ink200, ink500: ink500, first: true),
                    _MiniStat(label: 'Cobrados', value: '0', color: jade, ink200: ink200, ink500: ink500, first: false),
                    _MiniStat(label: 'Tasa', value: '0%', color: ink900, ink200: ink200, ink500: ink500, first: false),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color ink200;
  final Color ink500;
  final bool first;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
    required this.ink200,
    required this.ink500,
    required this.first,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          if (!first)
            Container(width: 1, height: 28, color: ink200, margin: const EdgeInsets.only(right: 10)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(fontSize: 10, color: ink500, letterSpacing: 0.08, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(fontSize: 22, color: color, fontWeight: FontWeight.w400, height: 1, letterSpacing: -0.01),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  final EstadoTarjeta estado;
  const _EstadoBadge({required this.estado});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (label, color, bg) = switch (estado) {
      EstadoTarjeta.activa => (
          'Activa',
          isDark ? AppColors.darkJade : AppColors.brandJade,
          isDark ? AppColors.darkJade50 : AppColors.lightJade50,
        ),
      EstadoTarjeta.pagada => (
          'Pagada',
          isDark ? AppColors.darkSky : AppColors.sky,
          isDark ? AppColors.darkSky50 : AppColors.sky50,
        ),
      EstadoTarjeta.vencida => (
          'Vencida',
          isDark ? AppColors.darkCoral : AppColors.coral,
          isDark ? AppColors.darkCoral50 : AppColors.coral50,
        ),
      EstadoTarjeta.atrasada => (
          'Atrasada',
          isDark ? AppColors.darkAmber : AppColors.amber,
          isDark ? AppColors.darkAmber50 : AppColors.amber50,
        ),
      EstadoTarjeta.enDevolucion => (
          'En devolución',
          isDark ? AppColors.darkViolet : AppColors.violet,
          isDark ? AppColors.darkViolet50 : AppColors.violet50,
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
