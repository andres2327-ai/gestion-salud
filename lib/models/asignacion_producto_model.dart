import 'package:cloud_firestore/cloud_firestore.dart';

class AsignacionProductoModel {
  final String id;
  final String asesoraUid;
  final String codigoBarras;
  final String nombreProducto;
  final double precioUnitario;
  final int cantidadAsignada;
  final int cantidadVendida;
  final bool activa;
  final DateTime fechaAsignacion;

  AsignacionProductoModel({
    required this.id,
    required this.asesoraUid,
    required this.codigoBarras,
    required this.nombreProducto,
    required this.precioUnitario,
    required this.cantidadAsignada,
    required this.cantidadVendida,
    required this.activa,
    required this.fechaAsignacion,
  });

  int get cantidadDisponible => cantidadAsignada - cantidadVendida;

  factory AsignacionProductoModel.fromMap(Map<String, dynamic> map, String id) {
    return AsignacionProductoModel(
      id: id,
      asesoraUid: map['asesora_uid'] ?? '',
      codigoBarras: map['codigo_barras'] ?? '',
      nombreProducto: map['nombre_producto'] ?? '',
      precioUnitario: (map['precio_unitario'] ?? 0).toDouble(),
      cantidadAsignada: map['cantidad_asignada'] ?? 0,
      cantidadVendida: map['cantidad_vendida'] ?? 0,
      activa: map['activa'] ?? true,
      fechaAsignacion: map['fecha_asignacion'] != null
          ? (map['fecha_asignacion'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'asesora_uid': asesoraUid,
      'codigo_barras': codigoBarras,
      'nombre_producto': nombreProducto,
      'precio_unitario': precioUnitario,
      'cantidad_asignada': cantidadAsignada,
      'cantidad_vendida': cantidadVendida,
      'activa': activa,
      'fecha_asignacion': FieldValue.serverTimestamp(),
    };
  }

  AsignacionProductoModel copyWith({
    int? cantidadAsignada,
    int? cantidadVendida,
    bool? activa,
  }) {
    return AsignacionProductoModel(
      id: id,
      asesoraUid: asesoraUid,
      codigoBarras: codigoBarras,
      nombreProducto: nombreProducto,
      precioUnitario: precioUnitario,
      cantidadAsignada: cantidadAsignada ?? this.cantidadAsignada,
      cantidadVendida: cantidadVendida ?? this.cantidadVendida,
      activa: activa ?? this.activa,
      fechaAsignacion: fechaAsignacion,
    );
  }
}
