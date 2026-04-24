import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers.dart';
import '../models/tarjeta_model.dart';

class AdminDevolucionesScreen extends ConsumerStatefulWidget {
  const AdminDevolucionesScreen({super.key});

  @override
  ConsumerState<AdminDevolucionesScreen> createState() =>
      _AdminDevolucionesScreenState();
}

class _AdminDevolucionesScreenState
    extends ConsumerState<AdminDevolucionesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(cobroControllerProvider.notifier).escucharDevoluciones();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cobroState = ref.watch(cobroControllerProvider);
    final perfil = ref.watch(usuarioActualProvider);
    final fmt = NumberFormat('#,###', 'es_CO');
    final datefmt = DateFormat('dd/MM/yyyy');

    final pendientes = cobroState.devoluciones
        .where((d) => d.estado == EstadoDevolucion.pendiente)
        .toList();
    final resueltas = cobroState.devoluciones
        .where((d) => d.estado != EstadoDevolucion.pendiente)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F1123),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1C3A),
        title: Row(
          children: [
            const Text(
              'Devoluciones',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (pendientes.isNotEmpty) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(40),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${pendientes.length}',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        elevation: 0,
      ),
      body: cobroState.cargando
          ? const Center(
              child: CircularProgressIndicator(color: Colors.tealAccent),
            )
          : cobroState.devoluciones.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.assignment_return_outlined,
                    color: Colors.grey,
                    size: 48,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No hay devoluciones',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (pendientes.isNotEmpty) ...[
                  _SectionLabel('PENDIENTES (${pendientes.length})'),
                  const SizedBox(height: 8),
                  ...pendientes.map(
                    (d) => _DevolucionCard(
                      devolucion: d,
                      fmt: fmt,
                      datefmt: datefmt,
                      onAprobar: () =>
                          _resolver(context, d, true, perfil?.uid ?? ''),
                      onRechazar: () =>
                          _resolver(context, d, false, perfil?.uid ?? ''),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                if (resueltas.isNotEmpty) ...[
                  _SectionLabel('HISTORIAL (${resueltas.length})'),
                  const SizedBox(height: 8),
                  ...resueltas.map(
                    (d) => _DevolucionCard(
                      devolucion: d,
                      fmt: fmt,
                      datefmt: datefmt,
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Future<void> _resolver(
    BuildContext context,
    DevolucionModel d,
    bool aprobada,
    String adminUid,
  ) async {
    final ok = await ref
        .read(cobroControllerProvider.notifier)
        .resolverDevolucion(
          devolucionId: d.devolucionId,
          tarjetaId: d.tarjetaId,
          asesoraUid: d.asesoraUid,
          adminUid: adminUid,
          aprobada: aprobada,
          montoReembolso: d.montoReembolso,
          cantidadDevuelta: d.cantidadDevuelta,
          codigoBarrasProducto: d.codigoBarras,
        );

    if (context.mounted) {
      final fmt = NumberFormat('#,###', 'es_CO');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? aprobada
                    ? '\$${fmt.format(d.montoReembolso)} descontados de la tarjeta de ${d.nombreCliente}'
                    : 'Devolución rechazada'
                : 'Error al procesar la devolución',
          ),
          backgroundColor:
              ok ? (aprobada ? Colors.green : Colors.orange) : Colors.red,
        ),
      );
    }
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _DevolucionCard extends StatelessWidget {
  final DevolucionModel devolucion;
  final NumberFormat fmt;
  final DateFormat datefmt;
  final VoidCallback? onAprobar;
  final VoidCallback? onRechazar;

  const _DevolucionCard({
    required this.devolucion,
    required this.fmt,
    required this.datefmt,
    this.onAprobar,
    this.onRechazar,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = devolucion.estado == EstadoDevolucion.pendiente;

    final (estadoLabel, estadoColor) = switch (devolucion.estado) {
      EstadoDevolucion.pendiente => ('Pendiente', Colors.orange),
      EstadoDevolucion.aprobada => ('Aprobada', Colors.green),
      EstadoDevolucion.rechazada => ('Rechazada', Colors.red),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1C3A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: estadoColor.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  devolucion.nombreCliente,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: estadoColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  estadoLabel,
                  style: TextStyle(
                    color: estadoColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            devolucion.nombreProducto,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '${devolucion.cantidadDevuelta} unidad(es) · ',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                '\$${fmt.format(devolucion.montoReembolso)}',
                style: const TextStyle(
                  color: Colors.tealAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Motivo: ${devolucion.motivo}',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            datefmt.format(devolucion.fechaDevolucion),
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
          if (isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onRechazar,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Rechazar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAprobar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.tealAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Aprobar'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.tealAccent,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}
