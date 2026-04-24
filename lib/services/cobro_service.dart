// lib/services/cobro_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tarjeta_model.dart';

class CobroService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _cuotasCol = FirebaseFirestore.instance.collection('cuotas');
  final _devCol = FirebaseFirestore.instance.collection('devoluciones');
  final _asigCol = FirebaseFirestore.instance.collection('asignaciones');

  // ─── CUOTAS ───────────────────────────────────────────────────────────────

  // Stream de cuotas de una tarjeta
  Stream<List<CuotaModel>> streamCuotasDeTarjeta(String tarjetaId) {
    return _cuotasCol
        .where('tarjeta_id', isEqualTo: tarjetaId)
        .orderBy('numero_cuota')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => CuotaModel.fromMap(d.data(), d.id)).toList(),
        );
  }

  // Registrar cobro de una cuota
  Future<void> cobrarCuota({
    required String cuotaId,
    required String tarjetaId,
    required String cobradorUid,
    required double monto,
    String? observacion,
  }) async {
    final batch = _db.batch();

    // Marcar cuota como cobrada
    batch.update(_cuotasCol.doc(cuotaId), {
      'estado': EstadoCuota.cobrada.name,
      'cobrador_uid': cobradorUid,
      'fecha_cobro': FieldValue.serverTimestamp(),
      'observacion': observacion,
    });

    // Descontar del saldo pendiente de la tarjeta
    batch.update(_db.collection('tarjetas').doc(tarjetaId), {
      'saldo_pendiente': FieldValue.increment(-monto),
    });

    await batch.commit();

    // Verificar si la tarjeta quedó totalmente pagada
    await _verificarTarjetaPagada(tarjetaId);
  }

  Future<void> _verificarTarjetaPagada(String tarjetaId) async {
    final cuotas = await _cuotasCol
        .where('tarjeta_id', isEqualTo: tarjetaId)
        .where('estado', isEqualTo: EstadoCuota.pendiente.name)
        .get();

    if (cuotas.docs.isEmpty) {
      await _db.collection('tarjetas').doc(tarjetaId).update({
        'estado': EstadoTarjeta.pagada.name,
        'saldo_pendiente': 0,
      });
    }
  }

  // Cuotas pendientes de un cobrador (según sus asignaciones)
  Future<List<CuotaModel>> cuotasPendientesCobrador(String cobradorUid) async {
    // Obtener tarjetas asignadas al cobrador
    final asigs = await _asigCol
        .where('cobrador_uid', isEqualTo: cobradorUid)
        .where('activa', isEqualTo: true)
        .get();

    final tarjetaIds = asigs.docs
        .map((d) => d['tarjeta_id'] as String)
        .toList();
    if (tarjetaIds.isEmpty) return [];

    // Firestore limita whereIn a 10 elementos
    final cuotas = <CuotaModel>[];
    for (int i = 0; i < tarjetaIds.length; i += 10) {
      final chunk = tarjetaIds.sublist(
        i,
        i + 10 > tarjetaIds.length ? tarjetaIds.length : i + 10,
      );
      final snap = await _cuotasCol
          .where('tarjeta_id', whereIn: chunk)
          .where('estado', isEqualTo: EstadoCuota.pendiente.name)
          .get();
      cuotas.addAll(snap.docs.map((d) => CuotaModel.fromMap(d.data(), d.id)));
    }
    return cuotas;
  }

  // Registrar pago libre (cobrador agrega monto sin cuota específica)
  Future<void> registrarPago({
    required String tarjetaId,
    required String cobradorUid,
    required double monto,
    String? observacion,
  }) async {
    final batch = _db.batch();

    // Log del pago
    final pagoRef = _db.collection('pagos_registrados').doc();
    batch.set(pagoRef, {
      'tarjeta_id': tarjetaId,
      'cobrador_uid': cobradorUid,
      'monto': monto,
      'observacion': observacion,
      'fecha': FieldValue.serverTimestamp(),
    });

    // Descontar del saldo pendiente
    batch.update(_db.collection('tarjetas').doc(tarjetaId), {
      'saldo_pendiente': FieldValue.increment(-monto),
    });

    await batch.commit();
    await _verificarTarjetaPagada(tarjetaId);
  }

  // Stream de pagos de una tarjeta (sin orderBy para evitar índice compuesto)
  Stream<List<Map<String, dynamic>>> streamPagosDeTarjeta(String tarjetaId) {
    return _db
        .collection('pagos_registrados')
        .where('tarjeta_id', isEqualTo: tarjetaId)
        .snapshots()
        .map((snap) {
          final lista = snap.docs
              .map((d) => {'id': d.id, ...d.data()})
              .toList();
          lista.sort((a, b) {
            final aDate =
                (a['fecha'] as Timestamp?)?.toDate() ?? DateTime(0);
            final bDate =
                (b['fecha'] as Timestamp?)?.toDate() ?? DateTime(0);
            return bDate.compareTo(aDate);
          });
          return lista;
        });
  }

  // ─── DEVOLUCIONES ─────────────────────────────────────────────────────────

  // Solicitar devolución (asesora)
  Future<String> solicitarDevolucion(DevolucionModel devolucion) async {
    final ref = _devCol.doc();
    await ref.set({
      ...devolucion.toMap(),
      'estado': EstadoDevolucion.pendiente.name,
    });
    return ref.id;
  }

  // Stream de devoluciones (admin ve todas)
  Stream<List<DevolucionModel>> streamDevoluciones({EstadoDevolucion? estado}) {
    Query query = _devCol.orderBy('fecha_devolucion', descending: true);
    if (estado != null) {
      query = query.where('estado', isEqualTo: estado.name);
    }
    return query.snapshots().map(
      (snap) => snap.docs
          .map(
            (d) =>
                DevolucionModel.fromMap(d.data() as Map<String, dynamic>, d.id),
          )
          .toList(),
    );
  }

  // Stream devoluciones de una asesora
  Stream<List<DevolucionModel>> streamDevolucionesAsesora(String asesoraUid) {
    return _devCol
        .where('asesora_uid', isEqualTo: asesoraUid)
        .orderBy('fecha_devolucion', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => DevolucionModel.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  // Resolver devolución (admin acepta o rechaza)
  Future<void> resolverDevolucion({
    required String devolucionId,
    required String tarjetaId,
    required String asesoraUid,
    required String adminUid,
    required EstadoDevolucion nuevoEstado,
    required double montoReembolso,
    required int cantidadDevuelta,
    required String codigoBarrasProducto,
  }) async {
    final batch = _db.batch();

    batch.update(_devCol.doc(devolucionId), {
      'estado': nuevoEstado.name,
      'admin_uid': adminUid,
      'fecha_resolucion': FieldValue.serverTimestamp(),
    });

    if (nuevoEstado == EstadoDevolucion.aprobada) {
      batch.update(_db.collection('tarjetas').doc(tarjetaId), {
        'saldo_pendiente': FieldValue.increment(-montoReembolso),
        'total_devuelto': FieldValue.increment(montoReembolso),
      });

      if (codigoBarrasProducto.isNotEmpty) {
        batch.update(
          _db.collection('productos').doc(codigoBarrasProducto),
          {'cantidad_stock': FieldValue.increment(cantidadDevuelta)},
        );
      }
    }

    await batch.commit();

    // Revertir vendidos en asignaciones_productos de la asesora
    if (nuevoEstado == EstadoDevolucion.aprobada &&
        codigoBarrasProducto.isNotEmpty) {
      final snap = await _db
          .collection('asignaciones_productos')
          .where('asesora_uid', isEqualTo: asesoraUid)
          .where('codigo_barras', isEqualTo: codigoBarrasProducto)
          .where('activa', isEqualTo: true)
          .get();
      if (snap.docs.isNotEmpty) {
        await _db
            .collection('asignaciones_productos')
            .doc(snap.docs.first.id)
            .update({
          'cantidad_vendida': FieldValue.increment(-cantidadDevuelta),
        });
      }
    }
  }

  // Devoluciones del día de hoy
  Future<int> contarDevolucionesHoy() async {
    final hoy = DateTime.now();
    final inicio = DateTime(hoy.year, hoy.month, hoy.day);
    final fin = inicio.add(const Duration(days: 1));
    final snap = await _devCol
        .where(
          'fecha_devolucion',
          isGreaterThanOrEqualTo: Timestamp.fromDate(inicio),
        )
        .where('fecha_devolucion', isLessThan: Timestamp.fromDate(fin))
        .get();
    return snap.docs.length;
  }

  // ─── ASIGNACIONES ─────────────────────────────────────────────────────────

  // Asignar tarjeta a cobrador (previene duplicados)
  Future<void> asignar(AsignacionModel asignacion) async {
    final existing = await _asigCol
        .where('cobrador_uid', isEqualTo: asignacion.cobradorUid)
        .where('tarjeta_id', isEqualTo: asignacion.tarjetaId)
        .where('activa', isEqualTo: true)
        .get();
    if (existing.docs.isNotEmpty) return;
    await _asigCol.doc().set(asignacion.toMap());
  }

  // Stream de asignaciones activas de un cobrador
  Stream<List<AsignacionModel>> streamAsignacionesCobrador(String cobradorUid) {
    return _asigCol
        .where('cobrador_uid', isEqualTo: cobradorUid)
        .where('activa', isEqualTo: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (d) => AsignacionModel.fromMap(
                  d.data(),
                  d.id,
                ),
              )
              .toList(),
        );
  }

  // Stream de todas las asignaciones (admin)
  Stream<List<AsignacionModel>> streamTodasAsignaciones() {
    return _asigCol
        .orderBy('fecha_asignacion', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (d) => AsignacionModel.fromMap(
                  d.data(),
                  d.id,
                ),
              )
              .toList(),
        );
  }

  // Desactivar asignación
  Future<void> desactivarAsignacion(String asignacionId) async {
    await _asigCol.doc(asignacionId).update({'activa': false});
  }
}
