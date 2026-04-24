// lib/models/usuario_model.dart

enum RolUsuario { superAdmin, admin, asesora, cobrador }

class UsuarioModel {
  final String uid;
  final String nombre;
  final String telefono;
  final String direccion;
  final String email;
  final RolUsuario rol;
  final bool activo;
  final DateTime fechaCreacion;
  final double metaMensual;

  UsuarioModel({
    required this.uid,
    required this.nombre,
    required this.telefono,
    required this.direccion,
    required this.email,
    required this.rol,
    required this.activo,
    required this.fechaCreacion,
    this.metaMensual = 1500000,
  });

  factory UsuarioModel.fromMap(Map<String, dynamic> map, String uid) {
    return UsuarioModel(
      uid: uid,
      nombre: map['nombre'] ?? '',
      telefono: map['telefono'] ?? '',
      direccion: map['direccion'] ?? '',
      email: map['email'] ?? '',
      rol: RolUsuario.values.firstWhere(
        (r) => r.name == map['rol'],
        orElse: () => RolUsuario.asesora,
      ),
      activo: map['activo'] ?? true,
      fechaCreacion: map['fecha_creacion'] != null
          ? (map['fecha_creacion'] as dynamic).toDate()
          : DateTime.now(),
      metaMensual: (map['meta_mensual'] ?? 1500000).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'telefono': telefono,
      'direccion': direccion,
      'email': email,
      'rol': rol.name,
      'activo': activo,
      'fecha_creacion': fechaCreacion,
      'meta_mensual': metaMensual,
    };
  }

  UsuarioModel copyWith({
    String? nombre,
    String? telefono,
    String? direccion,
    String? email,
    RolUsuario? rol,
    bool? activo,
    double? metaMensual,
  }) {
    return UsuarioModel(
      uid: uid,
      nombre: nombre ?? this.nombre,
      telefono: telefono ?? this.telefono,
      direccion: direccion ?? this.direccion,
      email: email ?? this.email,
      rol: rol ?? this.rol,
      activo: activo ?? this.activo,
      fechaCreacion: fechaCreacion,
      metaMensual: metaMensual ?? this.metaMensual,
    );
  }
}
