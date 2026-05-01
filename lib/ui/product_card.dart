import 'package:flutter/material.dart';
import '../models/producto_model.dart';

// ── Card para la pantalla de Inventario ───────────────────────────────────────
class ProductoCard extends StatelessWidget {
  final String nombre;
  final String tipo;
  final int cantidad;
  final VoidCallback? onTap;

  const ProductoCard({
    super.key,
    required this.nombre,
    required this.tipo,
    required this.cantidad,
    this.onTap,
  });

  Color _stockColor(ColorScheme cs) {
    if (cantidad <= 0) return cs.error;
    if (cantidad < 10) return Colors.orange;
    return cs.primary;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final cardColor =
        Theme.of(context).cardTheme.color ?? colorScheme.surface;
    final stockColor = _stockColor(colorScheme);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.medication_rounded,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombre,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(tipo, style: textTheme.bodySmall),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$cantidad',
                  style: TextStyle(
                    color: stockColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                Text('uds', style: textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Card para la pantalla de Catálogo/Productos (grid) ────────────────────────
class ProductCard extends StatelessWidget {
  final ProductoModel producto;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;

  const ProductCard({
    super.key,
    required this.producto,
    this.onTap,
    this.onAddToCart,
  });

  bool get _disponible => producto.cantidadStock > 0 && producto.activo;
  bool get _stockBajo => producto.cantidadStock < 10;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final cardColor =
        Theme.of(context).cardTheme.color ?? colorScheme.surface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.medication_rounded,
                    color: colorScheme.onPrimaryContainer,
                    size: 36,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto.nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(producto.tipo.name, style: textTheme.bodySmall),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${producto.precioUnitario.toStringAsFixed(0)}',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (_stockBajo && _disponible)
                        _StockBadge(label: 'Stock bajo', color: Colors.orange),
                      if (!_disponible)
                        _StockBadge(
                          label: 'Sin stock',
                          color: colorScheme.error,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: ElevatedButton.icon(
                      onPressed: _disponible ? onAddToCart : null,
                      icon: const Icon(
                        Icons.add_shopping_cart_rounded,
                        size: 14,
                      ),
                      label: const Text(
                        'Agregar',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StockBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
