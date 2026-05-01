import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers.dart';
import '../models/tarjeta_model.dart';
import '../models/usuario_model.dart';
import '../models/producto_model.dart';

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

  UsuarioModel? _asesoraSeleccionada;
  String? _zona;
  FrecuenciaPago _frecuencia = FrecuenciaPago.semanal;
  int _numCuotas = 4;
  final Map<String, int> _cantidades = {};
  bool _guardando = false;

  final fmt = NumberFormat('#,###', 'es_CO');

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(usuarioControllerProvider.notifier).cargar();
    });
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _direccionCtrl.dispose();
    _descripcionCtrl.dispose();
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
    if (!_formKey.currentState!.validate()) return;
    if (_asesoraSeleccionada == null) {
      _snack('Selecciona una asesora', error: true);
      return;
    }
    if (_zona == null) {
      _snack('Selecciona una zona', error: true);
      return;
    }
    if (!_tieneProductos) {
      _snack('Agrega al menos un producto', error: true);
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
    );

    setState(() => _guardando = false);

    if (!mounted) return;
    if (tarjetaId != null) {
      _snack('Venta registrada exitosamente');
      Navigator.pop(context);
    } else {
      final err = ref.read(tarjetaControllerProvider).error ?? 'Error';
      _snack(err, error: true);
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Theme.of(context).colorScheme.error : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final asesoras = ref.watch(asesorasProvider);
    final productos = ref.watch(productoControllerProvider).productos;

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
            // ── Asesora ──────────────────────────────────────────────────────
            _SectionHeader(icon: Icons.person_pin_outlined, label: 'ASESORA'),
            const SizedBox(height: 12),
            DropdownButtonFormField<UsuarioModel>(
              initialValue: _asesoraSeleccionada,
              decoration: const InputDecoration(
                hintText: 'Seleccionar asesora *',
                prefixIcon: Icon(Icons.person_outline, size: 20),
              ),
              items: asesoras.map((a) {
                return DropdownMenuItem(value: a, child: Text(a.nombre));
              }).toList(),
              onChanged: (v) => setState(() => _asesoraSeleccionada = v),
              validator: (v) => v == null ? 'Requerido' : null,
            ),

            const SizedBox(height: 24),

            // ── Cliente ───────────────────────────────────────────────────────
            _SectionHeader(icon: Icons.person_rounded, label: 'CLIENTE'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nombreCtrl,
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
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                hintText: 'Teléfono *',
                prefixIcon: Icon(Icons.phone_outlined, size: 20),
              ),
              validator: (v) =>
                  (v == null || v.trim().length < 7) ? 'Inválido' : null,
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

            // Zona
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

            // Descripción
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

            // ── Productos ─────────────────────────────────────────────────────
            _SectionHeader(icon: Icons.inventory_2_outlined, label: 'PRODUCTOS'),
            const SizedBox(height: 12),
            if (productos.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No hay productos en inventario',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              ...productos.map(
                (p) => _ProductoRow(
                  producto: p,
                  cantidad: _cantidades[p.codigoBarras] ?? 0,
                  fmt: fmt,
                  onChanged: (qty) =>
                      setState(() => _cantidades[p.codigoBarras] = qty),
                ),
              ),

            const SizedBox(height: 24),

            // ── Frecuencia ────────────────────────────────────────────────────
            _SectionHeader(
              icon: Icons.calendar_today_outlined,
              label: 'FRECUENCIA DE PAGO',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _FreqOption(
                    label: 'Diaria',
                    icon: Icons.today_outlined,
                    selected: _frecuencia == FrecuenciaPago.diaria,
                    onTap: () =>
                        setState(() => _frecuencia = FrecuenciaPago.diaria),
                    colorScheme: colorScheme,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FreqOption(
                    label: 'Semanal',
                    icon: Icons.date_range_outlined,
                    selected: _frecuencia == FrecuenciaPago.semanal,
                    onTap: () =>
                        setState(() => _frecuencia = FrecuenciaPago.semanal),
                    colorScheme: colorScheme,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Cuotas ────────────────────────────────────────────────────────
            _SectionHeader(
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
                          ? colorScheme.primary
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '$n',
                        style: TextStyle(
                          color: sel
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
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

            // ── Resumen ───────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total:', style: textTheme.bodyMedium),
                      Text(
                        '\$${fmt.format(_subtotal)}',
                        style: textTheme.bodyMedium?.copyWith(
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
                        style: textTheme.bodyMedium,
                      ),
                      Text(
                        '\$${fmt.format(_montoCuota)}',
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Botón registrar ───────────────────────────────────────────────
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
                          color: colorScheme.onPrimary,
                        ),
                      )
                    : const Text(
                        'Registrar Venta',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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

// ── Widgets locales ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icon, color: colorScheme.primary, size: 16),
        const SizedBox(width: 8),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Divider(color: colorScheme.outlineVariant)),
      ],
    );
  }
}

class _FreqOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _FreqOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? colorScheme.primary : Colors.transparent,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              size: 22,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductoRow extends StatelessWidget {
  final ProductoModel producto;
  final int cantidad;
  final NumberFormat fmt;
  final ValueChanged<int> onChanged;

  const _ProductoRow({
    required this.producto,
    required this.cantidad,
    required this.fmt,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final disponible = producto.cantidadStock;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
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
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '\$${fmt.format(producto.precioUnitario)}',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Stock: $disponible',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _CounterBtn(
                icon: Icons.remove,
                enabled: cantidad > 0,
                colorScheme: colorScheme,
                onTap: () => onChanged(cantidad - 1),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '$cantidad',
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _CounterBtn(
                icon: Icons.add,
                enabled: cantidad < disponible,
                colorScheme: colorScheme,
                onTap: () => onChanged(cantidad + 1),
              ),
              const Spacer(),
              if (cantidad > 0)
                Text(
                  '\$${fmt.format(producto.precioUnitario * cantidad)}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CounterBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _CounterBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled ? colorScheme.primary : colorScheme.outline,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? colorScheme.primary : colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
