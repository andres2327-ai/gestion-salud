import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../core/theme/app_theme.dart';

class AsesoraProductosScreen extends ConsumerStatefulWidget {
  const AsesoraProductosScreen({super.key});

  @override
  ConsumerState<AsesoraProductosScreen> createState() =>
      _AsesoraProductosScreenState();
}

class _AsesoraProductosScreenState
    extends ConsumerState<AsesoraProductosScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final perfil = ref.read(usuarioActualProvider);
      if (perfil != null) {
        ref
            .read(asignacionProductoControllerProvider.notifier)
            .escucharAsignaciones(perfil.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final asigState = ref.watch(asignacionProductoControllerProvider);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final violetColor = isDark ? AppColors.darkViolet : AppColors.violet;
    final violetBg = isDark ? AppColors.darkViolet50 : AppColors.violet50;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Productos Asignados'),
      ),
      body: asigState.cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Resumen badges
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      _StatBadge(
                        label: '${asigState.totalAsignados - asigState.totalVendidos} en stock',
                        color: violetColor,
                        bg: violetBg,
                      ),
                      const SizedBox(width: 10),
                      _StatBadge(
                        label: '${asigState.totalVendidos} vendidos',
                        color: isDark ? AppColors.darkAmber : AppColors.amber,
                        bg: isDark ? AppColors.darkAmber50 : AppColors.amber50,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Lista
                Expanded(
                  child: asigState.asignaciones.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkInk100
                                      : AppColors.lightInk100,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Icon(
                                  Icons.inventory_2_outlined,
                                  color: cs.onSurfaceVariant,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'No tienes productos asignados',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          itemCount: asigState.asignaciones.length,
                          itemBuilder: (_, i) {
                            final a = asigState.asignaciones[i];
                            final disponible = a.cantidadDisponible;
                            final progreso = a.cantidadAsignada > 0
                                ? (a.cantidadVendida / a.cantidadAsignada)
                                    .clamp(0.0, 1.0)
                                : 0.0;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cs.surface,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.darkInk200
                                      : AppColors.lightInk200,
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          a.nombreProducto,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14.5,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '$disponible uds',
                                        style: TextStyle(
                                          color: violetColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(3),
                                    child: LinearProgressIndicator(
                                      value: progreso,
                                      backgroundColor: isDark
                                          ? AppColors.darkInk200
                                          : AppColors.lightInk200,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          violetColor),
                                      minHeight: 4,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Asignados: ${a.cantidadAsignada}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                      Text(
                                        'Vendidos: ${a.cantidadVendida}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;

  const _StatBadge({
    required this.label,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12.5,
        ),
      ),
    );
  }
}
