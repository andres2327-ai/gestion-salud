// lib/services/usuario_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/usuario_model.dart';

class UsuarioService {
  final _col = FirebaseFirestore.instance.collection('usuarios');

  // Obtener un usuario por uid
  Future<UsuarioModel?> obtenerUsuario(String uid) async {
    final doc = await _col.doc(uid).get();
    if (!doc.exists) return null;
    return UsuarioModel.fromMap(doc.data()!, doc.id);
  }

  // Stream de todos los usuarios con un rol específico
  Stream<List<UsuarioModel>> streamPorRol(RolUsuario rol) {
    return _col
        .where('rol', isEqualTo: rol.name)
        .where('activo', isEqualTo: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => UsuarioModel.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  // Obtener lista de asesoras (todas, sin filtro de activo)
  Future<List<UsuarioModel>> obtenerAsesoras() async {
    final snap = await _col
        .where('rol', isEqualTo: RolUsuario.asesora.name)
        .get();
    return snap.docs.map((d) => UsuarioModel.fromMap(d.data(), d.id)).toList();
  }

  // Obtener lista de cobradores (todos, sin filtro de activo)
  Future<List<UsuarioModel>> obtenerCobradores() async {
    final snap = await _col
        .where('rol', isEqualTo: RolUsuario.cobrador.name)
        .get();
    return snap.docs.map((d) => UsuarioModel.fromMap(d.data(), d.id)).toList();
  }

  // Obtener todos los usuarios (admin ve asesoras + cobradores, sin admins)
  Future<List<UsuarioModel>> obtenerTodos() async {
    final snap = await _col.orderBy('fecha_creacion', descending: true).get();
    return snap.docs
        .map((d) => UsuarioModel.fromMap(d.data(), d.id))
        .where(
          (u) =>
              u.rol == RolUsuario.asesora || u.rol == RolUsuario.cobrador,
        )
        .toList();
  }

  // Actualizar datos de un usuario
  Future<void> actualizarUsuario(String uid, Map<String, dynamic> datos) async {
    await _col.doc(uid).update(datos);
  }

  // Desactivar (soft delete) usuario
  Future<void> desactivarUsuario(String uid) async {
    await _col.doc(uid).update({'activo': false});
  }

  // Reactivar usuario
  Future<void> reactivarUsuario(String uid) async {
    await _col.doc(uid).update({'activo': true});
  }

  // Stream de todos los usuarios (para superAdmin)
  Stream<List<UsuarioModel>> streamTodos() {
    return _col
        .orderBy('fecha_creacion', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => UsuarioModel.fromMap(d.data(), d.id))
              .toList(),
        );
  }
}
