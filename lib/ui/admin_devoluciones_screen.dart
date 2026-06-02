import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers.dart';
import '../models/tarjeta_model.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_snackbar.dart';
import 'widgets/shared_widgets.dart';

class AdminDevolucionesScreen extends ConsumerStatefulWidget {
  const AdminDevolucionesScreen({super.key});

  @override
  ConsumerState<AdminDevolucionesScreen> createState() =>
      _AdminDevolucionesScreenState();
}

class _AdminDevolucionesScreenState
    extends ConsumerState<AdminDevolucionesScreen> {
  // Tracks which devolution is currently being resolved (per-card loading)
  String? _procesandoId;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(cobroControllerProvider.notifier).escucharDevoluciones(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cobroState = ref.watch(cobroControllerProvider);
    final perfil = ref.watch(usuarioActualProvider);
    final fmt = NumberFormat('#,###', 'es_CO');
    final datefmt = DateFormat('dd/MM/yyyy');
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pendientes = cobroState.devoluciones
        .where((d) => d.estado == EstadoDevolucion.pendiente)
        .toList();
    final resueltas = cobroState.devoluciones
        .where((d) => d.estado != EstadoDevolucion.pendiente)
        .toList();

    // Only show full-screen spinner on the very first load (empty + loading)
    final cargandoInicial = cobroState.cargando && cobroState.devoluciones.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Devoluciones'),
            if (pendientes.isNotEmpty) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkAmber50 : AppColors.amber50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${pendientes.length}',
                  style: TextStyle(
                    color: isDark ? AppColors.darkAmber : AppColors.amber,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      body: cargandoInicial
          ? const Center(child: CircularProgressIndicator())
          : cobroState.devoluciones.isEmpty
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
                          Icons.assignment_return_outlined,
                          color: cs.onSurfaceVariant,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'No hay devoluciones',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (pendientes.isNotEmpty) ...[
                      SectionLabel('PENDIENTES (${pendientes.length})'),
                      const SizedBox(height: 10),
                      ...pendientes.map(
                        (d) => _DevolucionCard(
                          devolucion: d,
                          fmt: fmt,
                          datefmt: datefmt,
                          isDark: isDark,
                          cs: cs,
                          procesando: _procesandoId == d.devolucionId,
                          onAprobar: _procesandoId != null
                              ? null
                              : () => _resolver(d, true, perfil?.uid ?? ''),
                          onRechazar: _procesandoId != null
                              ? null
                              : () => _resolver(d, false, perfil?.uid ?? ''),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (resueltas.isNotEmpty) ...[
                      SectionLabel('HISTORIAL (${resueltas.length})'),
                      const SizedBox(height: 10),
                      ...resueltas.map(
                        (d) => _DevolucionCard(
                          devolucion: d,
                          fmt: fmt,
                          datefmt: datefmt,
                          isDark: isDark,
                          cs: cs,
                        ),
                      ),
                    ],
                  ],
                ),
    );
  }

  Future<void> _resolver(
    DevolucionModel d,
    bool aprobada,
    String adminUid,
  ) async {
    setState(() => _procesandoId = d.devolucionId);

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

    if (!mounted) return;
    setState(() => _procesandoId = null);

    final fmt = NumberFormat('#,###', 'es_CO');
    final msg = ok
        ? aprobada
            ? '\$${fmt.format(d.montoReembolso)} descontados · ${d.nombreCliente}'
            : 'Devolución rechazada'
        : 'Error al procesar la devolución';
    appSnackbar(context, msg, error: !ok);
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _DevolucionCard extends StatelessWidget {
  final DevolucionModel devolucion;
  final NumberFormat fmt;
  final DateFormat datefmt;
  final VoidCallback? onAprobar;
  final VoidCallback? onRechazar;
  final bool isDark;
  final ColorScheme cs;
  final bool procesando;

  const _DevolucionCard({
    required this.devolucion,
    required this.fmt,
    required this.datefmt,
    required this.isDark,
    required this.cs,
    this.onAprobar,
    this.onRechazar,
    this.procesando = false,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = devolucion.estado == EstadoDevolucion.pendiente;

    final (estadoLabel, estadoColor, estadoBg) = switch (devolucion.estado) {
      EstadoDevolucion.pendiente => (
          'Pendiente',
          isDark ? AppColors.darkAmber : AppColors.amber,
          isDark ? AppColors.darkAmber50 : AppColors.amber50,
        ),
      EstadoDevolucion.aprobada => (
          'Aprobada',
          isDark ? AppColors.darkJade : AppColors.brandJade,
          isDark ? AppColors.darkJade50 : AppColors.lightJade50,
        ),
      EstadoDevolucion.rechazada => (
          'Rechazada',
          isDark ? AppColors.darkCoral : AppColors.coral,
          isDark ? AppColors.darkCoral50 : AppColors.coral50,
        ),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: estadoColor.withAlpha(isPending ? 80 : 40),
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
                  devolucion.nombreCliente,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: estadoBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  estadoLabel,
                  style: TextStyle(
                    color: estadoColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            devolucion.nombreProducto,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '${devolucion.cantidadDevuelta} unidad(es) · ',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
              Text(
                '\$${fmt.format(devolucion.montoReembolso)}',
                style: TextStyle(
                  color: isDark ? AppColors.darkJade : AppColors.brandJade,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Motivo: ${devolucion.motivo}',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            datefmt.format(devolucion.fechaDevolucion),
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
          ),
          if (isPending) ...[
            const SizedBox(height: 12),
            procesando
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: isDark ? AppColors.darkJade : AppColors.brandJade,
                        ),
                      ),
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onRechazar,
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                isDark ? AppColors.darkCoral : AppColors.coral,
                            side: BorderSide(
                              color: isDark ? AppColors.darkCoral : AppColors.coral,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
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
                            backgroundColor:
                                isDark ? AppColors.darkJade : AppColors.brandJade,
                            foregroundColor:
                                isDark ? AppColors.darkBg : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
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

