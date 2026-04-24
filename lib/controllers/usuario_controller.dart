// lib/controllers/usuario_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/usuario_model.dart';
import '../services/auth_service.dart';
import '../services/usuario_service.dart';

class UsuarioState {
  final List<UsuarioModel> asesoras;
  final List<UsuarioModel> cobradores;
  final List<UsuarioModel> todos;
  final bool cargando;
  final String? error;
  final String? exito;

  const UsuarioState({
    this.asesoras = const [],
    this.cobradores = const [],
    this.todos = const [],
    this.cargando = false,
    this.error,
    this.exito,
  });

  UsuarioState copyWith({
    List<UsuarioModel>? asesoras,
    List<UsuarioModel>? cobradores,
    List<UsuarioModel>? todos,
    bool? cargando,
    String? error,
    String? exito,
  }) {
    return UsuarioState(
      asesoras: asesoras ?? this.asesoras,
      cobradores: cobradores ?? this.cobradores,
      todos: todos ?? this.todos,
      cargando: cargando ?? this.cargando,
      error: error,
      exito: exito,
    );
  }
}

class UsuarioController extends StateNotifier<UsuarioState> {
  final UsuarioService _usuarioService;
  final AuthService _authService;

  UsuarioController(this._usuarioService, this._authService)
    : super(const UsuarioState());

  // Cargar asesoras, cobradores y todos
  Future<void> cargar() async {
    state = state.copyWith(cargando: true);
    try {
      final asesoras = await _usuarioService.obtenerAsesoras();
      final cobradores = await _usuarioService.obtenerCobradores();
      final todos = await _usuarioService.obtenerTodos();
      state = state.copyWith(
        asesoras: asesoras,
        cobradores: cobradores,
        todos: todos,
        cargando: false,
      );
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
    }
  }

  // Crear asesora o cobrador (admin)
  Future<bool> crearUsuario({
    required String email,
    required String password,
    required String nombre,
    required String telefono,
    required String direccion,
    required RolUsuario rol,
  }) async {
    state = state.copyWith(cargando: true, error: null, exito: null);
    try {
      await _authService.crearUsuario(
        email: email,
        password: password,
        nombre: nombre,
        telefono: telefono,
        direccion: direccion,
        rol: rol,
      );

      await Future.delayed(const Duration(milliseconds: 500));
      await cargar();

      state = state.copyWith(
        cargando: false,
        exito: 'Usuario creado exitosamente.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        cargando: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  // Actualizar datos
  Future<void> actualizarUsuario(
    String uid,
    Map<String, dynamic> datos,
  ) async {
    state = state.copyWith(cargando: true);
    try {
      await _usuarioService.actualizarUsuario(uid, datos);
      await cargar();
      state = state.copyWith(exito: 'Usuario actualizado.');
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
    }
  }

  // Toggle activo/inactivo
  Future<void> toggleActivo(UsuarioModel usuario) async {
    try {
      if (usuario.activo) {
        await _usuarioService.desactivarUsuario(usuario.uid);
      } else {
        await _usuarioService.reactivarUsuario(usuario.uid);
      }
      await cargar();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Desactivar usuario
  Future<void> desactivarUsuario(String uid) async {
    try {
      await _usuarioService.desactivarUsuario(uid);
      await cargar();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Reactivar usuario
  Future<void> reactivarUsuario(String uid) async {
    try {
      await _usuarioService.reactivarUsuario(uid);
      await cargar();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void limpiarMensajes() {
    state = state.copyWith(error: null, exito: null);
  }
}
