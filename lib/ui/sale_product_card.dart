import 'package:flutter/material.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final cardColor =
        Theme.of(context).cardTheme.color ?? colorScheme.surface;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
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
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.medication_rounded,
                color: colorScheme.onPrimaryContainer,
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
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\$${producto.precioVenta.toStringAsFixed(0)}  ×  ${producto.cantidad}',
                    style: textTheme.bodySmall,
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
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _QtyButton(
                      icon: Icons.remove,
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
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _QtyButton(
                      icon: Icons.add,
                      onTap: () => onCantidadChanged(producto.cantidad + 1),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onRemove,
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: colorScheme.error,
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

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: colorScheme.outline),
        ),
        child: Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}
