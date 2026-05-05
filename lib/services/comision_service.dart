// lib/services/comision_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comision_model.dart';

class ComisionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _col = FirebaseFirestore.instance.collection('comisiones');

  static const double kPorcentajeComision = 0.20;

  // ─── Crear comisiones ─────────────────────────────────────────────────────

  Future<void> registrarComisionVenta({
    required String usuarioUid,
    required String nombreUsuario,
    required String tarjetaId,
    required String nombreCliente,
    required double totalVenta,
  }) async {
    final comision = totalVenta * kPorcentajeComision;
    await _col.doc().set({
      'usuario_uid': usuarioUid,
      'nombre_usuario': nombreUsuario,
      'tipo': TipoComision.venta.name,
      'tarjeta_id': tarjetaId,
      'nombre_cliente': nombreCliente,
      'monto_base': totalVenta,
      'porcentaje': kPorcentajeComision,
      'monto_comision': comision,
      'estado': EstadoComision.pendiente.name,
      'fecha': FieldValue.serverTimestamp(),
      'fecha_pago': null,
    });
  }

  Future<void> registrarComisionCobro({
    required String usuarioUid,
    required String nombreUsuario,
    required String tarjetaId,
    required String nombreCliente,
    required double montoCobrado,
  }) async {
    final comision = montoCobrado * kPorcentajeComision;
    await _col.doc().set({
      'usuario_uid': usuarioUid,
      'nombre_usuario': nombreUsuario,
      'tipo': TipoComision.cobro.name,
      'tarjeta_id': tarjetaId,
      'nombre_cliente': nombreCliente,
      'monto_base': montoCobrado,
      'porcentaje': kPorcentajeComision,
      'monto_comision': comision,
      'estado': EstadoComision.pendiente.name,
      'fecha': FieldValue.serverTimestamp(),
      'fecha_pago': null,
    });
  }

  // ─── Queries ──────────────────────────────────────────────────────────────

  Stream<List<ComisionModel>> streamComisionesUsuario(String usuarioUid) {
    return _col
        .where('usuario_uid', isEqualTo: usuarioUid)
        .snapshots()
        .map((snap) {
          final lista = snap.docs
              .map((d) => ComisionModel.fromMap(d.data(), d.id))
              .toList();
          lista.sort((a, b) => b.fecha.compareTo(a.fecha));
          return lista;
        });
  }

  Stream<List<ComisionModel>> streamTodasComisiones() {
    return _col.snapshots().map((snap) {
      final lista = snap.docs
          .map((d) => ComisionModel.fromMap(d.data(), d.id))
          .toList();
      lista.sort((a, b) => b.fecha.compareTo(a.fecha));
      return lista;
    });
  }

  // Comisiones pendientes de un usuario en el período quincenal actual
  Future<List<ComisionModel>> comisionesQuincenaActual(String usuarioUid) async {
    final ahora = DateTime.now();
    final DateTime inicio;
    final DateTime fin;

    if (ahora.day <= 15) {
      inicio = DateTime(ahora.year, ahora.month, 1);
      fin = DateTime(ahora.year, ahora.month, 16);
    } else {
      inicio = DateTime(ahora.year, ahora.month, 16);
      fin = DateTime(ahora.year, ahora.month + 1, 1);
    }

    final snap = await _col
        .where('usuario_uid', isEqualTo: usuarioUid)
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
        .where('fecha', isLessThan: Timestamp.fromDate(fin))
        .get();

    return snap.docs.map((d) => ComisionModel.fromMap(d.data(), d.id)).toList();
  }

  // Comisiones pendientes de todos en el período quincenal actual (para admin)
  Future<List<ComisionModel>> comisionesQuincenaTodos() async {
    final ahora = DateTime.now();
    final DateTime inicio;
    final DateTime fin;

    if (ahora.day <= 15) {
      inicio = DateTime(ahora.year, ahora.month, 1);
      fin = DateTime(ahora.year, ahora.month, 16);
    } else {
      inicio = DateTime(ahora.year, ahora.month, 16);
      fin = DateTime(ahora.year, ahora.month + 1, 1);
    }

    final snap = await _col
        .where('estado', isEqualTo: EstadoComision.pendiente.name)
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
        .where('fecha', isLessThan: Timestamp.fromDate(fin))
        .get();

    return snap.docs.map((d) => ComisionModel.fromMap(d.data(), d.id)).toList();
  }

  // Marcar comisiones como pagadas (admin paga quincena)
  Future<void> marcarPagadas(List<String> comisionIds) async {
    if (comisionIds.isEmpty) return;
    final batch = _db.batch();
    for (final id in comisionIds) {
      batch.update(_col.doc(id), {
        'estado': EstadoComision.pagada.name,
        'fecha_pago': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}
