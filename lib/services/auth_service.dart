// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
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

    final adminEmail = adminUser.email;
    final adminUid = adminUser.uid;
    String? adminPassword;

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
        // Si la sesión cambió, algo salió mal
        print('⚠️ Advertencia: La sesión del admin cambió durante la creación');
      }

      return nuevoUid;
    } catch (e) {
      print('❌ Error al crear usuario: $e');
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

  // Obtener perfil del usuario autenticado
  Future<UsuarioModel?> obtenerPerfil(String uid) async {
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
