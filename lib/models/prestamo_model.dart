// lib/models/prestamo_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum EstadoPrestamo { pendiente, aprobado, rechazado }

class PrestamoModel {
  final String prestamoId;
  final String usuarioUid;
  final String nombreUsuario;
  final String rol;
  final double monto;
  final double saldoPendiente;
  final String motivo;
  final EstadoPrestamo estado;
  final DateTime fechaSolicitud;
  final DateTime? fechaResolucion;
  final String? adminUid;

  const PrestamoModel({
    required this.prestamoId,
    required this.usuarioUid,
    required this.nombreUsuario,
    required this.rol,
    required this.monto,
    required this.saldoPendiente,
    required this.motivo,
    required this.estado,
    required this.fechaSolicitud,
    this.fechaResolucion,
    this.adminUid,
  });

  factory PrestamoModel.fromMap(Map<String, dynamic> map, String id) {
    return PrestamoModel(
      prestamoId: id,
      usuarioUid: map['usuario_uid'] ?? '',
      nombreUsuario: map['nombre_usuario'] ?? '',
      rol: map['rol'] ?? 'asesora',
      monto: (map['monto'] ?? 0).toDouble(),
      saldoPendiente: (map['saldo_pendiente'] ?? 0).toDouble(),
      motivo: map['motivo'] ?? '',
      estado: EstadoPrestamo.values.firstWhere(
        (e) => e.name == map['estado'],
        orElse: () => EstadoPrestamo.pendiente,
      ),
      fechaSolicitud: map['fecha_solicitud'] != null
          ? (map['fecha_solicitud'] as Timestamp).toDate()
          : DateTime.now(),
      fechaResolucion: map['fecha_resolucion'] != null
          ? (map['fecha_resolucion'] as Timestamp).toDate()
          : null,
      adminUid: map['admin_uid'],
    );
  }

  Map<String, dynamic> toMap() => {
        'usuario_uid': usuarioUid,
        'nombre_usuario': nombreUsuario,
        'rol': rol,
        'monto': monto,
        'saldo_pendiente': saldoPendiente,
        'motivo': motivo,
        'estado': estado.name,
        'fecha_solicitud': FieldValue.serverTimestamp(),
        'fecha_resolucion': null,
        'admin_uid': null,
      };
}
