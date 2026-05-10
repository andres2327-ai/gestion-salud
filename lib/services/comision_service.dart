// lib/services/comision_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comision_model.dart';

class ComisionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _col = FirebaseFirestore.instance.collection('comisiones');

  static const double kPorcentajeComision = 0.20;

  // ─── Crear comisión ───────────────────────────────────────────────────────

  Future<void> registrarComision({
    required TipoComision tipo,
    required String usuarioUid,
    required String nombreUsuario,
    required String tarjetaId,
    required String nombreCliente,
    required double montoBase,
  }) async {
    final comision = montoBase * kPorcentajeComision;
    await _col.doc().set({
      'usuario_uid': usuarioUid,
      'nombre_usuario': nombreUsuario,
      'tipo': tipo.name,
      'tarjeta_id': tarjetaId,
      'nombre_cliente': nombreCliente,
      'monto_base': montoBase,
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

  // Comisiones de un usuario en el período quincenal actual.
  // Only uses equality filters (no range query) — avoids composite index issues.
  // Date filtering is done in Dart.
  Future<List<ComisionModel>> comisionesQuincenaActual(String usuarioUid) async {
    final snap = await _col
        .where('usuario_uid', isEqualTo: usuarioUid)
        .get();

    final rango = _rangoQuincenaActual();
    return snap.docs
        .map((d) => ComisionModel.fromMap(d.data(), d.id))
        .where((c) => c.fecha.isAfter(rango.$1) && c.fecha.isBefore(rango.$2))
        .toList();
  }

  // Comisiones pendientes de todos en el período quincenal actual (para admin).
  // Fetches only pending commissions with a single equality filter,
  // then filters by quincena dates in Dart — no range query, no composite index.
  Future<List<ComisionModel>> comisionesQuincenaTodos() async {
    final snap = await _col
        .where('estado', isEqualTo: EstadoComision.pendiente.name)
        .get();

    final rango = _rangoQuincenaActual();
    return snap.docs
        .map((d) => ComisionModel.fromMap(d.data(), d.id))
        .where((c) => c.fecha.isAfter(rango.$1) && c.fecha.isBefore(rango.$2))
        .toList();
  }

  // Returns (inicio, fin) of the current bi-weekly period.
  (DateTime, DateTime) _rangoQuincenaActual() {
    final ahora = DateTime.now();
    if (ahora.day <= 15) {
      return (
        DateTime(ahora.year, ahora.month, 1),
        DateTime(ahora.year, ahora.month, 16),
      );
    } else {
      return (
        DateTime(ahora.year, ahora.month, 16),
        DateTime(ahora.year, ahora.month + 1, 1),
      );
    }
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
