import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers.dart';
import '../models/tarjeta_model.dart';

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

  // ✅ FIX: lista de productos guardada en estado local, NO en FutureBuilder
  List<TarjetaProductoModel> _productosDeVenta = [];
  bool _cargandoProductos = false;

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

  // ✅ FIX: carga productos una sola vez al seleccionar la tarjeta
  Future<void> _cargarProductosDeTarjeta(TarjetaModel tarjeta) async {
    setState(() {
      _cargandoProductos = true;
      _productosDeVenta = [];
      _productoSeleccionado = null;
      _cantidad = 1;
    });

    final productos = await ref
        .read(tarjetaControllerProvider.notifier)
        .obtenerProductosDeTarjeta(tarjeta.tarjetaId);

    if (mounted) {
      setState(() {
        _productosDeVenta = productos;
        _cargandoProductos = false;
      });
    }
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

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tarjetaState = ref.watch(tarjetaControllerProvider);
    final tarjetas = tarjetaState.tarjetas
        .where((t) => t.estado == EstadoTarjeta.activa)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F1123),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1C3A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Solicitar Devolución',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [

          // ── Selector de venta ──────────────────────────────────────────
          _Label('VENTA'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1C3A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<TarjetaModel>(
                isExpanded: true,
                dropdownColor: const Color(0xFF1A1C3A),
                value: _tarjetaSeleccionada,
                hint: const Text(
                  'Seleccionar venta...',
                  style: TextStyle(color: Colors.grey),
                ),
                items: tarjetas.map((t) {
                  return DropdownMenuItem(
                    value: t,
                    child: Text(
                      '${t.nombreCliente} — \$${fmt.format(t.saldoPendiente)}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }).toList(),
                onChanged: (t) {
                  setState(() => _tarjetaSeleccionada = t);
                  if (t != null) _cargarProductosDeTarjeta(t);
                },
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Selector de producto ───────────────────────────────────────
          _Label('PRODUCTO'),
          const SizedBox(height: 10),
          _cargandoProductos
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: CircularProgressIndicator(color: Colors.tealAccent),
                  ),
                )
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1C3A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  // ✅ FIX: usa _productosDeVenta (lista estable en state local)
                  // no un FutureBuilder que recrea objetos en cada render
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<TarjetaProductoModel>(
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1A1C3A),
                      value: _productoSeleccionado,
                      hint: Text(
                        _tarjetaSeleccionada == null
                            ? 'Primero selecciona una venta'
                            : _productosDeVenta.isEmpty
                                ? 'Sin productos en esta venta'
                                : 'Seleccionar producto...',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      items: _productosDeVenta.map((p) {
                        return DropdownMenuItem(
                          value: p,
                          child: Text(
                            '${p.nombreProducto}  (x${p.cantidad})',
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                      onChanged: _productosDeVenta.isEmpty
                          ? null
                          : (p) => setState(() {
                                _productoSeleccionado = p;
                                _cantidad = 1;
                              }),
                    ),
                  ),
                ),

          const SizedBox(height: 20),

          // ── Cantidad ───────────────────────────────────────────────────
          _Label('CANTIDAD A DEVOLVER'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1C3A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              _Btn(
                icon: Icons.remove,
                onTap: _cantidad > 1 ? () => setState(() => _cantidad--) : null,
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '$_cantidad',
                    style: const TextStyle(
                      color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              _Btn(
                icon: Icons.add,
                onTap: _productoSeleccionado != null &&
                        _cantidad < _productoSeleccionado!.cantidad
                    ? () => setState(() => _cantidad++)
                    : null,
              ),
            ]),
          ),

          const SizedBox(height: 20),

          // ── Motivo ─────────────────────────────────────────────────────
          _Label('MOTIVO'),
          const SizedBox(height: 10),
          TextField(
            controller: _motivoCtrl,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Describe el motivo de la devolución...',
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFF1A1C3A),
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

          const SizedBox(height: 16),

          // ── Aviso ──────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.withAlpha(60)),
            ),
            child: const Row(children: [
              Icon(Icons.info_outline, color: Colors.orange, size: 18),
              SizedBox(width: 8),
              Expanded(child: Text(
                'La devolución queda sujeta a aprobación de la administradora.',
                style: TextStyle(color: Colors.orange, fontSize: 12),
              )),
            ]),
          ),

          if (_productoSeleccionado != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1C3A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Monto a descontar:',
                      style: TextStyle(color: Colors.grey)),
                  Text(
                    '\$${fmt.format(_montoReembolso)}',
                    style: const TextStyle(
                      color: Colors.tealAccent,
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
          GestureDetector(
            onTap: _guardando ? null : _enviarSolicitud,
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                color: _guardando ? Colors.grey : Colors.redAccent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: _guardando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Enviar Solicitud',
                        style: TextStyle(
                          color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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

// ─── Widgets locales ─────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: Colors.tealAccent, fontSize: 11,
          fontWeight: FontWeight.w700, letterSpacing: 1.2,
        ),
      );
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _Btn({required this.icon, this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: onTap != null ? Colors.tealAccent.withAlpha(30) : Colors.grey.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: onTap != null ? Colors.tealAccent : Colors.grey),
        ),
        child: Icon(icon, color: onTap != null ? Colors.tealAccent : Colors.grey, size: 18),
      ),
    );
  }
}
