import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers.dart';
import '../models/tarjeta_model.dart';

class CobradorTarjetaDetalleScreen extends ConsumerStatefulWidget {
  final TarjetaModel tarjeta;
  final String cobradorUid;

  const CobradorTarjetaDetalleScreen({
    super.key,
    required this.tarjeta,
    required this.cobradorUid,
  });

  @override
  ConsumerState<CobradorTarjetaDetalleScreen> createState() =>
      _CobradorTarjetaDetalleScreenState();
}

class _CobradorTarjetaDetalleScreenState
    extends ConsumerState<CobradorTarjetaDetalleScreen> {
  bool _buscandoRuta = false;
  late final Stream<List<Map<String, dynamic>>> _pagosStream;

  final fmt = NumberFormat('#,###', 'es_CO');
  final datefmt = DateFormat('dd/MM/yyyy  HH:mm');

  @override
  void initState() {
    super.initState();
    _pagosStream = ref
        .read(cobroServiceProvider)
        .streamPagosDeTarjeta(widget.tarjeta.tarjetaId);
  }

  // ── Abrir ruta en Google Maps ──────────────────────────────────────────────

  Future<void> _comenzarRuta() async {
    final tarjeta = widget.tarjeta;

    if (tarjeta.latitud == 0 && tarjeta.longitud == 0) {
      _snack('Esta tarjeta no tiene coordenadas registradas', error: true);
      return;
    }

    setState(() => _buscandoRuta = true);
    try {
      final posicion =
          await ref.read(gpsServiceProvider).obtenerUbicacion();

      if (posicion == null) {
        _snack('No se pudo obtener tu ubicación actual', error: true);
        return;
      }

      final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&origin=${posicion.latitude},${posicion.longitude}'
        '&destination=${tarjeta.latitud},${tarjeta.longitud}'
        '&travelmode=driving',
      );

      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        _snack('No se pudo abrir Google Maps', error: true);
      }
    } finally {
      if (mounted) setState(() => _buscandoRuta = false);
    }
  }

  // ── Diálogo de cobro ───────────────────────────────────────────────────────

  void _mostrarDialogoCobro() {
    final tarjeta = widget.tarjeta;
    if (tarjeta.estado != EstadoTarjeta.activa) return;

    final montoCtrl = TextEditingController();
    final obsCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1C3A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tarjeta.nombreCliente,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Text(
                  'Saldo pendiente: ',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                Text(
                  '\$${fmt.format(tarjeta.saldoPendiente)}',
                  style: const TextStyle(
                    color: Colors.tealAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.white12),
            const SizedBox(height: 10),
            TextField(
              controller: montoCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixText: '\$ ',
                prefixStyle: const TextStyle(
                  color: Colors.tealAccent,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                filled: true,
                fillColor: const Color(0xFF0F1123),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.tealAccent),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: obsCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Observación (opcional)',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF0F1123),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  final raw = montoCtrl.text.replaceAll(',', '.');
                  final monto = double.tryParse(raw);
                  if (monto == null || monto <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ingresa un monto válido'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  Navigator.pop(ctx);
                  final ok = await ref
                      .read(cobroControllerProvider.notifier)
                      .registrarPago(
                        tarjetaId: tarjeta.tarjetaId,
                        cobradorUid: widget.cobradorUid,
                        monto: monto,
                        observacion: obsCtrl.text.trim().isEmpty
                            ? null
                            : obsCtrl.text.trim(),
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok
                              ? '\$${fmt.format(monto)} registrados'
                              : 'Error al registrar el cobro',
                        ),
                        backgroundColor: ok ? Colors.green : Colors.red,
                      ),
                    );
                  }
                },
                child: const Text(
                  'Confirmar Cobro',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red : Colors.green,
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tarjeta = widget.tarjeta;
    final pagado = tarjeta.totalVenta - tarjeta.saldoPendiente;
    final progreso = tarjeta.totalVenta > 0
        ? (pagado / tarjeta.totalVenta).clamp(0.0, 1.0)
        : 0.0;
    final tieneCoords = tarjeta.latitud != 0 || tarjeta.longitud != 0;
    final esActiva = tarjeta.estado == EstadoTarjeta.activa;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1123),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1C3A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          tarjeta.nombreCliente,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Tarjeta financiera ────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0D9B7A), Color(0xFF0ABFA3)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Saldo pendiente',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '\$${fmt.format(tarjeta.saldoPendiente)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            _EstadoBadgeDetalle(estado: tarjeta.estado),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progreso,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Pagado: \$${fmt.format(pagado)}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Total: \$${fmt.format(tarjeta.totalVenta)}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(progreso * 100).toStringAsFixed(0)}% cobrado · '
                          '${tarjeta.numCuotas} cuotas '
                          '${tarjeta.frecuenciaPago == FrecuenciaPago.diaria ? "diarias" : "semanales"} '
                          '· \$${fmt.format(tarjeta.montoCuota)} c/u',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Info del cliente ──────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1C3A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.person_outline,
                          label: 'Asesora',
                          value: tarjeta.nombreAsesora,
                        ),
                        if (tarjeta.telefonoCliente.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _InfoRow(
                            icon: Icons.phone_outlined,
                            label: 'Teléfono',
                            value: tarjeta.telefonoCliente,
                            onTap: () => launchUrl(
                              Uri.parse('tel:${tarjeta.telefonoCliente}'),
                            ),
                          ),
                        ],
                        if (tarjeta.direccionCliente.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _InfoRow(
                            icon: Icons.location_on_outlined,
                            label: 'Dirección',
                            value: tarjeta.direccionCliente,
                          ),
                        ],
                        if (tarjeta.productos.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _InfoRow(
                            icon: Icons.shopping_bag_outlined,
                            label: 'Productos',
                            value: tarjeta.productos
                                .map((p) => '${p.nombreProducto} ×${p.cantidad}')
                                .join(', '),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Historial de pagos ────────────────────────────────────
                  const Text(
                    'HISTORIAL DE PAGOS',
                    style: TextStyle(
                      color: Colors.tealAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),

                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _pagosStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                              color: Colors.tealAccent,
                            ),
                          ),
                        );
                      }

                      final pagos = snapshot.data ?? [];

                      if (pagos.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1C3A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              'Sin pagos registrados aún',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: pagos.map((pago) {
                          final monto =
                              (pago['monto'] as num?)?.toDouble() ?? 0;
                          final obs = pago['observacion'] as String?;
                          final fecha = (pago['fecha'] as Timestamp?)
                              ?.toDate();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1C3A),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.tealAccent.withAlpha(20),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.payments_outlined,
                                    color: Colors.tealAccent,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '\$${fmt.format(monto)}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      if (obs != null && obs.isNotEmpty)
                                        Text(
                                          obs,
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (fecha != null)
                                  Text(
                                    datefmt.format(fecha),
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // ── Botones de acción ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1C3A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                // Comenzar Ruta
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _buscandoRuta || !tieneCoords
                        ? null
                        : _comenzarRuta,
                    icon: _buscandoRuta
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.blueAccent,
                            ),
                          )
                        : const Icon(Icons.navigation_outlined, size: 18),
                    label: const Text('Comenzar Ruta'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blueAccent,
                      side: BorderSide(
                        color: tieneCoords
                            ? Colors.blueAccent
                            : Colors.grey,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Agregar Cobro
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: esActiva ? _mostrarDialogoCobro : null,
                    icon: const Icon(Icons.add_card, size: 18),
                    label: const Text('Agregar Cobro'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.tealAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets locales ──────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.tealAccent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: onTap != null ? Colors.tealAccent : Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(Icons.open_in_new, color: Colors.grey, size: 14),
        ],
      ),
    );
  }
}

class _EstadoBadgeDetalle extends StatelessWidget {
  final EstadoTarjeta estado;
  const _EstadoBadgeDetalle({required this.estado});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (estado) {
      EstadoTarjeta.activa => ('Activa', Colors.white),
      EstadoTarjeta.pagada => ('Pagada', Colors.lightBlueAccent),
      EstadoTarjeta.vencida => ('Vencida', Colors.redAccent),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white24,
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
