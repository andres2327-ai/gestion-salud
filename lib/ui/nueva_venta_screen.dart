// views/sales/nueva_venta_screen.dart
// Formulario completo para registrar una nueva venta
// Arquitectura: Vista pura (MVC) — sin lógica de negocio ni llamadas a Firebase aquí

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_theme.dart';
import './custom_text_field.dart';
import './sale_product_card.dart';
import './product_picker_sheet.dart';

// ── Enum para tipo de pago ──────────────────────────────────────────────────
enum TipoPago { contado, cuotas }

// ── Modelo simple para venta ────────────────────────────────────────────────
class NuevaVentaForm {
  final String nombreCliente;
  final String telefonoCliente;
  final String direccionCliente;
  final TipoPago tipoPago;
  final int numCuotas;
  final double montoCuota;
  final List<ProductoVentaItem> productos;
  final String asesoraUid;

  NuevaVentaForm({
    required this.nombreCliente,
    required this.telefonoCliente,
    required this.direccionCliente,
    required this.tipoPago,
    required this.numCuotas,
    required this.montoCuota,
    required this.productos,
    required this.asesoraUid,
  });

  double get totalVenta => productos.fold(0, (sum, p) => sum + p.subtotal);
}

class NuevaVentaScreen extends StatefulWidget {
  // En producción pasarás el usuario logueado desde el Controller
  final String asesoraUid;
  final String asesoraNombre;

  const NuevaVentaScreen({
    super.key,
    required this.asesoraUid,
    required this.asesoraNombre,
  });

  @override
  State<NuevaVentaScreen> createState() => _NuevaVentaScreenState();
}

class _NuevaVentaScreenState extends State<NuevaVentaScreen> {
  final _formKey = GlobalKey<FormState>();

  // ── Controladores ────────────────────────────────────────────────────────
  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _cuotasCtrl = TextEditingController(text: '1');

  // ── Estado local ────────────────────────────────────────────────────────
  TipoPago _tipoPago = TipoPago.contado;
  List<ProductoVentaItem> _carrito = [];
  bool _guardando = false;

  // ── Computed ─────────────────────────────────────────────────────────────
  double get _totalVenta => _carrito.fold(0, (sum, p) => sum + p.subtotal);

  double get _montoCuota {
    final n = int.tryParse(_cuotasCtrl.text) ?? 1;
    if (n <= 0) return _totalVenta;
    return _totalVenta / n;
  }

  // ── Carrito helpers ──────────────────────────────────────────────────────
  void _agregarProducto(ProductoInventario p) {
    setState(() {
      _carrito.add(
        ProductoVentaItem(
          codigoBarras: p.codigoBarras,
          nombre: p.nombre,
          cantidad: 1,
          precioVenta: p.precioUnitario,
        ),
      );
    });
  }

  void _actualizarCantidad(int index, int nuevaCantidad) {
    final p = _carrito[index];
    setState(() {
      _carrito[index] = ProductoVentaItem(
        codigoBarras: p.codigoBarras,
        nombre: p.nombre,
        cantidad: nuevaCantidad,
        precioVenta: p.precioVenta,
      );
    });
  }

  void _eliminarProducto(int index) {
    setState(() => _carrito.removeAt(index));
  }

  // ── Submit ───────────────────────────────────────────────────────────────
  Future<void> _guardarVenta() async {
    if (!_formKey.currentState!.validate()) return;
    if (_carrito.isEmpty) {
      _showSnack('Agrega al menos un producto', isError: true);
      return;
    }

    setState(() => _guardando = true);

    final venta = NuevaVentaForm(
      nombreCliente: _nombreCtrl.text.trim(),
      telefonoCliente: _telefonoCtrl.text.trim(),
      direccionCliente: _direccionCtrl.text.trim(),
      tipoPago: _tipoPago,
      numCuotas: int.tryParse(_cuotasCtrl.text) ?? 1,
      montoCuota: _montoCuota,
      productos: _carrito,
      asesoraUid: widget.asesoraUid,
    );

    // TODO: pasar `venta` al Controller para persistir en Firebase
    await Future.delayed(const Duration(seconds: 1)); // simula escritura

    setState(() => _guardando = false);
    if (mounted) {
      _showSnack('Venta registrada exitosamente ✓');
      Navigator.pop(context, venta); // devuelve al screen anterior
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        backgroundColor: isError ? AppColors.error : AppColors.accentDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _abrirProductPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductPickerSheet(
        onProductoSeleccionado: _agregarProducto,
        codigosYaAgregados: _carrito.map((p) => p.codigoBarras).toList(),
      ),
    );
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _direccionCtrl.dispose();
    _cuotasCtrl.dispose();
    super.dispose();
  }

  // ── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          children: [
            // ── Sección: Vendedor (readonly) ──────────────────────────
            _SectionHeader(icon: Icons.person_rounded, title: 'Vendedor'),
            _VendedorBadge(nombre: widget.asesoraNombre),
            const SizedBox(height: 24),

