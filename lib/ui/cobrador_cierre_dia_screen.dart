// lib/ui/cobrador_cierre_dia_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers.dart';
import '../models/tarjeta_model.dart';
import '../models/comision_model.dart';
import '../services/comision_service.dart';
import '../core/theme/app_theme.dart';

class CobradorCierreDiaScreen extends ConsumerStatefulWidget {
  const CobradorCierreDiaScreen({super.key});

  @override
  ConsumerState<CobradorCierreDiaScreen> createState() =>
      _CobradorCierreDiaScreenState();
}

class _CobradorCierreDiaScreenState
    extends ConsumerState<CobradorCierreDiaScreen> {
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

  double get _totalCobradoHoy =>
      _comisionesHoy.fold(0.0, (s, c) => s + c.montoBase);
  double get _totalComisionHoy =>
      _comisionesHoy.fold(0.0, (s, c) => s + c.montoComision);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
        title: const Text('Cierre del Día'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _cargarComisiones,
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary row
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      _SummaryCard(
                        label: 'Cobradas',
                        value: '${cobradas.length}',
                        color: isDark ? AppColors.darkJade : AppColors.brandJade,
                        bg: isDark ? AppColors.darkJade50 : AppColors.lightJade50,
                        icon: Icons.check_circle_outline,
                      ),
                      const SizedBox(width: 10),
                      _SummaryCard(
                        label: 'Sin cobrar',
                        value: '${noCobradas.length}',
                        color: isDark ? AppColors.darkCoral : AppColors.coral,
                        bg: isDark ? AppColors.darkCoral50 : AppColors.coral50,
                        icon: Icons.cancel_outlined,
                      ),
                      const SizedBox(width: 10),
                      _SummaryCard(
                        label: 'Sin visitar',
                        value: '$sinVisitar',
                        color: cs.onSurfaceVariant,
                        bg: isDark ? AppColors.darkInk100 : AppColors.lightInk100,
                        icon: Icons.pending_outlined,
                      ),
                    ],
                  ),
                ),

                // Commission banner
                if (_comisionesHoy.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkJade50 : AppColors.lightJade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: (isDark ? AppColors.darkJade : AppColors.brandJade)
                              .withAlpha(60),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.attach_money,
                            color: isDark ? AppColors.darkJade : AppColors.brandJade,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cobrado hoy: \$${fmt.format(_totalCobradoHoy)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Tu comisión (20%): \$${fmt.format(_totalComisionHoy)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkJade : AppColors.brandJade,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'MIS TARJETAS DE HOY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurfaceVariant,
                        letterSpacing: 0.06,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                Expanded(
                  child: asignaciones.isEmpty
                      ? Center(
                          child: Text(
                            'No tienes tarjetas asignadas',
                            style: TextStyle(color: cs.onSurfaceVariant),
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
                            final resultado = _resultados[asig.tarjetaId];
                            final motivo = _motivos[asig.tarjetaId];

                            Color borderColor = isDark
                                ? AppColors.darkInk200
                                : AppColors.lightInk200;
                            Color bgColor = cs.surface;
                            if (resultado == true) {
                              borderColor =
                                  (isDark ? AppColors.darkJade : AppColors.brandJade)
                                      .withAlpha(100);
                              bgColor =
                                  (isDark ? AppColors.darkJade50 : AppColors.lightJade50);
                            } else if (resultado == false) {
                              borderColor =
                                  (isDark ? AppColors.darkCoral : AppColors.coral)
                                      .withAlpha(100);
                              bgColor =
                                  (isDark ? AppColors.darkCoral50 : AppColors.coral50);
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: borderColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          asig.nombreCliente,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      if (tarjeta != null)
                                        Text(
                                          '\$${fmt.format(tarjeta.montoCuota)}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? AppColors.darkJade
                                                : AppColors.brandJade,
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (tarjeta != null) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      'Saldo: \$${fmt.format(tarjeta.saldoPendiente)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                  if (motivo != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        'Motivo: $motivo',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? AppColors.darkCoral
                                              : AppColors.coral,
                                        ),
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
                                          icon: const Icon(Icons.close, size: 15),
                                          label: const Text('No cobrado'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: isDark
                                                ? AppColors.darkCoral
                                                : AppColors.coral,
                                            side: BorderSide(
                                              color: resultado == false
                                                  ? (isDark
                                                      ? AppColors.darkCoral
                                                      : AppColors.coral)
                                                  : (isDark
                                                      ? AppColors.darkInk300
                                                      : AppColors.lightInk300),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
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
                                          icon: const Icon(Icons.check, size: 15),
                                          label: const Text('Cobrado'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isDark
                                                ? AppColors.darkJade
                                                : AppColors.brandJade,
                                            foregroundColor: isDark
                                                ? AppColors.darkBg
                                                : Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
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

                if (asignaciones.isNotEmpty && sinVisitar == 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _mostrarResumenFinal(
                            cobradas, noCobradas, tarjetasCobrador),
                        icon: const Icon(Icons.summarize_outlined, size: 18),
                        label: const Text('Ver Resumen del Día'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
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
              color: AppColors.brandJade,
              label: 'Cobradas',
              value: '${cobradas.length} tarjetas',
            ),
            _ResumenRow(
              icon: Icons.cancel,
              color: AppColors.coral,
              label: 'Sin cobrar',
              value: '${noCobradas.length} tarjetas',
            ),
            const Divider(),
            _ResumenRow(
              icon: Icons.attach_money,
              color: AppColors.brandJade,
              label: 'Total cobrado',
              value: '\$${fmt2.format(totalCobrado)}',
            ),
            _ResumenRow(
              icon: Icons.percent,
              color: AppColors.violet,
              label: 'Tu comisión (${(ComisionService.kPorcentajeComision * 100).toInt()}%)',
              value: '\$${fmt2.format(totalCobrado * ComisionService.kPorcentajeComision)}',
            ),
            const SizedBox(height: 8),
            Text(
              'Entrega \$${fmt2.format(totalCobrado)} al administrador '
              'al finalizar tu ruta.',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
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
  final Color bg;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.01,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: color.withAlpha(180),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
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
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
