import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers.dart';
import '../models/tarjeta_model.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_snackbar.dart';
import 'widgets/shared_widgets.dart';

class AsesoraDevolucionScreen extends ConsumerStatefulWidget {
  final String asesoraUid;
  const AsesoraDevolucionScreen({super.key, required this.asesoraUid});

  @override
  ConsumerState<AsesoraDevolucionScreen> createState() =>
      _AsesoraDevolucionScreenState();
}

class _AsesoraDevolucionScreenState
    extends ConsumerState<AsesoraDevolucionScreen> {
  TarjetaModel? _tarjetaSeleccionada;
  TarjetaProductoModel? _productoSeleccionado;
  int _cantidad = 1;
  final _motivoCtrl = TextEditingController();
  bool _guardando = false;

  final fmt = NumberFormat('#,###', 'es_CO');

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(tarjetaControllerProvider.notifier)
          .cargarTarjetasAsesora(widget.asesoraUid);
    });
  }

  @override
  void dispose() {
    _motivoCtrl.dispose();
    super.dispose();
  }

  double get _montoReembolso {
    if (_productoSeleccionado == null) return 0;
    return _productoSeleccionado!.precioVenta * _cantidad;
  }

  Future<void> _enviarSolicitud() async {
    if (_tarjetaSeleccionada == null) {
      _snack('Selecciona una venta', error: true);
      return;
    }
    if (_productoSeleccionado == null) {
      _snack('Selecciona un producto', error: true);
      return;
    }
    if (_motivoCtrl.text.trim().isEmpty) {
      _snack('Ingresa el motivo', error: true);
      return;
    }

    setState(() => _guardando = true);

    final ok = await ref.read(cobroControllerProvider.notifier).solicitarDevolucion(
      tarjetaId: _tarjetaSeleccionada!.tarjetaId,
      tarjetaProductoId: _productoSeleccionado!.id,
      codigoBarras: _productoSeleccionado!.codigoBarras,
      asesoraUid: widget.asesoraUid,
      nombreCliente: _tarjetaSeleccionada!.nombreCliente,
      nombreProducto: _productoSeleccionado!.nombreProducto,
      cantidadDevuelta: _cantidad,
      montoReembolso: _montoReembolso,
      motivo: _motivoCtrl.text.trim(),
    );

    setState(() => _guardando = false);

    if (mounted) {
      if (ok) {
        _snack('Solicitud enviada. Pendiente de aprobación.');
        Navigator.pop(context);
      } else {
        final err = ref.read(cobroControllerProvider).error ?? 'Error';
        _snack(err, error: true);
      }
    }
  }

  void _snack(String msg, {bool error = false}) =>
      appSnackbar(context, msg, error: error);

  @override
  Widget build(BuildContext context) {
    final tarjetaState = ref.watch(tarjetaControllerProvider);
    final tarjetas = tarjetaState.tarjetas
        .where((t) => t.estado == EstadoTarjeta.activa)
        .toList();
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final jadeColor = isDark ? AppColors.darkJade : AppColors.brandJade;
    final jadeBg = isDark ? AppColors.darkJade50 : AppColors.lightJade50;
    final violetColor = isDark ? AppColors.darkViolet : AppColors.violet;
    final amberColor = isDark ? AppColors.darkAmber : AppColors.amber;
    final amberBg = isDark ? AppColors.darkAmber50 : AppColors.amber50;
    final borderColor = isDark ? AppColors.darkInk200 : AppColors.lightInk200;

    return Scaffold(
      appBar: AppBar(title: const Text('Solicitar Devolución')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [

          // ── Selector de venta ──────────────────────────────────────────
          const SectionLabel('VENTA'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<TarjetaModel>(
                isExpanded: true,
                value: _tarjetaSeleccionada,
                hint: Text(
                  'Seleccionar venta...',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
                items: tarjetas.map((t) {
                  return DropdownMenuItem(
                    value: t,
                    child: Text(
                      '${t.nombreCliente} — \$${fmt.format(t.saldoPendiente)}',
                    ),
                  );
                }).toList(),
                onChanged: (t) {
                  setState(() {
                    _tarjetaSeleccionada = t;
                    _productoSeleccionado = null;
                    _cantidad = 1;
                  });
                },
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Selector de producto ───────────────────────────────────────
          const SectionLabel('PRODUCTO'),
          const SizedBox(height: 10),
          Builder(builder: (_) {
            final productos = _tarjetaSeleccionada?.productos ?? [];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<TarjetaProductoModel>(
                  isExpanded: true,
                  value: _productoSeleccionado,
                  hint: Text(
                    _tarjetaSeleccionada == null
                        ? 'Primero selecciona una venta'
                        : productos.isEmpty
                            ? 'Sin productos en esta venta'
                            : 'Seleccionar producto...',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                  items: productos.map((p) {
                    return DropdownMenuItem(
                      value: p,
                      child: Text('${p.nombreProducto}  (x${p.cantidad})'),
                    );
                  }).toList(),
                  onChanged: productos.isEmpty
                      ? null
                      : (p) => setState(() {
                            _productoSeleccionado = p;
                            _cantidad = 1;
                          }),
                ),
              ),
            );
          }),

          const SizedBox(height: 20),

          // ── Cantidad ───────────────────────────────────────────────────
          const SectionLabel('CANTIDAD A DEVOLVER'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Row(children: [
              CounterButton(
                icon: Icons.remove,
                enabled: _cantidad > 1,
                accentColor: jadeColor,
                accentBg: jadeBg,
                size: 36,
                onTap: _cantidad > 1 ? () => setState(() => _cantidad--) : null,
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '$_cantidad',
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              CounterButton(
                icon: Icons.add,
                enabled: _productoSeleccionado != null &&
                    _cantidad < _productoSeleccionado!.cantidad,
                accentColor: jadeColor,
                accentBg: jadeBg,
                size: 36,
                onTap: _productoSeleccionado != null &&
                        _cantidad < _productoSeleccionado!.cantidad
                    ? () => setState(() => _cantidad++)
                    : null,
              ),
            ]),
          ),

          const SizedBox(height: 20),

          // ── Motivo ─────────────────────────────────────────────────────
          const SectionLabel('MOTIVO'),
          const SizedBox(height: 10),
          TextField(
            controller: _motivoCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Describe el motivo de la devolución...',
            ),
          ),

          const SizedBox(height: 16),

          // ── Aviso ──────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: amberBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: amberColor.withAlpha(60)),
            ),
            child: Row(children: [
              Icon(Icons.info_outline, color: amberColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'La devolución queda sujeta a aprobación de la administradora.',
                  style: TextStyle(color: amberColor, fontSize: 12),
                ),
              ),
            ]),
          ),

          if (_productoSeleccionado != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Monto a descontar:',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                  Text(
                    '\$${fmt.format(_montoReembolso)}',
                    style: TextStyle(
                      color: violetColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 28),

          // ── Botón enviar ───────────────────────────────────────────────
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _guardando ? null : _enviarSolicitud,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.darkCoral : AppColors.coral,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _guardando
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Enviar Solicitud',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
