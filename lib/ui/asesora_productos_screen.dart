import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';

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

    return Scaffold(
      backgroundColor: const Color(0xFF0F1123),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1C3A),
        title: const Text(
          'Mis Productos Asignados',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: asigState.cargando
          ? const Center(
              child: CircularProgressIndicator(color: Colors.tealAccent),
            )
          : Column(
              children: [
                // Resumen
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _StatBadge(
                        label: '${asigState.totalAsignados - asigState.totalVendidos} en stock',
                        color: Colors.tealAccent,
                      ),
                      const SizedBox(width: 10),
                      _StatBadge(
                        label: '${asigState.totalVendidos} vendidos',
                        color: const Color(0xFF7B5E2A),
                      ),
                    ],
                  ),
                ),

                // Lista
                Expanded(
                  child: asigState.asignaciones.isEmpty
                      ? const Center(
                          child: Text(
                            'No tienes productos asignados',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: asigState.asignaciones.length,
                          itemBuilder: (_, i) {
                            final a = asigState.asignaciones[i];
                            final disponible = a.cantidadDisponible;
                            final progreso = a.cantidadAsignada > 0
                                ? a.cantidadVendida / a.cantidadAsignada
                                : 0.0;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1C3A),
                                borderRadius: BorderRadius.circular(14),
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
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '$disponible uds',
                                        style: const TextStyle(
                                          color: Colors.tealAccent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: progreso.clamp(0.0, 1.0),
                                      backgroundColor: Colors.white12,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                        Colors.tealAccent,
                                      ),
                                      minHeight: 5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Asignados: ${a.cantidadAsignada}',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        'Vendidos: ${a.cantidadVendida}',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
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

  const _StatBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}
