import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers.dart';
import '../services/initialization_service.dart';
import '../utils/formato_helper.dart';
import 'stat_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardControllerProvider);
    final stats = dashboardState.stats;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1123),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1C3A),
        title: const Text('Dashboard', style: TextStyle(color: Colors.white)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.tealAccent),
            onPressed: () =>
                ref.read(dashboardControllerProvider.notifier).refrescar(),
          ),
        ],
      ),
      body: dashboardState.cargando && stats == null
          ? const Center(
              child: CircularProgressIndicator(color: Colors.tealAccent),
            )
          : dashboardState.error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    dashboardState.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref
                        .read(dashboardControllerProvider.notifier)
                        .refrescar(),
                    child: const Text('Reintentar'),
                  ),
                  const SizedBox(height: 12),
                  if (dashboardState.error!.contains('permission'))
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      onPressed: () async {
                        final initService = InitializationService();
                        try {
                          await initService.inicializarDatos();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Datos inicializados'),
                              ),
                            );
                          }
                          ref
                              .read(dashboardControllerProvider.notifier)
                              .refrescar();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      child: const Text('Inicializar Datos'),
                    ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(dashboardControllerProvider.notifier).refrescar(),
              color: Colors.tealAccent,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 📊 Título
                      const Text(
                        'Resumen del Día',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat(
                          'EEEE, d MMMM yyyy',
                          'es_ES',
                        ).format(DateTime.now()),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 📈 Estadísticas principales
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          StatCard(
                            title: 'Ventas Hoy',
                            value: FormatoHelper.formatearMonto(
                                stats?.ventasHoy ?? 0),
                            icon: Icons.trending_up,
                            iconColor: Colors.green,
                            subtitle:
                                '${stats?.actividadReciente.length ?? 0} transacciones',
                          ),
                          StatCard(
                            title: 'Por Cobrar',
                            value: FormatoHelper.formatearMonto(
                                stats?.montoPendienteTotal ?? 0),
                            icon: Icons.receipt_long,
                            iconColor: Colors.orange,
                            subtitle: 'Saldo pendiente',
                          ),
                          StatCard(
                            title: 'Productos',
                            value: '${stats?.productosEnStock ?? 0}',
                            icon: Icons.inventory_2,
                            iconColor: Colors.blue,
                            subtitle: 'En stock',
                          ),
                          StatCard(
                            title: 'Usuarios',
                            value: '${stats?.asesorasActivas ?? 0}',
                            icon: Icons.people,
                            iconColor: Colors.purple,
                            subtitle: 'Asesoras activas',
                          ),
                          StatCard(
                            title: 'Devoluciones',
                            value: '${stats?.devolucionesHoy ?? 0}',
                            icon: Icons.reply,
                            iconColor: Colors.red,
                            subtitle: 'Hoy',
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // 📝 Actividad Reciente
                      const Text(
                        'Actividad Reciente',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 🎯 Lista de actividades
                      if (stats?.actividadReciente.isEmpty ?? true)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1C3A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              'No hay actividad reciente',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: (stats?.actividadReciente.length ?? 0),
                          separatorBuilder: (_, __) =>
                              const Divider(color: Color(0xFF2A2C4A)),
                          itemBuilder: (context, index) {
                            final actividad =
                                stats?.actividadReciente[index] ?? {};
                            final timestamp = actividad['fecha'] as dynamic;
                            final fecha = timestamp != null
                                ? DateTime.fromMillisecondsSinceEpoch(
                                    timestamp.millisecondsSinceEpoch,
                                  )
                                : null;

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1C3A),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          actividad['descripcion'] ??
                                              'Sin descripción',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${actividad['asesora'] ?? 'Sin asesora'} • ${fecha != null ? DateFormat('HH:mm', 'es_ES').format(fecha) : 'Sin hora'}',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    FormatoHelper.formatearMontoCompleto(
                                        (actividad['monto'] ?? 0).toDouble()),
                                    style: const TextStyle(
                                      color: Colors.tealAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
