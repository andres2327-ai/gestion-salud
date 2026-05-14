// lib/ui/cobrador_cierre_dia_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers.dart';
import '../models/tarjeta_model.dart';
import '../models/comision_model.dart';
import '../services/comision_service.dart';

class CobradorCierreDiaScreen extends ConsumerStatefulWidget {
  const CobradorCierreDiaScreen({super.key});

  @override
  ConsumerState<CobradorCierreDiaScreen> createState() =>
      _CobradorCierreDiaScreenState();
}

class _CobradorCierreDiaScreenState
    extends ConsumerState<CobradorCierreDiaScreen> {
  // For each tarjeta: null = not visited, true = collected, false = skipped
  final Map<String, bool?> _resultados = {};
  final Map<String, String> _motivos = {};
  bool _cargando = false;
  List<ComisionModel> _comisionesHoy = [];

  final fmt = NumberFormat('#,###', 'es_CO');
  final datefmt = DateFormat('dd/MM/yyyy', 'es_ES');

  @override
  void initState() {
    super.initState();
    Future.microtask(_cargarComisiones);
  }

  Future<void> _cargarComisiones() async {
    final perfil = ref.read(usuarioActualProvider);
    if (perfil == null) return;
    setState(() => _cargando = true);
    final lista = await ref
        .read(comisionControllerProvider.notifier)
        .cargarQuincenaActual(perfil.uid);
    // Filter to today only
    final hoy = DateTime.now();
    setState(() {
      _comisionesHoy = lista.where((c) {
        return c.fecha.year == hoy.year &&
            c.fecha.month == hoy.month &&
            c.fecha.day == hoy.day;
      }).toList();
      _cargando = false;
    });
  }

  void _marcarResultado(String tarjetaId, bool cobrado) {
    setState(() => _resultados[tarjetaId] = cobrado);
    if (!cobrado && !_motivos.containsKey(tarjetaId)) {
      _pedirMotivo(tarjetaId);
    }
  }

  void _pedirMotivo(String tarjetaId) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Motivo de no cobro'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: 'Ej: Cliente ausente, no tenía efectivo...',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _motivos[tarjetaId] = ctrl.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  double get _totalCobradoHoy {
    return _comisionesHoy.fold(0.0, (s, c) => s + c.montoBase);
  }

  double get _totalComisionHoy {
    return _comisionesHoy.fold(0.0, (s, c) => s + c.montoComision);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final tarjetasCobrador =
        ref.watch(tarjetaControllerProvider).tarjetasCobrador;
    final asignaciones = ref.watch(cobroControllerProvider).asignaciones;

    final cobradas = _resultados.entries
        .where((e) => e.value == true)
        .map((e) => e.key)
        .toSet();
    final noCobradas = _resultados.entries
        .where((e) => e.value == false)
        .map((e) => e.key)
        .toSet();
    final sinVisitar = asignaciones
        .where((a) => !_resultados.containsKey(a.tarjetaId))
        .length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cierre del Día',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarComisiones,
          ),
        ],
      ),
      body: _cargando
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : Column(
              children: [
                // Summary cards
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _SummaryCard(
                        label: 'Cobradas',
                        value: '${cobradas.length}',
                        color: Colors.green,
                        icon: Icons.check_circle_outline,
                      ),
                      const SizedBox(width: 10),
                      _SummaryCard(
                        label: 'Sin cobrar',
                        value: '${noCobradas.length}',
                        color: Colors.red,
                        icon: Icons.cancel_outlined,
                      ),
                      const SizedBox(width: 10),
                      _SummaryCard(
                        label: 'Sin visitar',
                        value: '$sinVisitar',
                        color: Colors.grey,
                        icon: Icons.pending_outlined,
                      ),
                    ],
                  ),
                ),

                // Commission summary
                if (_comisionesHoy.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.attach_money, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Cobrado hoy: \$${fmt.format(_totalCobradoHoy)}',
                                  style: textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w600)),
                              Text(
                                  'Tu comisión (20%): \$${fmt.format(_totalComisionHoy)}',
                                  style: textTheme.bodySmall
                                      ?.copyWith(color: colorScheme.primary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'MIS TARJETAS DE HOY',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                Expanded(
                  child: asignaciones.isEmpty
                      ? Center(
                          child: Text('No tienes tarjetas asignadas',
                              style: textTheme.bodyMedium),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: asignaciones.length,
                          itemBuilder: (_, i) {
                            final asig = asignaciones[i];
                            final tarjeta = tarjetasCobrador
                                .where(
                                    (t) => t.tarjetaId == asig.tarjetaId)
                                .firstOrNull;
                            final resultado = _resultados[asig.tarjetaId];
                            final motivo = _motivos[asig.tarjetaId];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: resultado == null
                                    ? Theme.of(context).cardTheme.color
                                    : resultado
                                        ? Colors.green.withValues(alpha: 0.08)
                                        : Colors.red.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: resultado == null
                                    ? null
                                    : Border.all(
                                        color: resultado
                                            ? Colors.green.withValues(alpha: 0.4)
                                            : Colors.red.withValues(alpha: 0.4),
                                      ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          asig.nombreCliente,
                                          style: textTheme.bodyLarge?.copyWith(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      if (tarjeta != null)
                                        Text(
                                          '\$${fmt.format(tarjeta.montoCuota)}',
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (tarjeta != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Saldo: \$${fmt.format(tarjeta.saldoPendiente)}',
                                      style: textTheme.bodySmall,
                                    ),
                                  ],
                                  if (motivo != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        'Motivo: $motivo',
                                        style: textTheme.bodySmall?.copyWith(
                                            color: Colors.red),
                                      ),
                                    ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: resultado == false
                                              ? null
                                              : () => _marcarResultado(
                                                  asig.tarjetaId, false),
                                          icon: const Icon(Icons.close, size: 16),
                                          label: const Text('No cobrado'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red,
                                            side: BorderSide(
                                              color: resultado == false
                                                  ? Colors.red
                                                  : Colors.grey,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: resultado == true
                                              ? null
                                              : () => _marcarResultado(
                                                  asig.tarjetaId, true),
                                          icon: const Icon(Icons.check, size: 16),
                                          label: const Text('Cobrado'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
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

                // Submit report button
                if (asignaciones.isNotEmpty && sinVisitar == 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _mostrarResumenFinal(
                            cobradas, noCobradas, tarjetasCobrador),
                        icon: const Icon(Icons.summarize_outlined, size: 18),
                        label: const Text('Ver Resumen del Día'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  void _mostrarResumenFinal(
    Set<String> cobradas,
    Set<String> noCobradas,
    List<TarjetaModel> tarjetas,
  ) {
    final fmt2 = NumberFormat('#,###', 'es_CO');
    double totalCobrado = 0;
    for (final id in cobradas) {
      final t = tarjetas.where((x) => x.tarjetaId == id).firstOrNull;
      if (t != null) totalCobrado += t.montoCuota;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resumen del Día'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ResumenRow(
              icon: Icons.check_circle,
              color: Colors.green,
              label: 'Cobradas',
              value: '${cobradas.length} tarjetas',
            ),
            _ResumenRow(
              icon: Icons.cancel,
              color: Colors.red,
              label: 'Sin cobrar',
              value: '${noCobradas.length} tarjetas',
            ),
            const Divider(),
            _ResumenRow(
              icon: Icons.attach_money,
              color: Colors.teal,
              label: 'Total cobrado',
              value: '\$${fmt2.format(totalCobrado)}',
            ),
            _ResumenRow(
              icon: Icons.percent,
              color: Colors.purple,
              label: 'Tu comisión (${(ComisionService.kPorcentajeComision * 100).toInt()}%)',
              value: '\$${fmt2.format(totalCobrado * ComisionService.kPorcentajeComision)}',
            ),
            const SizedBox(height: 8),
            Text(
              'Entrega \$${fmt2.format(totalCobrado)} al administrador '
              'al finalizar tu ruta.',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _ResumenRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _ResumenRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(value,
              style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
