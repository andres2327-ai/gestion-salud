// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/usuario_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream del usuario autenticado actual
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // Crear usuario (solo admin/superAdmin)
  Future<String> crearUsuario({
    required String email,
    required String password,
    required String nombre,
    required String telefono,
    required String direccion,
    required RolUsuario rol,
  }) async {
    final adminUser = _auth.currentUser;
    if (adminUser == null) {
      throw Exception('No hay admin autenticado');
    }

    final adminUid = adminUser.uid;

    try {
      // Crear una instancia secundaria de Firebase
      final secondaryFirebase = await Firebase.initializeApp(
        name: 'CreateUserApp',
        options: Firebase.app().options,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryFirebase);

      // Crear nuevo usuario en la instancia secundaria
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final nuevoUid = credential.user!.uid;

      // Guardar perfil en Firestore
      await _db.collection('usuarios').doc(nuevoUid).set({
        'nombre': nombre,
        'telefono': telefono,
        'direccion': direccion,
        'email': email.trim(),
        'rol': rol.name,
        'activo': true,
        'fecha_creacion': FieldValue.serverTimestamp(),
      });

      // Asegurarse de que el admin sigue autenticado
      if (_auth.currentUser?.uid != adminUid) {
        debugPrint('⚠️ Advertencia: La sesión del admin cambió durante la creación');
      }

      return nuevoUid;
    } catch (e) {
      debugPrint('❌ Error al crear usuario: $e');
      rethrow;
    }
  }

  // Inicio de sesión
  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  // Cerrar sesión
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Obtener perfil del usuario autenticado (cache-first para rapidez y offline)
  Future<UsuarioModel?> obtenerPerfil(String uid) async {
    try {
      final cached = await _db
          .collection('usuarios')
          .doc(uid)
          .get(const GetOptions(source: Source.cache));
      if (cached.exists) return UsuarioModel.fromMap(cached.data()!, cached.id);
    } catch (_) {
      // Sin caché — continúa con el servidor
    }
    final doc = await _db.collection('usuarios').doc(uid).get();
    if (!doc.exists) return null;
    return UsuarioModel.fromMap(doc.data()!, doc.id);
  }

  // Cambiar contraseña
  Future<void> cambiarPassword(String nuevaPassword) async {
    await _auth.currentUser?.updatePassword(nuevaPassword);
  }

  // Resetear contraseña por email
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }
}
