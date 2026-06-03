import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/asignacion_producto_model.dart';

class AsignacionProductoService {
  final _col = FirebaseFirestore.instance.collection('asignaciones_productos');

  // Stream de productos asignados a una asesora
  Stream<List<AsignacionProductoModel>> streamAsignacionesAsesora(
    String asesoraUid,
  ) {
    return _col
        .where('asesora_uid', isEqualTo: asesoraUid)
        .where('activa', isEqualTo: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => AsignacionProductoModel.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  // Asignar producto a asesora (admin)
  Future<void> asignarProducto(AsignacionProductoModel asignacion) async {
    // Si ya existe una asignación activa para ese producto y asesora, actualiza
    final existing = await _col
        .where('asesora_uid', isEqualTo: asignacion.asesoraUid)
        .where('codigo_barras', isEqualTo: asignacion.codigoBarras)
        .where('activa', isEqualTo: true)
        .get();

    if (existing.docs.isNotEmpty) {
      await _col.doc(existing.docs.first.id).update({
        'cantidad_asignada': FieldValue.increment(asignacion.cantidadAsignada),
      }).timeout(const Duration(seconds: 5), onTimeout: () {});
    } else {
      await _col
          .doc()
          .set(asignacion.toMap())
          .timeout(const Duration(seconds: 5), onTimeout: () {});
    }
  }

  // Descontar vendidos al crear una venta (llamado desde TarjetaService)
  Future<void> registrarVenta(
    String asesoraUid,
    String codigoBarras,
    int cantidadVendida,
  ) async {
    try {
      final snap = await _col
          .where('asesora_uid', isEqualTo: asesoraUid)
          .where('codigo_barras', isEqualTo: codigoBarras)
          .where('activa', isEqualTo: true)
          .get()
          .timeout(const Duration(seconds: 8));

      if (snap.docs.isNotEmpty) {
        await _col.doc(snap.docs.first.id).update({
          'cantidad_vendida': FieldValue.increment(cantidadVendida),
        }).timeout(const Duration(seconds: 5), onTimeout: () {});
      }
    } catch (_) {
      // Sin conexión: Firestore sincronizará cuando haya red.
    }
  }

  // Eliminar asignación individual
  Future<void> desactivarAsignacion(String asignacionId) async {
    await _col
        .doc(asignacionId)
        .update({'activa': false})
        .timeout(const Duration(seconds: 5), onTimeout: () {});
  }

  // Desactivar todas las asignaciones activas de un producto eliminado
  Future<void> desactivarAsignacionesPorProducto(String codigoBarras) async {
    final snap = await _col
        .where('codigo_barras', isEqualTo: codigoBarras)
        .where('activa', isEqualTo: true)
        .get();
    if (snap.docs.isEmpty) return;
    final db = FirebaseFirestore.instance;
    final batch = db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'activa': false});
    }
    await batch.commit().timeout(const Duration(seconds: 10), onTimeout: () {});
  }
}
