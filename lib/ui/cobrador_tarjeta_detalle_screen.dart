import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers.dart';
import '../models/tarjeta_model.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_snackbar.dart';
import 'widgets/foto_picker.dart';

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

  Future<void> _comenzarRuta() async {
    final tarjeta = widget.tarjeta;
    if (tarjeta.latitud == 0 && tarjeta.longitud == 0) {
      _snack('Esta tarjeta no tiene coordenadas registradas', error: true);
      return;
    }

    // geo: URI muestra el selector de apps nativo de Android
    // (Google Maps, Waze, HERE Maps, etc.)
    final geoUri = Uri.parse(
      'geo:${tarjeta.latitud},${tarjeta.longitud}'
      '?q=${tarjeta.latitud},${tarjeta.longitud}'
      '(${Uri.encodeComponent(tarjeta.nombreCliente)})',
    );

    if (!await launchUrl(geoUri, mode: LaunchMode.externalApplication)) {
      // Fallback si no hay ninguna app de mapas instalada
      final mapsUri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&destination=${tarjeta.latitud},${tarjeta.longitud}'
        '&travelmode=driving',
      );
      if (!await launchUrl(mapsUri, mode: LaunchMode.externalApplication)) {
        _snack('No se pudo abrir ninguna app de navegación', error: true);
      }
    }
  }

  void _mostrarDialogoCobro() {
    final tarjeta = widget.tarjeta;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final jadeColor = isDark ? AppColors.darkJade : AppColors.brandJade;
    final jadeBg = isDark ? AppColors.darkJade50 : AppColors.lightJade50;

    final esCobrableAhora = tarjeta.estado == EstadoTarjeta.activa ||
        tarjeta.estado == EstadoTarjeta.atrasada;
    if (!esCobrableAhora) return;

    final montoCtrl = TextEditingController();
    final obsCtrl = TextEditingController();
    XFile? fotoCobro;
    bool intentoEnviar = false;
    bool subiendo = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.92,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollCtrl) => Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: ListView(
              controller: scrollCtrl,
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              children: [
                // ── Handle ──────────────────────────────────────────
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: cs.outline,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),

                // ── Cliente y saldo ──────────────────────────────────
                Text(
                  tarjeta.nombreCliente,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Saldo pendiente: ',
                      style: TextStyle(
                          fontSize: 13, color: cs.onSurfaceVariant),
                    ),
                    Text(
                      '\$${fmt.format(tarjeta.saldoPendiente)}',
                      style: TextStyle(
                        color: jadeColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(
                    color: isDark
                        ? AppColors.darkInk200
                        : AppColors.lightInk200),
                const SizedBox(height: 10),

                // ── Monto ──────────────────────────────────────────
                TextField(
                  controller: montoCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    hintText: '0',
                    prefixText: '\$ ',
                    prefixStyle: TextStyle(
                      color: jadeColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // ── Observación ────────────────────────────────────
                TextField(
                  controller: obsCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Observación (opcional)',
                  ),
                ),
                const SizedBox(height: 20),

                // ── Foto requerida ─────────────────────────────────
                Text(
                  'FOTO DEL COBRO',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: jadeColor,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                FotoPickerTile(
                  valor: fotoCobro,
                  requerida: true,
                  mostrarError: intentoEnviar && fotoCobro == null,
                  accentColor: jadeColor,
                  accentBg: jadeBg,
                  onChanged: (f) => setModalState(() => fotoCobro = f),
                ),
                const SizedBox(height: 20),

                // ── Confirmar ──────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: jadeColor,
                      foregroundColor:
                          isDark ? AppColors.darkBg : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: subiendo
                        ? null
                        : () async {
                            setModalState(() => intentoEnviar = true);

                            final raw =
                                montoCtrl.text.replaceAll(',', '.');
                            final monto = double.tryParse(raw);
                            if (monto == null || monto <= 0) {
                              appSnackbar(context,
                                  'Ingresa un monto válido',
                                  error: true);
                              return;
                            }
                            if (fotoCobro == null) {
                              appSnackbar(
                                  context,
                                  'La foto del cobro es obligatoria',
                                  error: true);
                              return;
                            }

                            setModalState(() => subiendo = true);

                            // Subir foto antes de registrar el pago
                            String? fotoUrl;
                            try {
                              fotoUrl = await ref
                                  .read(storageServiceProvider)
                                  .subirFotoCobro(
                                    foto: fotoCobro!,
                                    tarjetaId: tarjeta.tarjetaId,
                                  );
                            } catch (_) {
                              if (mounted) {
                                appSnackbar(
                                    context,
                                    'Error al subir la foto',
                                    error: true);
                              }
                              setModalState(() => subiendo = false);
                              return;
                            }

                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);

                            final perfil = ref.read(usuarioActualProvider);
                            final ok = await ref
                                .read(cobroControllerProvider.notifier)
                                .registrarPago(
                                  tarjetaId: tarjeta.tarjetaId,
                                  cobradorUid: widget.cobradorUid,
                                  nombreCobrador: perfil?.nombre ?? '',
                                  nombreCliente: tarjeta.nombreCliente,
                                  monto: monto,
                                  saldoActual: tarjeta.saldoPendiente,
                                  observacion:
                                      obsCtrl.text.trim().isEmpty
                                          ? null
                                          : obsCtrl.text.trim(),
                                  fotoUrl: fotoUrl,
                                );
                            if (mounted) {
                              appSnackbar(
                                context,
                                ok
                                    ? '\$${fmt.format(monto)} registrados'
                                    : 'Error al registrar el cobro',
                                error: !ok,
                              );
                            }
                          },
                    child: subiendo
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Confirmar Cobro',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarDialogoDevolucion() {
    final tarjeta = widget.tarjeta;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    TarjetaProductoModel? productoSeleccionado;
    final cantidadCtrl = TextEditingController(text: '1');
    final motivoCtrl = TextEditingController();
    bool devolverTodo = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final amberColor = isDark ? AppColors.darkAmber : AppColors.amber;
          return Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: cs.outline,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const Text(
                  'Registrar Devolución',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 14),

                // ── Toggle: producto individual vs tarjeta completa ────
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkInk100
                        : AppColors.lightInk100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SwitchListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14),
                    title: const Text(
                      'Devolver tarjeta completa',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      devolverTodo
                          ? 'Reembolso: \$${fmt.format(tarjeta.saldoPendiente)}'
                          : 'Selecciona producto específico',
                      style: TextStyle(
                        fontSize: 12,
                        color: devolverTodo ? amberColor : cs.onSurfaceVariant,
                      ),
                    ),
                    value: devolverTodo,
                    activeThumbColor: amberColor,
                    onChanged: (v) => setModalState(() {
                      devolverTodo = v;
                      if (v) productoSeleccionado = null;
                    }),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Producto / cantidad (solo si no es tarjeta completa) ─
                if (!devolverTodo) ...[
                  DropdownButtonFormField<TarjetaProductoModel>(
                    initialValue: productoSeleccionado,
                    decoration: const InputDecoration(hintText: 'Producto *'),
                    items: tarjeta.productos
                        .map((p) => DropdownMenuItem(
                              value: p,
                              child: Text(p.nombreProducto),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setModalState(() => productoSeleccionado = v),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: cantidadCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Cantidad a devolver',
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                TextField(
                  controller: motivoCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Motivo de devolución *',
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: amberColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      final motivo = motivoCtrl.text.trim();
                      if (motivo.isEmpty) return;

                      if (devolverTodo) {
                        Navigator.pop(ctx);
                        final ok = await ref
                            .read(cobroControllerProvider.notifier)
                            .solicitarDevolucion(
                              tarjetaId: tarjeta.tarjetaId,
                              tarjetaProductoId: '',
                              codigoBarras: '',
                              asesoraUid: tarjeta.asesoraUid,
                              nombreCliente: tarjeta.nombreCliente,
                              nombreProducto: 'Tarjeta completa',
                              cantidadDevuelta: 1,
                              montoReembolso: tarjeta.saldoPendiente,
                              motivo: motivo,
                              esCobrador: true,
                            );
                        if (!mounted) return;
                        if (ok) {
                          Navigator.pop(context);
                          appSnackbar(context,
                              'Devolución enviada — tarjeta en proceso de revisión');
                        } else {
                          _snack('Error al registrar la devolución',
                              error: true);
                        }
                      } else {
                        final prod = productoSeleccionado;
                        final cantidad =
                            int.tryParse(cantidadCtrl.text) ?? 0;
                        if (prod == null || cantidad <= 0) return;
                        Navigator.pop(ctx);
                        final ok = await ref
                            .read(cobroControllerProvider.notifier)
                            .solicitarDevolucion(
                              tarjetaId: tarjeta.tarjetaId,
                              tarjetaProductoId: prod.id,
                              codigoBarras: prod.codigoBarras,
                              asesoraUid: tarjeta.asesoraUid,
                              nombreCliente: tarjeta.nombreCliente,
                              nombreProducto: prod.nombreProducto,
                              cantidadDevuelta: cantidad,
                              montoReembolso: prod.precioVenta * cantidad,
                              motivo: motivo,
                              esCobrador: true,
                            );
                        if (!mounted) return;
                        if (ok) {
                          Navigator.pop(context);
                          appSnackbar(context,
                              'Devolución enviada — tarjeta en proceso de revisión');
                        } else {
                          _snack('Error al registrar la devolución',
                              error: true);
                        }
                      }
                    },
                    child: const Text(
                      'Enviar Devolución',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _snack(String msg, {bool error = false}) =>
      appSnackbar(context, msg, error: error);

  @override
  Widget build(BuildContext context) {
    final tarjeta = widget.tarjeta;
    final pagado = tarjeta.totalVenta - tarjeta.saldoPendiente;
    final progreso = tarjeta.totalVenta > 0
        ? (pagado / tarjeta.totalVenta).clamp(0.0, 1.0)
        : 0.0;
    final tieneCoords = tarjeta.latitud != 0 || tarjeta.longitud != 0;
    final esCobrable = tarjeta.estado == EstadoTarjeta.activa ||
        tarjeta.estado == EstadoTarjeta.atrasada;
    final enDevolucion = tarjeta.estado == EstadoTarjeta.enDevolucion;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          tarjeta.nombreCliente,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Hero financiero ────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.brandGradStart,
                          AppColors.brandGradEnd,
                        ],
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
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '\$${fmt.format(tarjeta.saldoPendiente)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.02,
                                  ),
                                ),
                              ],
                            ),
                            _EstadoBadgeDetalle(estado: tarjeta.estado),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: progreso,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white),
                            minHeight: 5,
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
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Banner devolución en proceso ───────────────────────
                  if (enDevolucion)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkViolet50 : AppColors.violet50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? AppColors.darkViolet : AppColors.violet,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.hourglass_top_rounded,
                            size: 18,
                            color: isDark ? AppColors.darkViolet : AppColors.violet,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Devolución en proceso — esperando aprobación del admin. No se pueden registrar cobros.',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isDark ? AppColors.darkViolet : AppColors.violet,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ── Info del cliente ───────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkInk200
                            : AppColors.lightInk200,
                      ),
                    ),
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.person_outline,
                          label: 'Asesora',
                          value: tarjeta.nombreAsesora,
                          isDark: isDark,
                          cs: cs,
                        ),
                        if (tarjeta.telefonoCliente.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _InfoRow(
                            icon: Icons.phone_outlined,
                            label: 'Teléfono',
                            value: tarjeta.telefonoCliente,
                            isDark: isDark,
                            cs: cs,
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
                            isDark: isDark,
                            cs: cs,
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
                            isDark: isDark,
                            cs: cs,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Historial de pagos ─────────────────────────────────
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
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
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
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkInk200
                                  : AppColors.lightInk200,
                            ),
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
                          final monto =
                              (pago['monto'] as num?)?.toDouble() ?? 0;
                          final obs = pago['observacion'] as String?;
                          final fecha =
                              (pago['fecha'] as Timestamp?)?.toDate();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: cs.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkInk200
                                    : AppColors.lightInk200,
                              ),
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
                                    color: isDark
                                        ? AppColors.darkJade
                                        : AppColors.brandJade,
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

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // ── Barra de acciones ────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.darkInk200 : AppColors.lightInk200,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: tieneCoords ? _comenzarRuta : null,
                    icon: const Icon(Icons.navigation_outlined, size: 17),
                    label: const Text('Ruta'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          isDark ? AppColors.darkSky : AppColors.sky,
                      side: BorderSide(
                        color: tieneCoords
                            ? (isDark ? AppColors.darkSky : AppColors.sky)
                            : (isDark
                                ? AppColors.darkInk300
                                : AppColors.lightInk300),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: !enDevolucion && esCobrable && tarjeta.productos.isNotEmpty
                        ? _mostrarDialogoDevolucion
                        : null,
                    icon: Icon(
                      enDevolucion ? Icons.hourglass_top_rounded : Icons.reply_outlined,
                      size: 17,
                    ),
                    label: Text(enDevolucion ? 'Pendiente' : 'Devolución'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          enDevolucion
                              ? (isDark ? AppColors.darkViolet : AppColors.violet)
                              : (isDark ? AppColors.darkAmber : AppColors.amber),
                      side: BorderSide(
                        color: enDevolucion
                            ? (isDark ? AppColors.darkViolet : AppColors.violet)
                            : (!enDevolucion && esCobrable && tarjeta.productos.isNotEmpty
                                ? (isDark ? AppColors.darkAmber : AppColors.amber)
                                : (isDark ? AppColors.darkInk300 : AppColors.lightInk300)),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: esCobrable ? _mostrarDialogoCobro : null,
                    icon: const Icon(Icons.add_card, size: 17),
                    label: const Text('Cobrar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDark ? AppColors.darkJade : AppColors.brandJade,
                      foregroundColor:
                          isDark ? AppColors.darkBg : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
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
                  style:
                      TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
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

class _EstadoBadgeDetalle extends StatelessWidget {
  final EstadoTarjeta estado;
  const _EstadoBadgeDetalle({required this.estado});

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
