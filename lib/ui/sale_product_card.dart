import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class ProductoVentaItem {
  final String codigoBarras;
  final String nombre;
  final double precioVenta;
  final int cantidad;

  ProductoVentaItem({
    required this.codigoBarras,
    required this.nombre,
    required this.precioVenta,
    required this.cantidad,
  });

  double get subtotal => precioVenta * cantidad;

  ProductoVentaItem copyWith({
    String? codigoBarras,
    String? nombre,
    double? precioVenta,
    int? cantidad,
  }) {
    return ProductoVentaItem(
      codigoBarras: codigoBarras ?? this.codigoBarras,
      nombre: nombre ?? this.nombre,
      precioVenta: precioVenta ?? this.precioVenta,
      cantidad: cantidad ?? this.cantidad,
    );
  }
}

class SaleProductCard extends StatelessWidget {
  final ProductoVentaItem producto;
  final VoidCallback onRemove;
  final void Function(int nuevaCantidad) onCantidadChanged;

  const SaleProductCard({
    super.key,
    required this.producto,
    required this.onRemove,
    required this.onCantidadChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final jadeColor = isDark ? AppColors.darkJade : AppColors.brandJade;
    final jadeBg = isDark ? AppColors.darkJade50 : AppColors.lightJade50;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkInk200 : AppColors.lightInk200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Ícono producto
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: jadeBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.medication_rounded,
                color: jadeColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Nombre y precio
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\$${producto.precioVenta.toStringAsFixed(0)}  ×  ${producto.cantidad}',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Subtotal y controles
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${producto.subtotal.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: jadeColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _QtyButton(
                      icon: Icons.remove,
                      isDark: isDark,
                      cs: cs,
                      onTap: () {
                        if (producto.cantidad > 1) {
                          onCantidadChanged(producto.cantidad - 1);
                        }
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        '${producto.cantidad}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    _QtyButton(
                      icon: Icons.add,
                      isDark: isDark,
                      cs: cs,
                      onTap: () => onCantidadChanged(producto.cantidad + 1),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onRemove,
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: isDark ? AppColors.darkCoral : AppColors.coral,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  final ColorScheme cs;

  const _QtyButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkInk100 : AppColors.lightInk100,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: isDark ? AppColors.darkInk200 : AppColors.lightInk200,
          ),
        ),
        child: Icon(icon, size: 14, color: cs.onSurfaceVariant),
      ),
    );
  }
}
