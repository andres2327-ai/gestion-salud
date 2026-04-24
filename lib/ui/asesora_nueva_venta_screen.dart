import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers.dart';
import '../models/tarjeta_model.dart';
import '../models/asignacion_producto_model.dart';

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
  bool _guardando = false;

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
    super.dispose();
  }

  double get _subtotal {
    final asignaciones = ref.read(asignacionProductoControllerProvider).asignaciones;
    return asignaciones.fold(0.0, (sum, a) {
      final qty = _cantidades[a.codigoBarras] ?? 0;
      return sum + (a.precioUnitario * qty);
    });
  }

  double get _montoCuota => _numCuotas > 0 ? _subtotal / _numCuotas : 0;

  bool get _tieneProductos =>
      _cantidades.values.any((q) => q > 0);

  Future<void> _registrarVenta() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_tieneProductos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega al menos un producto'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _guardando = true);

    final asignaciones =
        ref.read(asignacionProductoControllerProvider).asignaciones;

    // Cargar productos seleccionados al carrito
    final ctrl = ref.read(tarjetaControllerProvider.notifier);
    ctrl.limpiarCarrito();
    for (final a in asignaciones) {
      final qty = _cantidades[a.codigoBarras] ?? 0;
      if (qty > 0) {
        // Usamos un ProductoModel simulado desde la asignación
        ctrl.agregarProductoDesdeAsignacion(a, qty);
      }
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
    );

    // Actualizar cantidades vendidas en asignaciones
    if (tarjetaId != null) {
      final service = ref.read(asignacionProductoServiceProvider);
      for (final a in asignaciones) {
        final qty = _cantidades[a.codigoBarras] ?? 0;
        if (qty > 0) {
          await service.registrarVenta(widget.asesoraUid, a.codigoBarras, qty);
        }
      }
    }

    setState(() => _guardando = false);

    if (mounted) {
      if (tarjetaId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Venta registrada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        final err = ref.read(tarjetaControllerProvider).error ?? 'Error';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final asignaciones = ref.watch(asignacionProductoControllerProvider).asignaciones;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1123),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1C3A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Nueva Venta',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Datos del cliente
            _SectionLabel(label: 'CLIENTE'),
            const SizedBox(height: 12),
            _buildField(
              controller: _nombreCtrl,
              hint: 'Nombre completo',
              icon: Icons.person_outline,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _telefonoCtrl,
              hint: 'Teléfono',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) =>
                  (v == null || v.trim().length < 7) ? 'Inválido' : null,
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _direccionCtrl,
              hint: 'Dirección',
              icon: Icons.location_on_outlined,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),

            const SizedBox(height: 24),

            // Productos asignados
            _SectionLabel(label: 'PRODUCTOS ASIGNADOS'),
            const SizedBox(height: 12),
            if (asignaciones.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1C3A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'No tienes productos asignados',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ...asignaciones.map((a) => _ProductoRow(
                    asignacion: a,
                    cantidad: _cantidades[a.codigoBarras] ?? 0,
                    fmt: fmt,
                    onChanged: (qty) {
                      setState(() => _cantidades[a.codigoBarras] = qty);
                    },
                  )),

            const SizedBox(height: 24),

            // Frecuencia de pago
            _SectionLabel(label: 'FRECUENCIA DE PAGO'),
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
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Número de cuotas
            _SectionLabel(label: 'NÚMERO DE CUOTAS'),
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
                          ? Colors.tealAccent
                          : const Color(0xFF1A1C3A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '$n',
                        style: TextStyle(
                          color: sel ? Colors.black : Colors.white,
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

            // Resumen
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1C3A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Subtotal:',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        '\$${fmt.format(_subtotal)}',
                        style: const TextStyle(
                          color: Colors.white,
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
                        style: const TextStyle(color: Colors.grey),
                      ),
                      Text(
                        '\$${fmt.format(_montoCuota)}',
                        style: const TextStyle(
                          color: Colors.tealAccent,
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

            // Botón registrar
            GestureDetector(
              onTap: _guardando ? null : _registrarVenta,
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: _guardando ? Colors.grey : Colors.tealAccent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: _guardando
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text(
                          'Registrar Venta',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.grey, size: 20),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Colors.tealAccent,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _FreqOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _FreqOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
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
              ? Colors.tealAccent.withAlpha(30)
              : const Color(0xFF1A1C3A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? Colors.tealAccent : Colors.transparent,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? Colors.tealAccent : Colors.grey,
              size: 22,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.tealAccent : Colors.grey,
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
  final AsignacionProductoModel asignacion;
  final int cantidad;
  final NumberFormat fmt;
  final ValueChanged<int> onChanged;

  const _ProductoRow({
    required this.asignacion,
    required this.cantidad,
    required this.fmt,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final disponible = asignacion.cantidadDisponible;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1C3A),
        borderRadius: BorderRadius.circular(12),
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '\$${fmt.format(asignacion.precioUnitario)}',
                style: const TextStyle(
                  color: Colors.tealAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Disponible: $disponible',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _CounterBtn(
                icon: Icons.remove,
                onTap: cantidad > 0 ? () => onChanged(cantidad - 1) : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '$cantidad',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _CounterBtn(
                icon: Icons.add,
                onTap: cantidad < disponible
                    ? () => onChanged(cantidad + 1)
                    : null,
              ),
              const Spacer(),
              if (cantidad > 0)
                Text(
                  'Subtotal: \$${fmt.format(asignacion.precioUnitario * cantidad)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
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
  final VoidCallback? onTap;

  const _CounterBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: onTap != null
              ? Colors.tealAccent.withAlpha(30)
              : Colors.grey.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: onTap != null ? Colors.tealAccent : Colors.grey,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: onTap != null ? Colors.tealAccent : Colors.grey,
        ),
      ),
    );
  }
}
