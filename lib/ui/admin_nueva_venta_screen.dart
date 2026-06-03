import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../providers.dart';
import '../models/tarjeta_model.dart';
import '../models/usuario_model.dart';
import '../models/producto_model.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_snackbar.dart';
import 'widgets/shared_widgets.dart';
import 'widgets/foto_picker.dart';
import 'producto_selector_screen.dart';

class AdminNuevaVentaScreen extends ConsumerStatefulWidget {
  const AdminNuevaVentaScreen({super.key});

  @override
  ConsumerState<AdminNuevaVentaScreen> createState() =>
      _AdminNuevaVentaScreenState();
}

class _AdminNuevaVentaScreenState extends ConsumerState<AdminNuevaVentaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  UsuarioModel? _asesoraSeleccionada;
  String? _zona;
  FrecuenciaPago _frecuencia = FrecuenciaPago.semanal;
  int _numCuotas = 4;
  final Map<String, int> _cantidades = {};
  String _busqueda = '';
  bool _guardando = false;
  XFile? _foto;
  bool _intentoRegistrar = false;

  final fmt = NumberFormat('#,###', 'es_CO');

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _direccionCtrl.dispose();
    _descripcionCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  double get _subtotal {
    final productos = ref.read(productoControllerProvider).productos;
    return productos.fold(0.0, (sum, p) {
      final qty = _cantidades[p.codigoBarras] ?? 0;
      return sum + (p.precioUnitario * qty);
    });
  }

  double get _montoCuota => _numCuotas > 0 ? _subtotal / _numCuotas : 0;

  bool get _tieneProductos => _cantidades.values.any((q) => q > 0);

  Future<void> _registrarVenta() async {
    setState(() => _intentoRegistrar = true);
    if (!_formKey.currentState!.validate()) return;
    if (_asesoraSeleccionada == null) {
      appSnackbar(context, 'Selecciona quién realiza la venta', error: true);
      return;
    }
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

    final productos = ref.read(productoControllerProvider).productos;
    final ctrl = ref.read(tarjetaControllerProvider.notifier);
    ctrl.limpiarCarrito();

    for (final p in productos) {
      final qty = _cantidades[p.codigoBarras] ?? 0;
      if (qty > 0) ctrl.agregarAlCarrito(p, qty);
    }

    final tarjetaId = await ctrl.crearVenta(
      asesoraUid: _asesoraSeleccionada!.uid,
      nombreAsesora: _asesoraSeleccionada!.nombre,
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

    setState(() => _guardando = false);

    if (!mounted) return;
    if (tarjetaId != null) {
      appSnackbar(context, 'Venta registrada exitosamente');
      Navigator.pop(context);
    } else {
      final err = ref.read(tarjetaControllerProvider).error ?? 'Error';
      appSnackbar(context, err, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final jadeColor = isDark ? AppColors.darkJade : AppColors.brandJade;
    final jadeBg = isDark ? AppColors.darkJade50 : AppColors.lightJade50;
    final adminActual = ref.watch(usuarioActualProvider);
    final asesoras = ref.watch(asesorasProvider);
    final todosLosVendedores = [
      ?adminActual,
      ...asesoras,
    ];
    final productos = ref.watch(productoControllerProvider).productos;
    final productosFiltrados = _busqueda.isEmpty
        ? productos
        : productos
            .where((p) =>
                p.nombre.toLowerCase().contains(_busqueda.toLowerCase()))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Venta'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Vendedor ─────────��───────────────────────────────────────────
            const SectionHeader(icon: Icons.person_pin_outlined, label: 'QUIÉN REALIZA LA VENTA'),
            const SizedBox(height: 12),
            DropdownButtonFormField<UsuarioModel>(
              initialValue: _asesoraSeleccionada,
              decoration: const InputDecoration(
                hintText: 'Seleccionar vendedor *',
                prefixIcon: Icon(Icons.person_outline, size: 20),
              ),
              items: todosLosVendedores.map((a) {
                final esAdmin = a.rol == RolUsuario.admin || a.rol == RolUsuario.superAdmin;
                return DropdownMenuItem(
                  value: a,
                  child: Text(esAdmin ? '${a.nombre} (Admin)' : a.nombre),
                );
              }).toList(),
              onChanged: (v) => setState(() => _asesoraSeleccionada = v),
              validator: (v) => v == null ? 'Requerido' : null,
            ),

            const SizedBox(height: 24),

            // ── Cliente ─────────────────────────────────────────────���────────
            const SectionHeader(icon: Icons.person_rounded, label: 'CLIENTE'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nombreCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Nombre completo *',
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
                hintText: 'Teléfono (10 dígitos) *',
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
                hintText: 'Dirección *',
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
              items: kZonas
                  .map((z) => DropdownMenuItem(value: z, child: Text(z)))
                  .toList(),
              onChanged: (v) => setState(() => _zona = v),
              validator: (v) => v == null ? 'Selecciona una zona' : null,
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

            // ── Productos ──────────────────────────────────────────────────���─
            const SectionHeader(icon: Icons.inventory_2_outlined, label: 'PRODUCTOS'),
            const SizedBox(height: 12),
            if (productos.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No hay productos en inventario',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                ),
              )
            else ...[
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
              if (productosFiltrados.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text(
                      'Sin resultados para "$_busqueda"',
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                    ),
                  ),
                )
              else
                Builder(builder: (_) {
                  const kMax = 10;
                  final sel = productosFiltrados
                      .where((p) => (_cantidades[p.codigoBarras] ?? 0) > 0)
                      .toList();
                  final noSel = productosFiltrados
                      .where((p) => (_cantidades[p.codigoBarras] ?? 0) == 0)
                      .toList();
                  final cupoRestante = (kMax - sel.length).clamp(0, noSel.length);
                  final visibles = [...sel, ...noSel.take(cupoRestante)];
                  final restantes = noSel.length - cupoRestante;

                  return Column(
                    children: [
                      ...visibles.map((p) => _ProductoRow(
                            producto: p,
                            cantidad: _cantidades[p.codigoBarras] ?? 0,
                            fmt: fmt,
                            isDark: isDark,
                            jadeColor: jadeColor,
                            jadeBg: jadeBg,
                            onChanged: (qty) =>
                                setState(() => _cantidades[p.codigoBarras] = qty),
                          )),
                      if (restantes > 0)
                        _BuscarMasButton(
                          restantes: restantes,
                          onTap: () async {
                            final items = productos
                                .map((p) => ProductoSelectorItem(
                                      codigo: p.codigoBarras,
                                      nombre: p.nombre,
                                      precio: p.precioUnitario,
                                      stockDisponible: p.cantidadStock,
                                    ))
                                .toList();
                            final result = await ProductoSelectorScreen.abrir(
                              context,
                              productos: items,
                              cantidadesIniciales: Map.from(_cantidades),
                              accentColor: jadeColor,
                              accentBg: jadeBg,
                            );
                            if (result != null) {
                              setState(() => result.forEach(
                                    (k, v) => _cantidades[k] = v,
                                  ));
                            }
                          },
                        ),
                    ],
                  );
                }),
            ],

            const SizedBox(height: 24),

            // ── Foto de la venta (requerida) ──────────────────────────────────
            const SectionHeader(
              icon: Icons.photo_camera_outlined,
              label: 'FOTO DE LA VENTA',
            ),
            const SizedBox(height: 12),
            FotoPickerTile(
              valor: _foto,
              requerida: true,
              mostrarError: _intentoRegistrar && _foto == null,
              accentColor: jadeColor,
              accentBg: jadeBg,
              onChanged: (f) => setState(() => _foto = f),
            ),

            const SizedBox(height: 24),

            // ── Frecuencia ───────────────────────────────────────────────────
            const SectionHeader(
              icon: Icons.calendar_today_outlined,
              label: 'FRECUENCIA DE PAGO',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FreqOption(
                    label: 'Diaria',
                    icon: Icons.today_outlined,
                    selected: _frecuencia == FrecuenciaPago.diaria,
                    accentColor: jadeColor,
                    accentBg: jadeBg,
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
                    accentColor: jadeColor,
                    accentBg: jadeBg,
                    onTap: () =>
                        setState(() => _frecuencia = FrecuenciaPago.semanal),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Cuotas ───────────────────────────────────────────────────────
            const SectionHeader(
              icon: Icons.payments_outlined,
              label: 'NÚMERO DE CUOTAS',
            ),
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
                      color: sel
                          ? jadeColor
                          : (isDark
                              ? AppColors.darkInk100
                              : AppColors.lightInk100),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: sel
                            ? jadeColor
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

            // ── Resumen ─────────────────���────────────────────────────���───────
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
                      Text('Total:', style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
                      Text(
                        '\$${fmt.format(_subtotal)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Cuota ${_frecuencia == FrecuenciaPago.diaria ? "diaria" : "semanal"}:',
                        style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                      ),
                      Text(
                        '\$${fmt.format(_montoCuota)}',
                        style: TextStyle(
                          color: jadeColor,
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

            // ── Botón registrar ───────────────────���──────────────────────────
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _guardando ? null : _registrarVenta,
                child: _guardando
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: cs.onPrimary,
                        ),
                      )
                    : const Text(
                        'Registrar Venta',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

// ── _ProductoRow es único a esta pantalla (usa ProductoModel) ────────────���────
class _ProductoRow extends StatelessWidget {
  final ProductoModel producto;
  final int cantidad;
  final NumberFormat fmt;
  final bool isDark;
  final Color jadeColor;
  final Color jadeBg;
  final ValueChanged<int> onChanged;

  const _ProductoRow({
    required this.producto,
    required this.cantidad,
    required this.fmt,
    required this.isDark,
    required this.jadeColor,
    required this.jadeBg,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final disponible = producto.cantidadStock;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
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
                  producto.nombre,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              Text(
                '\$${fmt.format(producto.precioUnitario)}',
                style: TextStyle(color: jadeColor, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Stock: $disponible',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              CounterButton(
                icon: Icons.remove,
                enabled: cantidad > 0,
                accentColor: jadeColor,
                accentBg: jadeBg,
                onTap: () => onChanged(cantidad - 1),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '$cantidad',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              CounterButton(
                icon: Icons.add,
                enabled: cantidad < disponible,
                accentColor: jadeColor,
                accentBg: jadeBg,
                onTap: () => onChanged(cantidad + 1),
              ),
              const Spacer(),
              if (cantidad > 0)
                Text(
                  '\$${fmt.format(producto.precioUnitario * cantidad)}',
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BuscarMasButton extends StatelessWidget {
  final int restantes;
  final VoidCallback onTap;
  const _BuscarMasButton({required this.restantes, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final jadeColor = isDark ? AppColors.darkJade : AppColors.brandJade;
    final jadeBg = isDark ? AppColors.darkJade50 : AppColors.lightJade50;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: jadeBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: jadeColor.withAlpha(80)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_rounded, size: 18, color: jadeColor),
            const SizedBox(width: 8),
            Text(
              'Buscar más ($restantes producto${restantes == 1 ? '' : 's'})',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: jadeColor,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.arrow_forward_ios_rounded, size: 13, color: jadeColor),
          ],
        ),
      ),
    );
  }
}
