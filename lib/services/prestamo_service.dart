// lib/services/prestamo_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/prestamo_model.dart';

class PrestamoService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('prestamos');

  Future<void> solicitar(PrestamoModel p) async {
    await _col.doc().set(p.toMap()).timeout(const Duration(seconds: 5));
  }

  Stream<List<PrestamoModel>> streamPendientes() {
    return _col
        .where('estado', isEqualTo: EstadoPrestamo.pendiente.name)
        .snapshots()
        .map((s) {
      final lista =
          s.docs.map((d) => PrestamoModel.fromMap(d.data(), d.id)).toList();
      lista.sort((a, b) => b.fechaSolicitud.compareTo(a.fechaSolicitud));
      return lista;
    });
  }

  Stream<List<PrestamoModel>> streamUsuario(String uid) {
    return _col
        .where('usuario_uid', isEqualTo: uid)
        .snapshots()
        .map((s) {
      final lista =
          s.docs.map((d) => PrestamoModel.fromMap(d.data(), d.id)).toList();
      lista.sort((a, b) => b.fechaSolicitud.compareTo(a.fechaSolicitud));
      return lista;
    });
  }

  Future<void> resolver({
    required String prestamoId,
    required bool aprobado,
    required String adminUid,
  }) async {
    await _col.doc(prestamoId).update({
      'estado': aprobado
          ? EstadoPrestamo.aprobado.name
          : EstadoPrestamo.rechazado.name,
      'fecha_resolucion': FieldValue.serverTimestamp(),
      'admin_uid': adminUid,
    }).timeout(const Duration(seconds: 5));
  }

  Future<List<PrestamoModel>> prestamosAprobadosConSaldo(String uid) async {
    final snap = await _col
        .where('usuario_uid', isEqualTo: uid)
        .where('estado', isEqualTo: EstadoPrestamo.aprobado.name)
        .get(const GetOptions(source: Source.server));
    return snap.docs
        .map((d) => PrestamoModel.fromMap(d.data(), d.id))
        .where((p) => p.saldoPendiente > 0)
        .toList();
  }

  Future<void> descontarDeuda({
    required String usuarioUid,
    required double montoADescontar,
  }) async {
    if (montoADescontar <= 0) return;

    final snap = await _col
        .where('usuario_uid', isEqualTo: usuarioUid)
        .where('estado', isEqualTo: EstadoPrestamo.aprobado.name)
        .get(const GetOptions(source: Source.server));

    final prestamos = snap.docs
        .map((d) => PrestamoModel.fromMap(d.data(), d.id))
        .where((p) => p.saldoPendiente > 0)
        .toList();

    if (prestamos.isEmpty) return;

    var restante = montoADescontar;
    final batch = _db.batch();
    bool hayActualizaciones = false;

    for (final p in prestamos) {
      if (restante <= 0) break;
      final descuento =
          restante < p.saldoPendiente ? restante : p.saldoPendiente;
      batch.update(_col.doc(p.prestamoId), {
        'saldo_pendiente': p.saldoPendiente - descuento,
      });
      restante -= descuento;
      hayActualizaciones = true;
    }

    if (hayActualizaciones) {
      await batch.commit().timeout(const Duration(seconds: 10));
    }
  }
}
