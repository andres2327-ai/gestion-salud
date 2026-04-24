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
      });
    } else {
      await _col.doc().set(asignacion.toMap());
    }
  }

  // Descontar vendidos al crear una venta (llamado desde TarjetaService)
  Future<void> registrarVenta(
    String asesoraUid,
    String codigoBarras,
    int cantidadVendida,
  ) async {
    final snap = await _col
        .where('asesora_uid', isEqualTo: asesoraUid)
        .where('codigo_barras', isEqualTo: codigoBarras)
        .where('activa', isEqualTo: true)
        .get();

    if (snap.docs.isNotEmpty) {
      await _col.doc(snap.docs.first.id).update({
        'cantidad_vendida': FieldValue.increment(cantidadVendida),
      });
    }
  }

  // Revertir vendidos al aprobar devolución
  Future<void> revertirVenta(
    String asesoraUid,
    String codigoBarras,
    int cantidad,
  ) async {
    final snap = await _col
        .where('asesora_uid', isEqualTo: asesoraUid)
        .where('codigo_barras', isEqualTo: codigoBarras)
        .where('activa', isEqualTo: true)
        .get();

    if (snap.docs.isNotEmpty) {
      await _col.doc(snap.docs.first.id).update({
        'cantidad_vendida': FieldValue.increment(-cantidad),
      });
    }
  }

  // Eliminar asignación
  Future<void> desactivarAsignacion(String asignacionId) async {
    await _col.doc(asignacionId).update({'activa': false});
  }
}
