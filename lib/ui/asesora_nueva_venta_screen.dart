import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers.dart';
import '../models/tarjeta_model.dart';
import '../models/asignacion_producto_model.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_snackbar.dart';
import 'widgets/shared_widgets.dart';
import 'widgets/foto_picker.dart';
import 'producto_selector_screen.dart';

class AsesoraNuevaVentaScreen extends ConsumerStatefulWidget {
  final String asesoraUid;
  final String asesoraNombre;

  const AsesoraNuevaVentaScreen({
    super.key,
    required this.asesoraUid,
    required this.asesoraNombre,
  });

  @override
  ConsumerState<AsesoraNuevaVentaScreen> createState() =>
      _AsesoraNuevaVentaScreenState();
}

class _AsesoraNuevaVentaScreenState
    extends ConsumerState<AsesoraNuevaVentaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();

  FrecuenciaPago _frecuencia = FrecuenciaPago.semanal;
  int _numCuotas = 4;
  final Map<String, int> _cantidades = {};
  String? _zona;
  final _descripcionCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  String _busqueda = '';
  bool _guardando = false;
  XFile? _foto;
  bool _intentoRegistrar = false;

  final fmt = NumberFormat('#,###', 'es_CO');

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(asignacionProductoControllerProvider.notifier)
          .escucharAsignaciones(widget.asesoraUid);
    });
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _direccionCtrl.dispose();
    _descripcionCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _productosPendientes = [];

  double _calcSubtotal(List<AsignacionProductoModel> asignaciones) {
    final fromAssigned = asignaciones.fold(0.0, (sum, a) {
      final qty = _cantidades[a.codigoBarras] ?? 0;
      return sum + (a.precioUnitario * qty);
    });
    final fromPending = _productosPendientes.fold(
      0.0,
      (sum, p) => sum + ((p['precio'] as double) * (p['cantidad'] as int)),
    );
    return fromAssigned + fromPending;
  }

  bool get _tieneProductos =>
      _cantidades.values.any((q) => q > 0) || _productosPendientes.isNotEmpty;

  void _mostrarAgregarPendiente() {
    final nombreCtrl = TextEditingController();
    final precioCtrl = TextEditingController();
    final cantidadCtrl = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Producto pendiente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Agrega un producto que no tienes en tu inventario asignado. '
              'Se sumará al total sin descontar stock.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nombreCtrl,
              decoration: const InputDecoration(labelText: 'Nombre del producto'),
              textCapitalization: TextCapitalization.words,
            ),
            TextField(
              controller: precioCtrl,
              decoration: const InputDecoration(labelText: 'Precio unitario'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            TextField(
              controller: cantidadCtrl,
              decoration: const InputDecoration(labelText: 'Cantidad'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final nombre = nombreCtrl.text.trim();
              final precio = double.tryParse(precioCtrl.text.replaceAll(',', '.')) ?? 0;
              final cantidad = int.tryParse(cantidadCtrl.text) ?? 1;
              if (nombre.isEmpty || precio <= 0 || cantidad <= 0) return;
              setState(() {
                _productosPendientes.add({
                  'nombre': nombre,
                  'precio': precio,
                  'cantidad': cantidad,
                });
              });
              Navigator.pop(ctx);
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  Future<void> _registrarVenta() async {
    setState(() => _intentoRegistrar = true);
    if (!_formKey.currentState!.validate()) return;
    if (_zona == null) {
      appSnackbar(context, 'Selecciona una zona', error: true);
      return;
    }
    if (!_tieneProductos) {
      appSnackbar(context, 'Agrega al menos un producto', error: true);
      return;
    }
    if (_foto == null) {
      appSnackbar(context, 'La foto de la venta es obligatoria', error: true);
      return;
    }

    setState(() => _guardando = true);

    final asignaciones =
        ref.read(asignacionProductoControllerProvider).asignaciones;

    final ctrl = ref.read(tarjetaControllerProvider.notifier);
    ctrl.limpiarCarrito();
    for (final a in asignaciones) {
      final qty = _cantidades[a.codigoBarras] ?? 0;
      if (qty > 0) {
        ctrl.agregarProductoDesdeAsignacion(a, qty);
      }
    }
    for (final p in _productosPendientes) {
      ctrl.agregarProductoPendiente(
        nombre: p['nombre'] as String,
        precioUnitario: p['precio'] as double,
        cantidad: p['cantidad'] as int,
      );
    }

    final tarjetaId = await ctrl.crearVenta(
      asesoraUid: widget.asesoraUid,
      nombreAsesora: widget.asesoraNombre,
      nombreCliente: _nombreCtrl.text.trim(),
      telefonoCliente: _telefonoCtrl.text.trim(),
      direccionCliente: _direccionCtrl.text.trim(),
      tipoPago: TipoPago.cuotas,
      frecuenciaPago: _frecuencia,
      numCuotas: _numCuotas,
      zona: _zona!,
      descripcion: _descripcionCtrl.text.trim().isEmpty
          ? null
          : _descripcionCtrl.text.trim(),
      foto: _foto,
    );

    if (tarjetaId != null) {
      await ref
          .read(asignacionProductoControllerProvider.notifier)
          .registrarVentas(widget.asesoraUid, _cantidades);
    }

    setState(() => _guardando = false);

    if (mounted) {
      if (tarjetaId != null) {
        appSnackbar(context, 'Venta registrada exitosamente');
        Navigator.pop(context);
      } else {
        final err = ref.read(tarjetaControllerProvider).error ?? 'Error';
        appSnackbar(context, err, error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final asignaciones = ref.watch(asignacionProductoControllerProvider).asignaciones;
    final subtotal = _calcSubtotal(asignaciones);
    final montoCuota = _numCuotas > 0 ? subtotal / _numCuotas : 0.0;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final violetColor = isDark ? AppColors.darkViolet : AppColors.violet;
    final violetBg = isDark ? AppColors.darkViolet50 : AppColors.violet50;
    final amberColor = isDark ? AppColors.darkAmber : AppColors.amber;

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Venta')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SectionLabel('CLIENTE'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nombreCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Nombre completo',
                prefixIcon: Icon(Icons.person_outline, size: 20),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _telefonoCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: const InputDecoration(
                hintText: 'Teléfono (10 dígitos)',
                prefixIcon: Icon(Icons.phone_outlined, size: 20),
              ),
              validator: (v) {
                final n = v?.trim() ?? '';
                if (n.length < 7) return 'Mínimo 7 dígitos';
                if (n.length > 10) return 'Máximo 10 dígitos';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _direccionCtrl,
              decoration: const InputDecoration(
                hintText: 'Dirección',
                prefixIcon: Icon(Icons.location_on_outlined, size: 20),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _zona,
              decoration: const InputDecoration(
                hintText: 'Zona *',
                prefixIcon: Icon(Icons.map_outlined, size: 20),
              ),
              items: kZonas.map((z) => DropdownMenuItem(value: z, child: Text(z))).toList(),
              onChanged: (v) => setState(() => _zona = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descripcionCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Descripción (opcional) — casa, calle, referencia...',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 48),
                  child: Icon(Icons.notes_outlined, size: 20),
                ),
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 24),

            const SectionLabel('PRODUCTOS ASIGNADOS'),
            const SizedBox(height: 12),
            if (asignaciones.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppColors.darkInk200 : AppColors.lightInk200,
                  ),
                ),
                child: Text(
                  'No tienes productos asignados',
                  style: TextStyle(color: cs.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              )
            else ...[
              Builder(builder: (_) {
                final seleccionados = asignaciones
                    .where((a) => (_cantidades[a.codigoBarras] ?? 0) > 0)
                    .toList();
                final noSeleccionados = asignaciones
                    .where((a) => (_cantidades[a.codigoBarras] ?? 0) == 0)
                    .toList();
                final filtrados = _busqueda.isEmpty
                    ? noSeleccionados
                    : noSeleccionados
                        .where((a) => a.nombreProducto
                            .toLowerCase()
                            .contains(_busqueda.toLowerCase()))
                        .toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (seleccionados.isNotEmpty) ...[
                      Text(
                        'EN CARRITO',
                        style: TextStyle(
                          color: violetColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...seleccionados.map((a) => _ProductoRow(
                            asignacion: a,
                            cantidad: _cantidades[a.codigoBarras] ?? 0,
                            fmt: fmt,
                            isDark: isDark,
                            cs: cs,
                            violetColor: violetColor,
                            onChanged: (qty) =>
                                setState(() => _cantidades[a.codigoBarras] = qty),
                          )),
                      const SizedBox(height: 16),
                      Text(
                        'AGREGAR MÁS',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _busqueda = v),
                      decoration: InputDecoration(
                        hintText: 'Buscar producto...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _busqueda.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _busqueda = '');
                                },
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (filtrados.isEmpty && noSeleccionados.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Sin resultados para "$_busqueda"',
                          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else ...[
                      ...filtrados.take(10).map((a) => _ProductoRow(
                            asignacion: a,
                            cantidad: _cantidades[a.codigoBarras] ?? 0,
                            fmt: fmt,
                            isDark: isDark,
                            cs: cs,
                            violetColor: violetColor,
                            onChanged: (qty) =>
                                setState(() => _cantidades[a.codigoBarras] = qty),
                          )),
                      if (filtrados.length > 10)
                        _BuscarMasAsesoraButton(
                          restantes: filtrados.length - 10,
                          violetColor: violetColor,
                          violetBg: violetBg,
                          onTap: () async {
                            final items = asignaciones
                                .map((a) => ProductoSelectorItem(
                                      codigo: a.codigoBarras,
                                      nombre: a.nombreProducto,
                                      precio: a.precioUnitario,
                                      stockDisponible: a.cantidadDisponible,
                                    ))
                                .toList();
                            final result = await ProductoSelectorScreen.abrir(
                              context,
                              productos: items,
                              cantidadesIniciales: Map.from(_cantidades),
                              accentColor: violetColor,
                              accentBg: violetBg,
                            );
                            if (result != null) {
                              setState(() => result.forEach(
                                    (k, v) => _cantidades[k] = v,
                                  ));
                            }
                          },
                        ),
                    ],
                  ],
                );
              }),
            ],

            const SizedBox(height: 16),

            const SectionLabel('PRODUCTOS PENDIENTES'),
            const SizedBox(height: 8),
            if (_productosPendientes.isNotEmpty) ...[
              ..._productosPendientes.asMap().entries.map((entry) {
                final i = entry.key;
                final p = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: amberColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: amberColor.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.pending_outlined, color: amberColor, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p['nombre'] as String,
                              style: TextStyle(
                                color: cs.onSurface,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '${p['cantidad']}x \$${fmt.format((p['precio'] as double).toInt())}',
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: amberColor, size: 18),
                        onPressed: () => setState(() => _productosPendientes.removeAt(i)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
            OutlinedButton.icon(
              onPressed: _mostrarAgregarPendiente,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Agregar producto pendiente'),
              style: OutlinedButton.styleFrom(
                foregroundColor: amberColor,
                side: BorderSide(color: amberColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Foto de la venta (requerida) ──────────────────────────
            const SectionLabel('FOTO DE LA VENTA'),
            const SizedBox(height: 12),
            FotoPickerTile(
              valor: _foto,
              requerida: true,
              mostrarError: _intentoRegistrar && _foto == null,
              accentColor: violetColor,
              accentBg: violetBg,
              onChanged: (f) => setState(() => _foto = f),
            ),

            const SizedBox(height: 24),

            const SectionLabel('FRECUENCIA DE PAGO'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FreqOption(
                    label: 'Diaria',
                    icon: Icons.today_outlined,
                    selected: _frecuencia == FrecuenciaPago.diaria,
                    accentColor: violetColor,
                    accentBg: violetBg,
                    onTap: () =>
                        setState(() => _frecuencia = FrecuenciaPago.diaria),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FreqOption(
                    label: 'Semanal',
                    icon: Icons.date_range_outlined,
                    selected: _frecuencia == FrecuenciaPago.semanal,
                    accentColor: violetColor,
                    accentBg: violetBg,
                    onTap: () =>
                        setState(() => _frecuencia = FrecuenciaPago.semanal),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            const SectionLabel('NÚMERO DE CUOTAS'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [2, 4, 6, 8, 12].map((n) {
                final sel = _numCuotas == n;
                return GestureDetector(
                  onTap: () => setState(() => _numCuotas = n),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: sel ? violetColor : cs.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: sel
                            ? violetColor
                            : (isDark
                                ? AppColors.darkInk200
                                : AppColors.lightInk200),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$n',
                        style: TextStyle(
                          color: sel ? Colors.white : cs.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.darkInk200 : AppColors.lightInk200,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Subtotal:', style: TextStyle(color: cs.onSurfaceVariant)),
                      Text(
                        '\$${fmt.format(subtotal)}',
                        style: TextStyle(
                          color: cs.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Cuota ${_frecuencia == FrecuenciaPago.diaria ? "diaria" : "semanal"}:',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                      Text(
                        '\$${fmt.format(montoCuota)}',
                        style: TextStyle(
                          color: violetColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _guardando ? null : _registrarVenta,
                style: ElevatedButton.styleFrom(
                  backgroundColor: violetColor,
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
                        'Registrar Venta',
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
      ),
    );
  }
}

class _ProductoRow extends StatelessWidget {
  final AsignacionProductoModel asignacion;
  final int cantidad;
  final NumberFormat fmt;
  final bool isDark;
  final ColorScheme cs;
  final Color violetColor;
  final ValueChanged<int> onChanged;

  const _ProductoRow({
    required this.asignacion,
    required this.cantidad,
    required this.fmt,
    required this.isDark,
    required this.cs,
    required this.violetColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final disponible = asignacion.cantidadDisponible;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkInk200 : AppColors.lightInk200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  asignacion.nombreProducto,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '\$${fmt.format(asignacion.precioUnitario)}',
                style: TextStyle(
                  color: violetColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Disponible: $disponible',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              CounterButton(
                icon: Icons.remove,
                enabled: cantidad > 0,
                accentColor: violetColor,
                onTap: () => onChanged(cantidad - 1),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '$cantidad',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              CounterButton(
                icon: Icons.add,
                enabled: cantidad < disponible,
                accentColor: violetColor,
                onTap: () => onChanged(cantidad + 1),
              ),
              const Spacer(),
              if (cantidad > 0)
                Text(
                  'Subtotal: \$${fmt.format(asignacion.precioUnitario * cantidad)}',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BuscarMasAsesoraButton extends StatelessWidget {
  final int restantes;
  final Color violetColor;
  final Color violetBg;
  final VoidCallback onTap;

  const _BuscarMasAsesoraButton({
    required this.restantes,
    required this.violetColor,
    required this.violetBg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: violetBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: violetColor.withAlpha(80)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_rounded, size: 18, color: violetColor),
            const SizedBox(width: 8),
            Text(
              'Buscar más ($restantes producto${restantes == 1 ? '' : 's'})',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: violetColor,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.arrow_forward_ios_rounded, size: 13, color: violetColor),
          ],
        ),
      ),
    );
  }
}
