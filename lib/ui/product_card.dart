// widgets/product_card.dart
// ProductoCard (inventario) con el diseño dark del original
// + ProductCard (catálogo) del forms — en un solo archivo

import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/producto_model.dart';

// ── Card para la pantalla de Inventario (estilo mockup dark) ─────────────────
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

  Color get _stockColor {
    if (cantidad <= 0) return AppColors.error;
    if (cantidad < 10) return AppColors.warning;
    return AppColors.accent;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accentGlow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.medication_rounded,
                color: AppColors.accent,
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
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tipo,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$cantidad',
                  style: TextStyle(
                    color: _stockColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'uds',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Card para la pantalla de Catálogo/Productos (grid, del forms) ────────────
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen / ícono
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.accentGlow,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.medication_rounded,
                    color: AppColors.accent,
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
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    producto.tipo.name,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${producto.precioUnitario.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      if (_stockBajo && _disponible)
                        _StockBadge(
                          label: 'Stock bajo',
                          color: AppColors.warning,
                        ),
                      if (!_disponible)
                        _StockBadge(label: 'Sin stock', color: AppColors.error),
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
        color: color.withOpacity(0.15),
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
