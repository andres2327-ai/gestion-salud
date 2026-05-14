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
    }).timeout(const Duration(seconds: 5), onTimeout: () {});
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

  Stream<List<ComisionModel>> streamComisionesPendientes() {
    return _col
        .where('estado', isEqualTo: EstadoComision.pendiente.name)
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
        .where('estado', isEqualTo: EstadoComision.pendiente.name)
        .get(const GetOptions(source: Source.server));
    final lista = snap.docs
        .map((d) => ComisionModel.fromMap(d.data(), d.id))
        .toList();
    lista.sort((a, b) => b.fecha.compareTo(a.fecha));
    return lista;
  }

  // Todas las comisiones pendientes de pago (para admin — pantalla de quincena).
  // Fuerza lectura desde el servidor para evitar caché vacía en el primer arranque.
  Future<List<ComisionModel>> comisionesQuincenaTodos() async {
    final snap = await _col
        .where('estado', isEqualTo: EstadoComision.pendiente.name)
        .get(const GetOptions(source: Source.server));
    final lista = snap.docs
        .map((d) => ComisionModel.fromMap(d.data(), d.id))
        .toList();
    lista.sort((a, b) => b.fecha.compareTo(a.fecha));
    return lista;
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
    await batch.commit().timeout(const Duration(seconds: 10), onTimeout: () {});
  }
}
