// lib/models/comision_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum TipoComision { venta, cobro }

enum EstadoComision { pendiente, pagada }

class ComisionModel {
  final String comisionId;
  final String usuarioUid;
  final String nombreUsuario;
  final TipoComision tipo;
  final String tarjetaId;
  final String nombreCliente;
  final double montoBase;
  final double porcentaje;
  final double montoComision;
  final EstadoComision estado;
  final DateTime fecha;
  final DateTime? fechaPago;

  ComisionModel({
    required this.comisionId,
    required this.usuarioUid,
    required this.nombreUsuario,
    required this.tipo,
    required this.tarjetaId,
    required this.nombreCliente,
    required this.montoBase,
    this.porcentaje = 0.20,
    required this.montoComision,
    this.estado = EstadoComision.pendiente,
    required this.fecha,
    this.fechaPago,
  });

  factory ComisionModel.fromMap(Map<String, dynamic> map, String id) {
    return ComisionModel(
      comisionId: id,
      usuarioUid: map['usuario_uid'] ?? '',
      nombreUsuario: map['nombre_usuario'] ?? '',
      tipo: TipoComision.values.firstWhere(
        (t) => t.name == map['tipo'],
        orElse: () => TipoComision.venta,
      ),
      tarjetaId: map['tarjeta_id'] ?? '',
      nombreCliente: map['nombre_cliente'] ?? '',
      montoBase: (map['monto_base'] ?? 0).toDouble(),
      porcentaje: (map['porcentaje'] ?? 0.20).toDouble(),
      montoComision: (map['monto_comision'] ?? 0).toDouble(),
      estado: EstadoComision.values.firstWhere(
        (e) => e.name == map['estado'],
        orElse: () => EstadoComision.pendiente,
      ),
      fecha: map['fecha'] != null
          ? (map['fecha'] as Timestamp).toDate()
          : DateTime.now(),
      fechaPago: map['fecha_pago'] != null
          ? (map['fecha_pago'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'usuario_uid': usuarioUid,
      'nombre_usuario': nombreUsuario,
      'tipo': tipo.name,
      'tarjeta_id': tarjetaId,
      'nombre_cliente': nombreCliente,
      'monto_base': montoBase,
      'porcentaje': porcentaje,
      'monto_comision': montoComision,
      'estado': estado.name,
      'fecha': FieldValue.serverTimestamp(),
      'fecha_pago': fechaPago,
    };
  }
}
