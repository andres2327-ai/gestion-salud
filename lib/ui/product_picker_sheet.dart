// widgets/product_picker_sheet.dart
// BottomSheet para buscar y seleccionar un producto del inventario
// En producción recibirá la lista real desde Firestore

import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
//import '../models/sale_model.dart';

// ── Producto simulado del inventario ────────────────────────────────────────
class ProductoInventario {
  final String codigoBarras;
  final String nombre;
  final String tipo;
  final double precioUnitario;
  final int cantidadStock;

  const ProductoInventario({
    required this.codigoBarras,
    required this.nombre,
    required this.tipo,
    required this.precioUnitario,
    required this.cantidadStock,
  });
}

// ── Mock data (reemplazar con llamada a Firestore) ───────────────────────────
final List<ProductoInventario> mockProductos = [
  ProductoInventario(codigoBarras: '7001', nombre: 'Amoxicilina 500mg x 10', tipo: 'pastillas', precioUnitario: 18500, cantidadStock: 80),
  ProductoInventario(codigoBarras: '7002', nombre: 'Ibuprofeno 400mg x 20', tipo: 'pastillas', precioUnitario: 12000, cantidadStock: 120),
  ProductoInventario(codigoBarras: '7003', nombre: 'Loratadina 10mg x 10', tipo: 'pastillas', precioUnitario: 9800, cantidadStock: 60),
  ProductoInventario(codigoBarras: '7004', nombre: 'Omeprazol 20mg x 14', tipo: 'pastillas', precioUnitario: 15200, cantidadStock: 45),
  ProductoInventario(codigoBarras: '7005', nombre: 'Vitamina C 1g x 10', tipo: 'pastillas', precioUnitario: 8500, cantidadStock: 200),
  ProductoInventario(codigoBarras: '7006', nombre: 'Jarabe Ambroxol 120ml', tipo: 'liquido', precioUnitario: 22000, cantidadStock: 30),
  ProductoInventario(codigoBarras: '7007', nombre: 'Gel Diclofenaco 50g', tipo: 'polvo', precioUnitario: 28000, cantidadStock: 25),
];

class ProductPickerSheet extends StatefulWidget {
  final void Function(ProductoInventario producto) onProductoSeleccionado;
  final List<String> codigosYaAgregados; // evita duplicados

  const ProductPickerSheet({
    super.key,
    required this.onProductoSeleccionado,
    this.codigosYaAgregados = const [],
  });

  @override
  State<ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<ProductPickerSheet> {
  final _searchCtrl = TextEditingController();
  List<ProductoInventario> _filtered = mockProductos;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_filter);
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = mockProductos
          .where((p) =>
              p.nombre.toLowerCase().contains(q) ||
              p.codigoBarras.contains(q))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ── Handle ───────────────────────────────────────────────────
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.inputBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // ── Título ───────────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Agregar Producto',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Buscador ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o código...',
                hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.textHint, size: 18),
                filled: true,
                fillColor: AppColors.inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.inputBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.inputBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Lista ─────────────────────────────────────────────────────
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              itemCount: _filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final p = _filtered[i];
                final yaAgregado =
                    widget.codigosYaAgregados.contains(p.codigoBarras);

                return _ProductTile(
                  producto: p,
                  yaAgregado: yaAgregado,
                  onTap: yaAgregado
                      ? null
                      : () {
                          widget.onProductoSeleccionado(p);
                          Navigator.pop(context);
                        },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final ProductoInventario producto;
  final bool yaAgregado;
  final VoidCallback? onTap;

  const _ProductTile({
    required this.producto,
    required this.yaAgregado,
    this.onTap,
  });

  IconData get _tipoIcon {
    switch (producto.tipo) {
      case 'liquido':
        return Icons.water_drop_rounded;
      case 'polvo':
        return Icons.science_rounded;
      default:
        return Icons.medication_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: yaAgregado ? 0.45 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.cardElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: yaAgregado
                  ? AppColors.divider
                  : AppColors.inputBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.accentGlow,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(_tipoIcon,
                    color: AppColors.accent, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.nombre,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Stock: ${producto.cantidadStock}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${producto.precioUnitario.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (yaAgregado)
                    const Text(
                      'Agregado',
                      style: TextStyle(
                        color: AppColors.textHint,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
