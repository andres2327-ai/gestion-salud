import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers.dart';
import '../models/tarjeta_model.dart';
import '../core/theme/app_theme.dart';

class VentaDetalleScreen extends ConsumerStatefulWidget {
  final TarjetaModel tarjeta;
  const VentaDetalleScreen({super.key, required this.tarjeta});

  @override
  ConsumerState<VentaDetalleScreen> createState() => _VentaDetalleScreenState();
}

class _VentaDetalleScreenState extends ConsumerState<VentaDetalleScreen> {
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

  @override
  Widget build(BuildContext context) {
    final t = widget.tarjeta;
    final pagado = t.totalVenta - t.saldoPendiente;
    final progreso =
        t.totalVenta > 0 ? (pagado / t.totalVenta).clamp(0.0, 1.0) : 0.0;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final jadeColor = isDark ? AppColors.darkJade : AppColors.brandJade;
    final ink200 = isDark ? AppColors.darkInk200 : AppColors.lightInk200;
    final fechaStr = DateFormat('dd/MM/yyyy').format(t.fechaVenta);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.nombreCliente,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero financiero ─────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.brandGradStart, AppColors.brandGradEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
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
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          Text(
                            '\$${fmt.format(t.saldoPendiente)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.02,
                            ),
                          ),
                        ],
                      ),
                      _EstadoBadge(estado: t.estado),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progreso,
                      backgroundColor: Colors.white24,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pagado: \$${fmt.format(pagado)}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        'Total: \$${fmt.format(t.totalVenta)}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(progreso * 100).toStringAsFixed(0)}% cobrado · '
                    '${t.numCuotas} cuotas '
                    '${t.frecuenciaPago == FrecuenciaPago.diaria ? "diarias" : "semanales"} · '
                    '\$${fmt.format(t.montoCuota)} c/u',
                    style: const TextStyle(color: Colors.white60, fontSize: 11.5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Info cliente ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: ink200),
              ),
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.person_outline,
                    label: 'Asesora',
                    value: t.nombreAsesora,
                    isDark: isDark,
                    cs: cs,
                  ),
                  if (t.telefonoCliente.isNotEmpty) ...[
                    Divider(height: 20, color: ink200),
                    _InfoRow(
                      icon: Icons.phone_outlined,
                      label: 'Teléfono',
                      value: t.telefonoCliente,
                      isDark: isDark,
                      cs: cs,
                      onTap: () =>
                          launchUrl(Uri.parse('tel:${t.telefonoCliente}')),
                    ),
                  ],
                  if (t.direccionCliente.isNotEmpty) ...[
                    Divider(height: 20, color: ink200),
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      label: 'Dirección',
                      value: t.direccionCliente,
                      isDark: isDark,
                      cs: cs,
                    ),
                  ],
                  if (t.zona.isNotEmpty) ...[
                    Divider(height: 20, color: ink200),
                    _InfoRow(
                      icon: Icons.map_outlined,
                      label: 'Zona',
                      value: t.zona,
                      isDark: isDark,
                      cs: cs,
                    ),
                  ],
                  if (t.descripcion != null && t.descripcion!.isNotEmpty) ...[
                    Divider(height: 20, color: ink200),
                    _InfoRow(
                      icon: Icons.notes_outlined,
                      label: 'Descripción',
                      value: t.descripcion!,
                      isDark: isDark,
                      cs: cs,
                    ),
                  ],
                  Divider(height: 20, color: ink200),
                  _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Fecha de venta',
                    value: fechaStr,
                    isDark: isDark,
                    cs: cs,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Productos ───────────────────────────────────────────────────
            if (t.productos.isNotEmpty) ...[
              Text(
                'PRODUCTOS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurfaceVariant,
                  letterSpacing: 0.06,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: ink200),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < t.productos.length; i++) ...[
                      if (i > 0) Divider(height: 1, color: ink200),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.productos[i].nombreProducto,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '${t.productos[i].cantidad} unidad${t.productos[i].cantidad != 1 ? "es" : ""} · '
                                    '\$${fmt.format(t.productos[i].precioVenta)} c/u',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '\$${fmt.format(t.productos[i].subtotal)}',
                              style: TextStyle(
                                color: jadeColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Historial de pagos ──────────────────────────────────────────
            Text(
              'HISTORIAL DE PAGOS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: cs.onSurfaceVariant,
                letterSpacing: 0.06,
              ),
            ),
            const SizedBox(height: 10),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _pagosStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final pagos = snapshot.data ?? [];
                if (pagos.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: ink200),
                    ),
                    child: Center(
                      child: Text(
                        'Sin pagos registrados aún',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ),
                  );
                }
                return Column(
                  children: pagos.map((pago) {
                    final monto = (pago['monto'] as num?)?.toDouble() ?? 0;
                    final obs = pago['observacion'] as String?;
                    final fecha = (pago['fecha'] as Timestamp?)?.toDate();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: ink200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkJade50
                                  : AppColors.lightJade50,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Icon(
                              Icons.payments_outlined,
                              color: jadeColor,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '\$${fmt.format(monto)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                if (obs != null && obs.isNotEmpty)
                                  Text(
                                    obs,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (fecha != null)
                            Text(
                              datefmt.format(fecha),
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
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
  final bool isDark;
  final ColorScheme cs;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    required this.cs,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final jadeColor = isDark ? AppColors.darkJade : AppColors.brandJade;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: jadeColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: onTap != null ? jadeColor : cs.onSurface,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            Icon(Icons.open_in_new, color: cs.onSurfaceVariant, size: 14),
        ],
      ),
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  final EstadoTarjeta estado;
  const _EstadoBadge({required this.estado});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (estado) {
      EstadoTarjeta.activa => ('Activa', Colors.white),
      EstadoTarjeta.pagada => ('Pagada', Colors.white70),
      EstadoTarjeta.vencida => ('Vencida', AppColors.coral50),
      EstadoTarjeta.atrasada => ('Atrasada', AppColors.amber50),
      EstadoTarjeta.enDevolucion => ('En devolución', AppColors.violet50),
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
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
