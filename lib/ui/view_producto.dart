// ui/view_producto.dart

import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_snackbar.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/producto_model.dart';
import '../providers.dart';
import './custom_text_field.dart';
import './barcode_scanner_screen.dart';

class ProductoFormPage extends ConsumerStatefulWidget {
  final ProductoModel? productoEditar;
  const ProductoFormPage({super.key, this.productoEditar});

  @override
  ConsumerState<ProductoFormPage> createState() => _ProductoFormPageState();
}

class _ProductoFormPageState extends ConsumerState<ProductoFormPage> {
  final _formKey       = GlobalKey<FormState>();
  final _codigoCtrl    = TextEditingController();
  final _nombreCtrl    = TextEditingController();
  final _principioCtrl = TextEditingController();
  final _precioCtrl    = TextEditingController();
  final _stockCtrl     = TextEditingController();
  final _stockMinCtrl  = TextEditingController();

  TipoProducto? _tipoSeleccionado;
  DateTime? _fechaVencimiento;
  bool _activo = true;
  bool _guardando = false;

  bool get _modoEdicion => widget.productoEditar != null;

  @override
  void initState() {
    super.initState();
    final p = widget.productoEditar;
    if (p != null) {
      _codigoCtrl.text = p.codigoBarras;
      _nombreCtrl.text = p.nombre;
      _precioCtrl.text = p.precioUnitario.toStringAsFixed(0);
      _stockCtrl.text = p.cantidadStock.toString();
      _tipoSeleccionado = p.tipo;
      _fechaVencimiento = p.fechaVencimiento;
      _activo = p.activo;
    }
  }

  Future<void> _escanearCodigo() async {
    final codigo = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (codigo != null && codigo.isNotEmpty) {
      setState(() => _codigoCtrl.text = codigo);
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_fechaVencimiento == null) {
      appSnackbar(context, 'Selecciona la fecha de vencimiento', error: true);
      return;
    }

    setState(() => _guardando = true);

    bool exito;
    if (_modoEdicion) {
      exito = await ref
          .read(productoControllerProvider.notifier)
          .actualizarProducto(
            widget.productoEditar!.codigoBarras,
            {
              'nombre': _nombreCtrl.text.trim(),
              'tipo': _tipoSeleccionado!.name,
              'precio_unitario': double.tryParse(_precioCtrl.text.trim()) ?? 0,
              'cantidad_stock': int.tryParse(_stockCtrl.text.trim()) ?? 0,
              'fecha_vencimiento': _fechaVencimiento,
              'activo': _activo,
            },
          );
    } else {
      final producto = ProductoModel(
        codigoBarras:     _codigoCtrl.text.trim(),
        nombre:           _nombreCtrl.text.trim(),
        tipo:             _tipoSeleccionado!,
        precioUnitario:   double.tryParse(_precioCtrl.text.trim()) ?? 0,
        cantidadStock:    int.tryParse(_stockCtrl.text.trim()) ?? 0,
        fechaVencimiento: _fechaVencimiento!,
        activo:           _activo,
      );
      exito = await ref
          .read(productoControllerProvider.notifier)
          .agregarProducto(producto);
    }

    if (!mounted) return;
    setState(() => _guardando = false);

    if (exito) {
      appSnackbar(context, _modoEdicion ? 'Producto actualizado ✓' : 'Producto guardado exitosamente ✓');
      Navigator.pop(context);
    } else {
      final error = ref.read(productoControllerProvider).error;
      appSnackbar(context, error ?? 'No se pudo guardar el producto', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final jadeColor = isDark ? AppColors.darkJade : AppColors.brandJade;
    final jadeBg = isDark ? AppColors.darkJade50 : AppColors.lightJade50;

    return Scaffold(
      appBar: AppBar(
        title: Text(_modoEdicion ? 'Editar Producto' : 'Nuevo Producto'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkInk100 : AppColors.lightInk100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: cs.onSurface,
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            _SectionHeader(icon: Icons.barcode_reader, title: 'Identificación'),
            const SizedBox(height: 12),

            // ── Campo código de barras + botón escanear ──────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'CÓDIGO DE BARRAS',
                    hint: 'Ej: 7702001234567',
                    controller: _codigoCtrl,
                    prefixIcon: Icons.numbers_rounded,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    readOnly: _modoEdicion,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Tooltip(
                    message: 'Escanear código de barras',
                    child: InkWell(
                      onTap: _escanearCodigo,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: jadeBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: jadeColor.withAlpha(100),
                          ),
                        ),
                        child: Icon(
                          Icons.document_scanner_rounded,
                          color: jadeColor,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                'Escribe el código o toca el ícono para escanearlo con la cámara',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
              ),
            ),
            const SizedBox(height: 14),

            CustomTextField(
              label: 'NOMBRE DEL PRODUCTO',
              hint: 'Ej: Amoxicilina 500mg',
              controller: _nombreCtrl,
              prefixIcon: Icons.medication_rounded,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 14),

            CustomTextField(
              label: 'PRINCIPIO ACTIVO',
              hint: 'Ej: Amoxicilina trihidrato',
              controller: _principioCtrl,
              prefixIcon: Icons.science_rounded,
            ),
            const SizedBox(height: 14),

            CustomDropdownField<TipoProducto>(
              label: 'TIPO DE PRODUCTO',
              hint: 'Seleccionar tipo',
              value: _tipoSeleccionado,
              items: TipoProducto.values.map((tipo) {
                return DropdownMenuItem(
                  value: tipo,
                  child: Text(
                    tipo.name[0].toUpperCase() + tipo.name.substring(1),
                  ),
                );
              }).toList(),
              onChanged: (v) => setState(() => _tipoSeleccionado = v),
              validator: (v) => v == null ? 'Seleccione un tipo' : null,
            ),
            const SizedBox(height: 24),

            _SectionHeader(
              icon: Icons.attach_money_rounded,
              title: 'Precio y Stock',
            ),
            const SizedBox(height: 12),

            CustomTextField(
              label: 'PRECIO UNITARIO',
              hint: 'Ej: 25000',
              controller: _precioCtrl,
              keyboardType: TextInputType.number,
              prefixIcon: Icons.attach_money_rounded,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(8),
              ],
              validator: (v) {
                final n = int.tryParse(v?.trim() ?? '');
                if (n == null || n <= 0) return 'Ingresa un precio válido';
                return null;
              },
            ),
            const SizedBox(height: 14),

            CustomTextField(
              label: 'STOCK DISPONIBLE',
              hint: 'Ej: 100',
              controller: _stockCtrl,
              keyboardType: TextInputType.number,
              prefixIcon: Icons.inventory_2_rounded,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(5),
              ],
              validator: (v) {
                final n = int.tryParse(v?.trim() ?? '');
                if (n == null || n < 0) return 'Ingresa una cantidad válida';
                return null;
              },
            ),
            const SizedBox(height: 14),

            CustomTextField(
              label: 'STOCK MÍNIMO DE SEGURIDAD',
              hint: 'Ej: 10',
              controller: _stockMinCtrl,
              keyboardType: TextInputType.number,
              prefixIcon: Icons.warning_amber_rounded,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(5),
              ],
            ),
            const SizedBox(height: 24),

            _SectionHeader(
              icon: Icons.calendar_today_rounded,
              title: 'Vencimiento y Estado',
            ),
            const SizedBox(height: 12),

            _FechaVencimientoTile(
              fecha: _fechaVencimiento,
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _fechaVencimiento = picked);
              },
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.darkInk200 : AppColors.lightInk200,
                ),
              ),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Producto activo',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  _activo ? 'Visible en el catálogo' : 'Oculto del catálogo',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                value: _activo,
                onChanged: (v) => setState(() => _activo = v),
              ),
            ),
            const SizedBox(height: 32),

            _SubmitButton(guardando: _guardando, onTap: _guardar),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _nombreCtrl.dispose();
    _principioCtrl.dispose();
    _precioCtrl.dispose();
    _stockCtrl.dispose();
    _stockMinCtrl.dispose();
    super.dispose();
  }
}

