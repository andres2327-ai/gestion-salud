import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

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
  final List<String> codigosYaAgregados;

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
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkInk200 : AppColors.lightInk200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Agregar Producto',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Buscar por nombre o código...',
                prefixIcon: Icon(Icons.search_rounded, size: 18),
              ),
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              itemCount: _filtered.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final p = _filtered[i];
                final yaAgregado =
                    widget.codigosYaAgregados.contains(p.codigoBarras);

                return _ProductTile(
                  producto: p,
                  yaAgregado: yaAgregado,
                  isDark: isDark,
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
  final bool isDark;
  final VoidCallback? onTap;

  const _ProductTile({
    required this.producto,
    required this.yaAgregado,
    required this.isDark,
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
    final cs = Theme.of(context).colorScheme;
    final jadeColor = isDark ? AppColors.darkJade : AppColors.brandJade;
    final jadeBg = isDark ? AppColors.darkJade50 : AppColors.lightJade50;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: yaAgregado ? 0.45 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.darkInk200 : AppColors.lightInk200,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: jadeBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _tipoIcon,
                  color: jadeColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Stock: ${producto.cantidadStock}',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
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
                    style: TextStyle(
                      color: jadeColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  if (yaAgregado)
                    Text(
                      'Agregado',
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
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
