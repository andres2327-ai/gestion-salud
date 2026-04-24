import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers.dart';
import '../models/tarjeta_model.dart';
import 'cobrador_tarjeta_detalle_screen.dart';

class CobradorHomeScreen extends ConsumerStatefulWidget {
  const CobradorHomeScreen({super.key});

  @override
  ConsumerState<CobradorHomeScreen> createState() => _CobradorHomeScreenState();
}

class _CobradorHomeScreenState extends ConsumerState<CobradorHomeScreen> {
  List<String> _idsAnteriores = [];

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

  @override
  Widget build(BuildContext context) {
    final perfil = ref.watch(usuarioActualProvider);
    final cobroState = ref.watch(cobroControllerProvider);
    final tarjetasCobrador =
        ref.watch(tarjetaControllerProvider).tarjetasCobrador;
    final fmt = NumberFormat('#,###', 'es_CO');

    if (perfil == null) return const SizedBox();

    final asignaciones = cobroState.asignaciones;

    // Disparar carga de tarjetas cuando cambian las asignaciones
    final ids = asignaciones.map((a) => a.tarjetaId).toList();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sincronizarTarjetas(ids);
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0F1123),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hola,',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      Text(
                        perfil.nombre,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.blueAccent,
                    child: Text(
                      perfil.nombre.isNotEmpty
                          ? perfil.nombre[0].toUpperCase()
                          : 'C',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text(
                    'Mis Cobros',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withAlpha(40),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${asignaciones.length}',
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: cobroState.cargando
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.blueAccent,
                      ),
                    )
                  : asignaciones.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            color: Colors.grey,
                            size: 48,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No tienes tarjetas asignadas',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: asignaciones.length,
                      itemBuilder: (_, i) {
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
                                      builder: (_) =>
                                          CobradorTarjetaDetalleScreen(
                                        tarjeta: tarjeta,
                                        cobradorUid: perfil.uid,
                                      ),
                                    ),
                                  )
                              : null,
                        );
                      },
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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1C3A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  asignacion.nombreCliente as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              if (tarjeta != null) _EstadoBadge(estado: tarjeta!.estado),
            ],
          ),
          if (tarjeta != null) ...[
            const SizedBox(height: 6),
            if (tarjeta!.productos.isNotEmpty)
              Text(
                tarjeta!.productos.map((p) => p.nombreProducto).join(', '),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Saldo: \$${fmt.format(saldo)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                Text(
                  'Total: \$${fmt.format(total)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progreso,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Colors.tealAccent,
                ),
                minHeight: 5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${(progreso * 100).toStringAsFixed(0)}% cobrado · '
              '${tarjeta!.numCuotas} cuotas ${tarjeta!.frecuenciaPago == FrecuenciaPago.diaria ? "diarias" : "semanales"} '
              '· \$${fmt.format(tarjeta!.montoCuota)} c/u',
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ] else
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Cargando datos...',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
        ],
      ),
    ));
  }
}

class _EstadoBadge extends StatelessWidget {
  final EstadoTarjeta estado;
  const _EstadoBadge({required this.estado});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (estado) {
      EstadoTarjeta.activa => ('Activa', Colors.tealAccent),
      EstadoTarjeta.pagada => ('Pagada', Colors.blue),
      EstadoTarjeta.vencida => ('Vencida', Colors.red),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
