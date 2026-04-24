// lib/services/tarjeta_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tarjeta_model.dart';

class TarjetaService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _col = FirebaseFirestore.instance.collection('tarjetas');
  final _tpCol = FirebaseFirestore.instance.collection('tarjeta_productos');

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

      // Descontar del inventario
      final inventarioRef = _db.collection('productos').doc(prod.codigoBarras);
      batch.update(inventarioRef, {
        'cantidad_stock': FieldValue.increment(-prod.cantidad),
      });
    }

    // Guardar cuotas
    for (final cuota in cuotas) {
      final cuotaRef = _db.collection('cuotas').doc();
      batch.set(cuotaRef, {...cuota.toMap(), 'tarjeta_id': tarjetaId});
    }

    await batch.commit();
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

  // Tarjetas del mes actual
  Future<List<TarjetaModel>> tarjetasDelMes() async {
    final ahora = DateTime.now();
    final inicio = DateTime(ahora.year, ahora.month, 1);
    final fin = DateTime(ahora.year, ahora.month + 1, 1);

    final snap = await _col
        .where(
          'fecha_venta',
          isGreaterThanOrEqualTo: Timestamp.fromDate(inicio),
        )
        .where('fecha_venta', isLessThan: Timestamp.fromDate(fin))
        .orderBy('fecha_venta', descending: true)
        .get();

    return snap.docs.map((d) => TarjetaModel.fromMap(d.data(), d.id)).toList();
  }

  // Tarjetas de los últimos N días
  Future<List<TarjetaModel>> tarjetasUltimosDias(int dias) async {
    final desde = DateTime.now().subtract(Duration(days: dias));
    final snap = await _col
        .where('fecha_venta', isGreaterThanOrEqualTo: Timestamp.fromDate(desde))
        .orderBy('fecha_venta', descending: true)
        .get();
    return snap.docs.map((d) => TarjetaModel.fromMap(d.data(), d.id)).toList();
  }

  // Obtener tarjeta por id
  Future<TarjetaModel?> obtenerTarjeta(String tarjetaId) async {
    final doc = await _col.doc(tarjetaId).get();
    if (!doc.exists) return null;
    return TarjetaModel.fromMap(doc.data()!, doc.id);
  }

  // Actualizar foto de la tarjeta
  Future<void> actualizarFoto(String tarjetaId, String fotoUrl) async {
    await _col.doc(tarjetaId).update({'foto_url': fotoUrl});
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