// ── Widgets locales ───────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final jadeColor = isDark ? AppColors.darkJade : AppColors.brandJade;
    return Row(
      children: [
        Icon(icon, color: jadeColor, size: 16),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: jadeColor,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            color: isDark ? AppColors.darkInk200 : AppColors.lightInk200,
          ),
        ),
      ],
    );
  }
}

class _FechaVencimientoTile extends StatelessWidget {
  final DateTime? fecha;
  final VoidCallback onTap;
  const _FechaVencimientoTile({required this.fecha, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final jadeColor = isDark ? AppColors.darkJade : AppColors.brandJade;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: fecha == null
                ? (isDark ? AppColors.darkInk200 : AppColors.lightInk200)
                : jadeColor,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              color: fecha == null ? cs.onSurfaceVariant : jadeColor,
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                fecha == null
                    ? 'Seleccionar fecha de vencimiento *'
                    : 'Vence: ${fecha!.day.toString().padLeft(2, '0')}/'
                        '${fecha!.month.toString().padLeft(2, '0')}/'
                        '${fecha!.year}',
                style: TextStyle(
                  color: fecha == null ? cs.onSurfaceVariant : cs.onSurface,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: cs.onSurfaceVariant,
              size: 14,
            ),
          ],
        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final jadeColor = isDark ? AppColors.darkJade : AppColors.brandJade;

    return GestureDetector(
      onTap: guardando ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          gradient: guardando
              ? null
              : const LinearGradient(
                  colors: [AppColors.brandGradStart, AppColors.brandGradEnd],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          color: guardando
              ? (isDark ? AppColors.darkInk100 : AppColors.lightInk100)
              : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: guardando
              ? null
              : [
                  BoxShadow(
                    color: jadeColor.withAlpha(60),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Center(
          child: guardando
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: jadeColor,
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Guardar Producto',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
