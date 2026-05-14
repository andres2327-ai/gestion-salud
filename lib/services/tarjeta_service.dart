// lib/services/tarjeta_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tarjeta_model.dart';
import '../models/comision_model.dart';
import 'comision_service.dart';

class TarjetaService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _col = FirebaseFirestore.instance.collection('tarjetas');
  final _tpCol = FirebaseFirestore.instance.collection('tarjeta_productos');
  final _comisionService = ComisionService();

  // ─── Tarjetas ──────────────────────────────────────────────────────────────

  // Crear tarjeta + productos + cuotas en una transacción
  Future<String> crearTarjeta({
    required TarjetaModel tarjeta,
    required List<TarjetaProductoModel> productos,
    required List<CuotaModel> cuotas,
  }) async {
    final tarjetaRef = _col.doc();
    final tarjetaId = tarjetaRef.id;

    final batch = _db.batch();

    // Guardar tarjeta con productos embebidos para carga directa sin query extra
    batch.set(tarjetaRef, {
      ...tarjeta.toMap(),
      'tarjeta_id': tarjetaId,
      'productos': productos.map((p) => p.toMap()).toList(),
    });

    // Guardar productos de la tarjeta
    for (final prod in productos) {
      final prodRef = _tpCol.doc();
      batch.set(prodRef, {...prod.toMap(), 'tarjeta_id': tarjetaId});

      // Solo descontar del inventario si el producto NO es pendiente
      if (!prod.pendiente) {
        final inventarioRef = _db.collection('productos').doc(prod.codigoBarras);
        batch.update(inventarioRef, {
          'cantidad_stock': FieldValue.increment(-prod.cantidad),
        });
      }
    }

    // Guardar cuotas
    for (final cuota in cuotas) {
      final cuotaRef = _db.collection('cuotas').doc();
      batch.set(cuotaRef, {...cuota.toMap(), 'tarjeta_id': tarjetaId});
    }

    await batch.commit().timeout(const Duration(seconds: 10), onTimeout: () {});

    // Registrar comisión de la asesora (20% del total de venta)
    await _comisionService
        .registrarComision(
          tipo: TipoComision.venta,
          usuarioUid: tarjeta.asesoraUid,
          nombreUsuario: tarjeta.nombreAsesora,
          tarjetaId: tarjetaId,
          nombreCliente: tarjeta.nombreCliente,
          montoBase: tarjeta.totalVenta,
        )
        .timeout(const Duration(seconds: 5), onTimeout: () {});

    return tarjetaId;
  }

  // Stream tarjetas de una asesora (sin orderBy para evitar índice compuesto)
  Stream<List<TarjetaModel>> streamTarjetasAsesora(String asesoraUid) {
    return _col
        .where('asesora_uid', isEqualTo: asesoraUid)
        .snapshots()
        .map((snap) {
          final lista = snap.docs
              .map((d) => TarjetaModel.fromMap(d.data(), d.id))
              .toList();
          lista.sort((a, b) => b.fechaVenta.compareTo(a.fechaVenta));
          return lista;
        });
  }

  // Stream todas las tarjetas (admin) — sin orderBy para evitar índice
  Stream<List<TarjetaModel>> streamTodasLasTarjetas() {
    return _col.snapshots().map((snap) {
      final lista = snap.docs
          .map((d) => TarjetaModel.fromMap(d.data(), d.id))
          .toList();
      lista.sort((a, b) => b.fechaVenta.compareTo(a.fechaVenta));
      return lista;
    });
  }

  // Actualizar foto de la tarjeta
  Future<void> actualizarFoto(String tarjetaId, String fotoUrl) async {
    await _col
        .doc(tarjetaId)
        .update({'foto_url': fotoUrl})
        .timeout(const Duration(seconds: 5), onTimeout: () {});
  }

  // Stream de tarjetas por lista de IDs (para cobrador)
  Stream<List<TarjetaModel>> streamTarjetasPorIds(List<String> ids) {
    if (ids.isEmpty) return Stream.value([]);
    // Firestore whereIn acepta máx 10 elementos; particionamos si hay más
    if (ids.length <= 10) {
      return _col
          .where(FieldPath.documentId, whereIn: ids)
          .snapshots()
          .map(
            (snap) => snap.docs
                .map((d) => TarjetaModel.fromMap(d.data(), d.id))
                .toList(),
          );
    }
    // Más de 10: combinamos múltiples streams
    final streams = <Stream<List<TarjetaModel>>>[];
    for (int i = 0; i < ids.length; i += 10) {
      final chunk = ids.sublist(i, (i + 10).clamp(0, ids.length));
      streams.add(
        _col
            .where(FieldPath.documentId, whereIn: chunk)
            .snapshots()
            .map(
              (snap) => snap.docs
                  .map((d) => TarjetaModel.fromMap(d.data(), d.id))
                  .toList(),
            ),
      );
    }
    // Combina emitiendo cuando cualquier chunk cambia
    return streams.reduce(
      (a, b) => a.asyncExpand(
        (listA) => b.map((listB) => [...listA, ...listB]),
      ),
    );
  }

  // Actualizar campos de una tarjeta
  Future<void> actualizarTarjeta(
    String tarjetaId,
    Map<String, dynamic> datos,
  ) async {
    await _col
        .doc(tarjetaId)
        .update(datos)
        .timeout(const Duration(seconds: 5), onTimeout: () {});
  }

  // Eliminar tarjeta, sus cuotas y sus asignaciones
  Future<void> eliminarTarjeta(String tarjetaId) async {
    List<QuerySnapshot<Map<String, dynamic>>> results;
    try {
      results = await Future.wait([
        _db.collection('cuotas').where('tarjeta_id', isEqualTo: tarjetaId).get(),
        _db
            .collection('asignaciones')
            .where('tarjeta_id', isEqualTo: tarjetaId)
            .get(),
      ]).timeout(const Duration(seconds: 8));
    } catch (_) {
      // Sin conexión: sólo se elimina la tarjeta principal;
      // las cuotas y asignaciones se limpiarán cuando haya red.
      results = const [];
    }

    final batch = _db.batch();
    batch.delete(_col.doc(tarjetaId));
    if (results.length == 2) {
      for (final doc in results[0].docs) {
        batch.delete(doc.reference);
      }
      for (final doc in results[1].docs) {
        batch.delete(doc.reference);
      }
    }

    await batch.commit().timeout(const Duration(seconds: 10), onTimeout: () {});
  }

  // ─── Productos de una tarjeta ──────────────────────────────────────────────

  Future<List<TarjetaProductoModel>> obtenerProductosDeTarjeta(
    String tarjetaId,
  ) async {
    final snap = await _tpCol.where('tarjeta_id', isEqualTo: tarjetaId).get();
    return snap.docs
        .map((d) => TarjetaProductoModel.fromMap(d.data(), d.id))
        .toList();
  }
}
