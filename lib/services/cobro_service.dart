// lib/services/cobro_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comision_model.dart';
import '../models/tarjeta_model.dart';
import 'comision_service.dart';

class CobroService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _cuotasCol = FirebaseFirestore.instance.collection('cuotas');
  final _devCol = FirebaseFirestore.instance.collection('devoluciones');
  final _asigCol = FirebaseFirestore.instance.collection('asignaciones');
  final _comisionService = ComisionService();

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
    required String nombreCobrador,
    required String nombreCliente,
    required double monto,
    required double saldoActual,
    String? observacion,
  }) async {
    final batch = _db.batch();

    batch.update(_cuotasCol.doc(cuotaId), {
      'estado': EstadoCuota.cobrada.name,
      'cobrador_uid': cobradorUid,
      'fecha_cobro': FieldValue.serverTimestamp(),
      'observacion': observacion,
    });

    final tarjetaRef = _db.collection('tarjetas').doc(tarjetaId);
    if (monto >= saldoActual) {
      batch.update(tarjetaRef, {
        'saldo_pendiente': 0.0,
        'estado': EstadoTarjeta.pagada.name,
      });
    } else {
      batch.update(tarjetaRef, {
        'saldo_pendiente': FieldValue.increment(-monto),
      });
    }

    await batch.commit().timeout(const Duration(seconds: 10), onTimeout: () {});

    await _comisionService
        .registrarComision(
          tipo: TipoComision.cobro,
          usuarioUid: cobradorUid,
          nombreUsuario: nombreCobrador,
          tarjetaId: tarjetaId,
          nombreCliente: nombreCliente,
          montoBase: monto,
        )
        .timeout(const Duration(seconds: 5), onTimeout: () {});
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
    required String nombreCobrador,
    required String nombreCliente,
    required double monto,
    required double saldoActual,
    String? observacion,
    String? fotoUrl,
  }) async {
    final batch = _db.batch();

    final pagoRef = _db.collection('pagos_registrados').doc();
    batch.set(pagoRef, {
      'tarjeta_id': tarjetaId,
      'cobrador_uid': cobradorUid,
      'monto': monto,
      'observacion': observacion,
      'foto_url': fotoUrl,
      'fecha': FieldValue.serverTimestamp(),
    });

    final tarjetaRef = _db.collection('tarjetas').doc(tarjetaId);
    if (monto >= saldoActual) {
      batch.update(tarjetaRef, {
        'saldo_pendiente': 0.0,
        'estado': EstadoTarjeta.pagada.name,
      });
    } else {
      batch.update(tarjetaRef, {
        'saldo_pendiente': FieldValue.increment(-monto),
      });
    }

    await batch.commit().timeout(const Duration(seconds: 10), onTimeout: () {});

    await _comisionService
        .registrarComision(
          tipo: TipoComision.cobro,
          usuarioUid: cobradorUid,
          nombreUsuario: nombreCobrador,
          tarjetaId: tarjetaId,
          nombreCliente: nombreCliente,
          montoBase: monto,
        )
        .timeout(const Duration(seconds: 5), onTimeout: () {});
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

  // Solicitar devolución (asesora o cobrador; pasa origen: 'cobrador' si aplica)
  Future<String> solicitarDevolucion(DevolucionModel devolucion, {String? origen}) async {
    final batch = _db.batch();

    final ref = _devCol.doc();
    batch.set(ref, {
      ...devolucion.toMap(),
      'estado': EstadoDevolucion.pendiente.name,
      'origen': ?origen,
    });

    batch.update(_db.collection('tarjetas').doc(devolucion.tarjetaId), {
      'estado': EstadoTarjeta.enDevolucion.name,
    });

    await batch.commit().timeout(const Duration(seconds: 5), onTimeout: () {});
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
        'estado': EstadoTarjeta.activa.name,
      });

      if (codigoBarrasProducto.isNotEmpty) {
        batch.update(
          _db.collection('productos').doc(codigoBarrasProducto),
          {'cantidad_stock': FieldValue.increment(cantidadDevuelta)},
        );
      }
    } else {
      batch.update(_db.collection('tarjetas').doc(tarjetaId), {
        'estado': EstadoTarjeta.activa.name,
      });
    }

    await batch.commit().timeout(const Duration(seconds: 10), onTimeout: () {});

    // Fire-and-forget: no bloquea la UI — se reintenta en la próxima sync
    if (nuevoEstado == EstadoDevolucion.aprobada &&
        codigoBarrasProducto.isNotEmpty) {
      _revertirAsignacionProducto(asesoraUid, codigoBarrasProducto, cantidadDevuelta);
    }
  }

  void _revertirAsignacionProducto(
    String asesoraUid,
    String codigoBarras,
    int cantidad,
  ) {
    _db
        .collection('asignaciones_productos')
        .where('asesora_uid', isEqualTo: asesoraUid)
        .where('codigo_barras', isEqualTo: codigoBarras)
        .where('activa', isEqualTo: true)
        .get()
        .then((snap) {
      if (snap.docs.isNotEmpty) {
        snap.docs.first.reference.update({
          'cantidad_vendida': FieldValue.increment(-cantidad),
        }).catchError((_) {});
      }
    }).catchError((_) {});
  }

  // Devoluciones del día de hoy
  Future<int> contarDevolucionesHoy() async {
    final hoy = DateTime.now();
    final inicio = DateTime(hoy.year, hoy.month, hoy.day);
    final fin = inicio.add(const Duration(days: 1));
    final agg = await _devCol
        .where(
          'fecha_devolucion',
          isGreaterThanOrEqualTo: Timestamp.fromDate(inicio),
        )
        .where('fecha_devolucion', isLessThan: Timestamp.fromDate(fin))
        .count()
        .get();
    return agg.count ?? 0;
  }

  // Descuento quincena asesora: 20% de devoluciones aprobadas sin pagar
  Future<double> deduccionDevolucionesAsesora(String asesoraUid) async {
    final snap = await _devCol
        .where('asesora_uid', isEqualTo: asesoraUid)
        .where('estado', isEqualTo: EstadoDevolucion.aprobada.name)
        .get(const GetOptions(source: Source.server));
    return snap.docs.fold<double>(0.0, (acc, d) {
      final monto = (d.data()['monto_reembolso'] ?? 0.0).toDouble();
      return acc + monto * 0.20;
    });
  }

  // ─── ASIGNACIONES ─────────────────────────────────────────────────────────

  // Asignar todas las tarjetas de una zona a un cobrador (batch)
  Future<void> asignarPorZona({
    required String cobradorUid,
    required String nombreCobrador,
    required List<AsignacionModel> asignaciones,
  }) async {
    if (asignaciones.isEmpty) return;
    final batch = _db.batch();
    for (final a in asignaciones) {
      final ref = _asigCol.doc();
      batch.set(ref, {...a.toMap(), 'asignacion_id': ref.id});
    }
    await batch.commit();
  }

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

  // Desactivar asignación individual
  Future<void> desactivarAsignacion(String asignacionId) async {
    await _asigCol.doc(asignacionId).update({'activa': false});
  }

  // Desactivar múltiples asignaciones en un solo batch
  Future<void> desactivarAsignacionesBatch(List<String> ids) async {
    if (ids.isEmpty) return;
    final batch = _db.batch();
    for (final id in ids) {
      batch.update(_asigCol.doc(id), {'activa': false});
    }
    await batch.commit();
  }
}