            // ── Sección: Datos del cliente ────────────────────────────
            _SectionHeader(
              icon: Icons.person_outline_rounded,
              title: 'Datos del Cliente',
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'NOMBRE COMPLETO',
              hint: 'Ej: Carlos Muñoz',
              controller: _nombreCtrl,
              prefixIcon: Icons.person_outline_rounded,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              label: 'TELÉFONO',
              hint: 'Ej: 3001234567',
              controller: _telefonoCtrl,
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) => (v == null || v.trim().length < 7)
                  ? 'Teléfono inválido'
                  : null,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              label: 'DIRECCIÓN',
              hint: 'Ej: Calle 45 # 12-30',
              controller: _direccionCtrl,
              prefixIcon: Icons.location_on_outlined,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 24),

            // ── Sección: Tipo de pago ─────────────────────────────────
            _SectionHeader(
              icon: Icons.credit_card_rounded,
              title: 'Tipo de Pago',
            ),
            const SizedBox(height: 12),
            _TipoPagoSelector(
              selected: _tipoPago,
              onChanged: (t) => setState(() => _tipoPago = t),
            ),
            if (_tipoPago == TipoPago.cuotas) ...[
              const SizedBox(height: 14),
              CustomTextField(
                label: 'NÚMERO DE CUOTAS',
                hint: 'Ej: 6',
                controller: _cuotasCtrl,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.format_list_numbered_rounded,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 1) return 'Mínimo 1 cuota';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              _CuotaPreview(
                numCuotas: int.tryParse(_cuotasCtrl.text) ?? 1,
                montoCuota: _montoCuota,
              ),
            ],
            const SizedBox(height: 24),

            // ── Sección: Productos ────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SectionHeader(
                  icon: Icons.medication_rounded,
                  title: 'Productos',
                ),
                TextButton.icon(
                  onPressed: _abrirProductPicker,
                  icon: const Icon(
                    Icons.add_circle_rounded,
                    color: AppColors.accent,
                    size: 18,
                  ),
                  label: const Text(
                    'Agregar',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Carrito vacío ─────────────────────────────────────────
            if (_carrito.isEmpty)
              _EmptyCart(onTap: _abrirProductPicker)
            else
              Column(
                children: [
                  ...List.generate(
                    _carrito.length,
                    (i) => SaleProductCard(
                      producto: _carrito[i],
                      onRemove: () => _eliminarProducto(i),
                      onCantidadChanged: (n) => _actualizarCantidad(i, n),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _TotalBar(total: _totalVenta),
                ],
              ),

            const SizedBox(height: 32),

            // ── Botón guardar ─────────────────────────────────────────
            _SubmitButton(guardando: _guardando, onTap: _guardarVenta),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() => AppBar(
    leading: IconButton(
      onPressed: () => Navigator.pop(context),
      icon: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 16,
          color: AppColors.textPrimary,
        ),
      ),
    ),
    title: const Text('Nueva Venta'),
    actions: [
      Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.accentGlow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.accent.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.shopping_cart_outlined,
                color: AppColors.accent,
                size: 14,
              ),
              const SizedBox(width: 5),
              Text(
                '${_carrito.length}',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// ── Widgets locales ─────────────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.accent, size: 16),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: AppColors.accent,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Container(height: 1, color: AppColors.divider)),
      ],
    );
  }
}

class _VendedorBadge extends StatelessWidget {
  final String nombre;

  const _VendedorBadge({required this.nombre});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.accentGlow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.accentDark,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: AppColors.background,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text(
                  'Vendedor asignado automáticamente',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.lock_outline_rounded,
            color: AppColors.accent,
            size: 16,
          ),
        ],
      ),
    );
  }
}

class _TipoPagoSelector extends StatelessWidget {
  final TipoPago selected;
  final void Function(TipoPago) onChanged;

  const _TipoPagoSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PagoOption(
            label: 'Contado',
            icon: Icons.payments_outlined,
            selected: selected == TipoPago.contado,
            onTap: () => onChanged(TipoPago.contado),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _PagoOption(
            label: 'Cuotas',
            icon: Icons.calendar_month_rounded,
            selected: selected == TipoPago.cuotas,
            onTap: () => onChanged(TipoPago.cuotas),
          ),
        ),
      ],
    );
  }
}

class _PagoOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _PagoOption({
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
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentGlow : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.inputBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? AppColors.accent : AppColors.textSecondary,
              size: 22,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.accent : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CuotaPreview extends StatelessWidget {
  final int numCuotas;
  final double montoCuota;

  const _CuotaPreview({required this.numCuotas, required this.montoCuota});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.textSecondary,
            size: 15,
          ),
          const SizedBox(width: 8),
          Text(
            '$numCuotas cuotas de ',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          Text(
            '\$${montoCuota.toStringAsFixed(0)}',
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  final VoidCallback onTap;

  const _EmptyCart({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.inputBorder,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.add_shopping_cart_rounded,
              color: AppColors.textHint,
              size: 36,
            ),
            const SizedBox(height: 10),
            const Text(
              'Sin productos',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Toca para agregar productos a la venta',
              style: TextStyle(color: AppColors.textHint, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalBar extends StatelessWidget {
  final double total;

  const _TotalBar({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'TOTAL VENTA',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          Text(
            '\$${total.toStringAsFixed(0)}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final bool guardando;
  final VoidCallback onTap;

  const _SubmitButton({required this.guardando, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: guardando ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          gradient: guardando
              ? null
              : const LinearGradient(
                  colors: [AppColors.accent, AppColors.accentDark],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          color: guardando ? AppColors.card : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: guardando
              ? null
              : [
                  BoxShadow(
                    color: AppColors.accentGlow,
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Center(
          child: guardando
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.accent,
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      color: AppColors.background,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Registrar Venta',
                      style: TextStyle(
                        color: AppColors.background,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
