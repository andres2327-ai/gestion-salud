// ui/view_producto.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../models/producto_model.dart';
import '../providers.dart';
import './custom_text_field.dart';
import './barcode_scanner_screen.dart';

class ProductoFormPage extends ConsumerStatefulWidget {
  const ProductoFormPage({super.key});

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
      ScaffoldMessenger.of(context).showSnackBar(
        _snack('Selecciona la fecha de vencimiento', error: true),
      );
      return;
    }

    setState(() => _guardando = true);

    final producto = ProductoModel(
      codigoBarras:     _codigoCtrl.text.trim(),
      nombre:           _nombreCtrl.text.trim(),
      tipo:             _tipoSeleccionado!,
      precioUnitario:   double.tryParse(_precioCtrl.text.trim()) ?? 0,
      cantidadStock:    int.tryParse(_stockCtrl.text.trim()) ?? 0,
      fechaVencimiento: _fechaVencimiento!,
      activo:           _activo,
    );

    final exito = await ref
        .read(productoControllerProvider.notifier)
        .agregarProducto(producto);

    if (!mounted) return;
    setState(() => _guardando = false);

    if (exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        _snack('Producto guardado exitosamente ✓'),
      );
      Navigator.pop(context);
    } else {
      final error = ref.read(productoControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        _snack(error ?? 'No se pudo guardar el producto', error: true),
      );
    }
  }

  SnackBar _snack(String msg, {bool error = false}) => SnackBar(
        content: Text(
          msg,
          style: const TextStyle(color: AppColors.background),
        ),
        backgroundColor: error ? AppColors.error : AppColors.accentDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Gestión de Producto'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 16, color: AppColors.textPrimary),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            _SectionHeader(
              icon: Icons.barcode_reader,
              title: 'Identificación',
            ),
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
                          color: AppColors.accentGlow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
                        ),
                        child: const Icon(
                          Icons.document_scanner_rounded,
                          color: AppColors.accent,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text(
                'Escribe el código o toca el ícono para escanearlo con la cámara',
                style: TextStyle(color: AppColors.textHint, fontSize: 11),
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
                    style: const TextStyle(color: AppColors.textPrimary),
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
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 14),

            CustomTextField(
              label: 'STOCK DISPONIBLE',
              hint: 'Ej: 100',
              controller: _stockCtrl,
              keyboardType: TextInputType.number,
              prefixIcon: Icons.inventory_2_rounded,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 14),

            CustomTextField(
              label: 'STOCK MÍNIMO DE SEGURIDAD',
              hint: 'Ej: 10',
              controller: _stockMinCtrl,
              keyboardType: TextInputType.number,
              prefixIcon: Icons.warning_amber_rounded,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                  builder: (context, child) => Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: AppColors.accent,
                        onPrimary: AppColors.background,
                        surface: AppColors.card,
                        onSurface: AppColors.textPrimary,
                      ),
                    ),
                    child: child!,
                  ),
                );
                if (picked != null) setState(() => _fechaVencimiento = picked);
              },
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Producto activo',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  _activo ? 'Visible en el catálogo' : 'Oculto del catálogo',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
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

class _FechaVencimientoTile extends StatelessWidget {
  final DateTime? fecha;
  final VoidCallback onTap;
  const _FechaVencimientoTile({required this.fecha, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: fecha == null ? AppColors.inputBorder : AppColors.accent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              color: fecha == null ? AppColors.textHint : AppColors.accent,
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
                  color:
                      fecha == null ? AppColors.textHint : AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: AppColors.textHint, size: 14),
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
              : const [
                  BoxShadow(
                    color: AppColors.accentGlow,
                    blurRadius: 20,
                    offset: Offset(0, 6),
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
                    Icon(Icons.save_rounded,
                        color: AppColors.background, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Guardar Producto',
                      style: TextStyle(
                        color: AppColors.background,
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
