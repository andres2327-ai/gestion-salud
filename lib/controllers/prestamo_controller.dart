// lib/controllers/prestamo_controller.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/prestamo_model.dart';
import '../services/prestamo_service.dart';

class PrestamoState {
  final List<PrestamoModel> prestamos;
  final bool cargando;
  final String? error;
  final String? exito;

  const PrestamoState({
    this.prestamos = const [],
    this.cargando = false,
    this.error,
    this.exito,
  });

  PrestamoState copyWith({
    List<PrestamoModel>? prestamos,
    bool? cargando,
    String? error,
    String? exito,
  }) {
    return PrestamoState(
      prestamos: prestamos ?? this.prestamos,
      cargando: cargando ?? this.cargando,
      error: error,
      exito: exito,
    );
  }
}

class PrestamoController extends StateNotifier<PrestamoState> {
  final PrestamoService _service;
  StreamSubscription<List<PrestamoModel>>? _sub;

  PrestamoController(this._service) : super(const PrestamoState());

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void escucharPendientes() {
    _sub?.cancel();
    _sub = _service.streamPendientes().listen((lista) {
      state = state.copyWith(prestamos: lista, cargando: false);
    });
  }

  void escucharMisPrestamos(String uid) {
    _sub?.cancel();
    _sub = _service.streamUsuario(uid).listen((lista) {
      state = state.copyWith(prestamos: lista, cargando: false);
    });
  }

  Future<bool> solicitar({
    required String usuarioUid,
    required String nombreUsuario,
    required String rol,
    required double monto,
    required String motivo,
  }) async {
    state = state.copyWith(cargando: true, error: null);
    try {
      final p = PrestamoModel(
        prestamoId: '',
        usuarioUid: usuarioUid,
        nombreUsuario: nombreUsuario,
        rol: rol,
        monto: monto,
        saldoPendiente: monto,
        motivo: motivo,
        estado: EstadoPrestamo.pendiente,
        fechaSolicitud: DateTime.now(),
      );
      await _service.solicitar(p);
      state = state.copyWith(cargando: false, exito: 'Préstamo solicitado.');
      return true;
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
      return false;
    }
  }

  Future<bool> resolver({
    required String prestamoId,
    required bool aprobado,
    required String adminUid,
  }) async {
    state = state.copyWith(cargando: true, error: null);
    try {
      await _service.resolver(
        prestamoId: prestamoId,
        aprobado: aprobado,
        adminUid: adminUid,
      );
      state = state.copyWith(
        cargando: false,
        exito: aprobado ? 'Préstamo aprobado.' : 'Préstamo rechazado.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
      return false;
    }
  }

  void limpiarMensajes() {
    state = state.copyWith(error: null, exito: null);
  }
}
