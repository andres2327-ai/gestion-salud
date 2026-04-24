// lib/services/producto_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/producto_model.dart';

class ProductoService {
  final _col = FirebaseFirestore.instance.collection('productos');

  // Stream de todos los productos activos
  Stream<List<ProductoModel>> streamProductos() {
    // NOTA: orderBy('nombre') junto a where() requiere índice compuesto en
    // Firestore. Al no existir el índice el stream falla silenciosamente.
    // Ordenamos en memoria para evitar esa dependencia.
    return _col
        .where('activo', isEqualTo: true)
        .snapshots()
        .map(
          (snap) {
            final lista = snap.docs
                .map((d) => ProductoModel.fromMap(d.data(), d.id))
                .toList();
            lista.sort((a, b) => a.nombre.compareTo(b.nombre)); // orden en memoria
            return lista;
          },
        );
  }

  // Obtener producto por código de barras
  Future<ProductoModel?> obtenerProducto(String codigoBarras) async {
    final doc = await _col.doc(codigoBarras).get();
    if (!doc.exists) return null;
    return ProductoModel.fromMap(doc.data()!, doc.id);
  }

  // Agregar nuevo producto
  Future<void> agregarProducto(ProductoModel producto) async {
    await _col.doc(producto.codigoBarras).set(producto.toMap());
  }

  // Actualizar producto
  Future<void> actualizarProducto(
    String codigoBarras,
    Map<String, dynamic> datos,
  ) async {
    await _col.doc(codigoBarras).update(datos);
  }

  // Ajustar stock (positivo = entrada, negativo = salida)
  Future<void> ajustarStock(String codigoBarras, int cantidad) async {
    await _col.doc(codigoBarras).update({
      'cantidad_stock': FieldValue.increment(cantidad),
    });
  }

  // Desactivar producto
  Future<void> desactivarProducto(String codigoBarras) async {
    await _col.doc(codigoBarras).update({'activo': false});
  }

  // Obtener productos con stock bajo (menos de N unidades)
  Future<List<ProductoModel>> productosStockBajo({int limite = 10}) async {
    final snap = await _col
        .where('activo', isEqualTo: true)
        .where('cantidad_stock', isLessThan: limite)
        .get();
    return snap.docs.map((d) => ProductoModel.fromMap(d.data(), d.id)).toList();
  }

  // Obtener productos próximos a vencer (30 días)
  Future<List<ProductoModel>> productosProximosVencer() async {
    final limite = Timestamp.fromDate(
      DateTime.now().add(const Duration(days: 30)),
    );
    final snap = await _col
        .where('activo', isEqualTo: true)
        .where('fecha_vencimiento', isLessThanOrEqualTo: limite)
        .get();
    return snap.docs.map((d) => ProductoModel.fromMap(d.data(), d.id)).toList();
  }
}
