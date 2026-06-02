import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers.dart';
import '../models/usuario_model.dart';
import '../models/producto_model.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_snackbar.dart';

class AdminAsignarProductosScreen extends ConsumerStatefulWidget {
  final UsuarioModel asesora;

  const AdminAsignarProductosScreen({super.key, required this.asesora});

  @override
  ConsumerState<AdminAsignarProductosScreen> createState() =>
      _AdminAsignarProductosScreenState();
}

class _AdminAsignarProductosScreenState
    extends ConsumerState<AdminAsignarProductosScreen> {
  ProductoModel? _productoSeleccionado;
  final _cantCtrl = TextEditingController(text: '1');
  bool _guardando = false;

  final fmt = NumberFormat('#,###', 'es_CO');

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(productoControllerProvider.notifier).cargar();
      ref
          .read(asignacionProductoControllerProvider.notifier)
          .escucharAsignaciones(widget.asesora.uid);
    });
  }

  @override
  void dispose() {
    _cantCtrl.dispose();
    super.dispose();
  }

  Future<void> _asignar() async {
    if (_productoSeleccionado == null) {
      _snack('Selecciona un producto', error: true);
      return;
    }
    final cant = int.tryParse(_cantCtrl.text) ?? 0;
    if (cant <= 0) {
      _snack('La cantidad debe ser mayor a 0', error: true);
      return;
    }
    if (cant > _productoSeleccionado!.cantidadStock) {
      _snack(
        'No hay suficiente stock (disponible: ${_productoSeleccionado!.cantidadStock})',
        error: true,
      );
      return;
    }

    setState(() => _guardando = true);

    final ok = await ref
        .read(asignacionProductoControllerProvider.notifier)
        .asignarProducto(
          asesoraUid: widget.asesora.uid,
          codigoBarras: _productoSeleccionado!.codigoBarras,
          nombreProducto: _productoSeleccionado!.nombre,
          precioUnitario: _productoSeleccionado!.precioUnitario,
          cantidad: cant,
        );

    setState(() => _guardando = false);

    if (mounted) {
      _snack(
        ok
            ? '$cant unidades de "${_productoSeleccionado!.nombre}" asignadas a ${widget.asesora.nombre}'
            : (ref.read(asignacionProductoControllerProvider).error ??
                'Error al asignar'),
        error: !ok,
      );
      if (ok) {
        setState(() {
          _productoSeleccionado = null;
          _cantCtrl.text = '1';
        });
      }
    }
  }

  void _snack(String msg, {bool error = false}) =>
      appSnackbar(context, msg, error: error);

  @override
  Widget build(BuildContext context) {
    final productoState = ref.watch(productoControllerProvider);
    final asigState = ref.watch(asignacionProductoControllerProvider);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final jadeColor = isDark ? AppColors.darkJade : AppColors.brandJade;
    final jadeBg = isDark ? AppColors.darkJade50 : AppColors.lightJade50;
    final borderColor = isDark ? AppColors.darkInk200 : AppColors.lightInk200;

    final productosDisponibles = productoState.productos
        .where((p) => p.activo && p.cantidadStock > 0)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Asignar Productos', style: TextStyle(fontSize: 16)),
            Text(
              widget.asesora.nombre,
              style: TextStyle(color: jadeColor, fontSize: 12),
            ),
          ],
        ),
      ),
      body: productoState.cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Selector de producto
                Text(
                  'PRODUCTO DEL INVENTARIO',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.06,
                  ),
                ),
                const SizedBox(height: 10),
                productosDisponibles.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor),
                        ),
                        child: Text(
                          'No hay productos con stock disponible',
                          style: TextStyle(color: cs.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<ProductoModel>(
                            isExpanded: true,
                            value: _productoSeleccionado,
                            hint: Text(
                              'Selecciona un producto...',
                              style: TextStyle(color: cs.onSurfaceVariant),
                            ),
                            items: productosDisponibles.map((p) {
                              return DropdownMenuItem(
                                value: p,
                                child: Text(
                                  '${p.nombre}  ·  Stock: ${p.cantidadStock}  ·  \$${fmt.format(p.precioUnitario)}',
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (p) =>
                                setState(() => _productoSeleccionado = p),
                          ),
                        ),
                      ),

                if (_productoSeleccionado != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: jadeBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: jadeColor.withAlpha(60)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: jadeColor, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Stock disponible: ${_productoSeleccionado!.cantidadStock} unidades',
                          style: TextStyle(color: jadeColor, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                Text(
                  'CANTIDAD A ASIGNAR',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.06,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _cantCtrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(hintText: '0'),
                ),

                const SizedBox(height: 28),

                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _guardando ? null : _asignar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: jadeColor,
                      foregroundColor: isDark ? AppColors.darkBg : Colors.white,
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
                            'Asignar Producto',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 32),

                Text(
                  'PRODUCTOS YA ASIGNADOS',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.06,
                  ),
                ),
                const SizedBox(height: 10),
                if (asigState.cargando)
                  const Center(child: CircularProgressIndicator())
                else if (asigState.asignaciones.isEmpty)
                  Text(
                    'Ninguno aún',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  )
                else
                  ...asigState.asignaciones.map((a) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(isDark ? 40 : 6),
                            blurRadius: 1,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              a.nombreProducto,
                              style: TextStyle(
                                color: cs.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Asignados: ${a.cantidadAsignada}',
                                style: TextStyle(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'Vendidos: ${a.cantidadVendida}',
                                style: TextStyle(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'Disponibles: ${a.cantidadDisponible}',
                                style: TextStyle(
                                  color: jadeColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}
