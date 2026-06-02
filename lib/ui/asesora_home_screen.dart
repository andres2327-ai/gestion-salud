import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers.dart';
import '../models/tarjeta_model.dart';
import '../models/usuario_model.dart';
import '../core/theme/app_theme.dart';
import 'asesora_nueva_venta_screen.dart';
import 'asesora_productos_screen.dart';
import 'prestamo_solicitud_screen.dart';

class AsesoraHomeScreen extends ConsumerStatefulWidget {
  const AsesoraHomeScreen({super.key});

  @override
  ConsumerState<AsesoraHomeScreen> createState() => _AsesoraHomeScreenState();
}

class _AsesoraHomeScreenState extends ConsumerState<AsesoraHomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final perfil = ref.read(usuarioActualProvider);
      if (perfil != null) {
        ref
            .read(tarjetaControllerProvider.notifier)
            .cargarTarjetasAsesora(perfil.uid);
        ref
            .read(cobroControllerProvider.notifier)
            .escucharDevolucionesAsesora(perfil.uid);
      }
    });
  }

  Future<void> _mostrarEditarMeta(
    BuildContext context,
    UsuarioModel perfil,
  ) async {
    final cs = Theme.of(context).colorScheme;
    final ctrl = TextEditingController(
      text: perfil.metaMensual.toInt().toString(),
    );

    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Meta mensual'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            prefixText: '\$ ',
            prefixStyle: TextStyle(
              color: cs.primary,
              fontWeight: FontWeight.bold,
            ),
            hintText: '1500000',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final val = double.tryParse(ctrl.text.replaceAll(',', '.'));
              if (val != null && val > 0) Navigator.pop(ctx, val);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result != null && context.mounted) {
      await ref
          .read(usuarioServiceProvider)
          .actualizarUsuario(perfil.uid, {'meta_mensual': result});
      ref.read(authControllerProvider.notifier).actualizarMetaMensual(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final perfil = ref.watch(usuarioActualProvider);
    final tarjetaState = ref.watch(tarjetaControllerProvider);
    final cobroState = ref.watch(cobroControllerProvider);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (perfil == null) return const SizedBox();

    final initials = perfil.nombre
        .split(' ')
        .take(2)
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
        .join();

    final ahora = DateTime.now();

    final totalVentas = tarjetaState.tarjetas
        .where(
          (t) =>
              t.asesoraUid == perfil.uid &&
              t.fechaVenta.month == ahora.month &&
              t.fechaVenta.year == ahora.year,
        )
        .fold<double>(0, (s, t) => s + t.totalVenta);

    final totalDevoluciones = cobroState.devoluciones
        .where(
          (d) =>
              d.asesoraUid == perfil.uid &&
              d.estado == EstadoDevolucion.aprobada &&
              d.fechaDevolucion.month == ahora.month &&
              d.fechaDevolucion.year == ahora.year,
        )
        .fold<double>(0, (s, d) => s + d.montoReembolso);

    final gananciasMes =
        ((totalVentas - totalDevoluciones) * 0.20).clamp(0.0, double.infinity);
    final metaMes = perfil.metaMensual;
    final progreso =
        metaMes > 0 ? (gananciasMes / metaMes).clamp(0.0, 1.0) : 0.0;

    final fmt = NumberFormat('#,###', 'es_CO');

    final violetColor = isDark ? AppColors.darkViolet : AppColors.violet;
    final violetBg = isDark ? AppColors.darkViolet50 : AppColors.violet50;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
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
                            'Hola de nuevo,',
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
                        color: violetBg,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: violetColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Quincena hero card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isDark ? AppColors.darkInk200 : AppColors.lightInk200,
                    ),
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
                      // Radial violet halo
                      Positioned(
                        right: -80, top: -80,
                        child: Container(
                          width: 220, height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [violetColor.withAlpha(30), Colors.transparent],
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
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'QUINCENA EN CURSO',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.08,
                                        color: isDark ? AppColors.darkInk500 : AppColors.lightInk500,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${ahora.day <= 15 ? "1 → 15" : "16 → ${DateUtils.getDaysInMonth(ahora.year, ahora.month)}"} · pago al cierre',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: isDark ? AppColors.darkInk400 : AppColors.lightInk400,
                                      ),
                                    ),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: () => _mostrarEditarMeta(context, perfil),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: violetColor.withAlpha(31),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.calendar_today_outlined, size: 11, color: violetColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Faltan ${ahora.day <= 15 ? 15 - ahora.day + 1 : DateUtils.getDaysInMonth(ahora.year, ahora.month) - ahora.day + 1} días',
                                          style: TextStyle(fontSize: 11, color: violetColor, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              '\$${fmt.format(gananciasMes)}',
                              style: TextStyle(
                                fontSize: 52,
                                fontWeight: FontWeight.w400,
                                letterSpacing: -0.02,
                                color: violetColor,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'comisión acumulada · 20% sobre ventas netas',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.darkInk500 : AppColors.lightInk500,
                              ),
                            ),
                            const SizedBox(height: 18),
                            // Gradient progress bar
                            Stack(
                              children: [
                                Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkInk200 : AppColors.lightInk200,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor: progreso,
                                  child: Container(
                                    height: 8,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [violetColor, AppColors.brandJade],
                                      ),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${(progreso * 100).toStringAsFixed(0)}% completado · meta \$${fmt.format(metaMes)}',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: isDark ? AppColors.darkInk500 : AppColors.lightInk500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'ACCIONES RÁPIDAS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurfaceVariant,
                    letterSpacing: 0.06,
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 10)),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.15,
                ),
                delegate: SliverChildListDelegate([
                  _ActionCard(
                    icon: Icons.shopping_bag_outlined,
                    label: 'Nueva Venta',
                    color: violetColor,
                    tint: violetBg,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AsesoraNuevaVentaScreen(
                          asesoraUid: perfil.uid,
                          asesoraNombre: perfil.nombre,
                        ),
                      ),
                    ),
                    isDark: isDark,
                    cs: cs,
                  ),
                  _ActionCard(
                    icon: Icons.inventory_2_outlined,
                    label: 'Mis Productos',
                    color: isDark ? AppColors.darkAmber : AppColors.amber,
                    tint: isDark ? AppColors.darkAmber50 : AppColors.amber50,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AsesoraProductosScreen(),
                      ),
                    ),
                    isDark: isDark,
                    cs: cs,
                  ),
                  _ActionCard(
                    icon: Icons.bar_chart_outlined,
                    label: 'Mis Ventas',
                    color: isDark ? AppColors.darkSky : AppColors.sky,
                    tint: isDark ? AppColors.darkSky50 : AppColors.sky50,
                    onTap: () {},
                    isDark: isDark,
                    cs: cs,
                  ),
                  _ActionCard(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Solicitar Préstamo',
                    color: isDark ? AppColors.darkJade : AppColors.brandJade,
                    tint: isDark ? AppColors.darkJade50 : AppColors.lightJade50,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PrestamoSolicitudScreen(),
                      ),
                    ),
                    isDark: isDark,
                    cs: cs,
                  ),
                ]),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color tint;
  final VoidCallback onTap;
  final bool isDark;
  final ColorScheme cs;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.tint,
    required this.onTap,
    required this.isDark,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.005,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
