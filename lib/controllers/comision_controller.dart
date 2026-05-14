// lib/controllers/comision_controller.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/comision_model.dart';
import '../services/comision_service.dart';

class ComisionState {
  final List<ComisionModel> comisiones;
  final bool cargando;
  final String? error;
  final String? exito;

  const ComisionState({
    this.comisiones = const [],
    this.cargando = false,
    this.error,
    this.exito,
  });

  double get totalPendiente => comisiones
      .where((c) => c.estado == EstadoComision.pendiente)
      .fold(0.0, (s, c) => s + c.montoComision);

  double get totalPagado => comisiones
      .where((c) => c.estado == EstadoComision.pagada)
      .fold(0.0, (s, c) => s + c.montoComision);

  ComisionState copyWith({
    List<ComisionModel>? comisiones,
    bool? cargando,
    String? error,
    String? exito,
  }) {
    return ComisionState(
      comisiones: comisiones ?? this.comisiones,
      cargando: cargando ?? this.cargando,
      error: error,
      exito: exito,
    );
  }
}

class ComisionController extends StateNotifier<ComisionState> {
  final ComisionService _service;
  StreamSubscription<List<ComisionModel>>? _sub;

  ComisionController(this._service) : super(const ComisionState());

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void escucharComisionesUsuario(String usuarioUid) {
    _sub?.cancel();
    _sub = _service.streamComisionesUsuario(usuarioUid).listen((lista) {
      state = state.copyWith(comisiones: lista);
    });
  }

  void escucharComisionesPendientes() {
    _sub?.cancel();
    _sub = _service.streamComisionesPendientes().listen((lista) {
      state = state.copyWith(comisiones: lista, cargando: false);
    }, onError: (_) {
      state = state.copyWith(cargando: false);
    });
  }

  void escucharTodasComisiones() {
    _sub?.cancel();
    _sub = _service.streamTodasComisiones().listen((lista) {
      state = state.copyWith(comisiones: lista);
    });
  }

  Future<List<ComisionModel>> cargarQuincenaActual(String usuarioUid) async {
    state = state.copyWith(cargando: true);
    try {
      final lista = await _service.comisionesQuincenaActual(usuarioUid);
      state = state.copyWith(cargando: false);
      return lista;
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
      return [];
    }
  }

  Future<List<ComisionModel>> cargarQuincenaTodos() async {
    state = state.copyWith(cargando: true);
    try {
      final lista = await _service.comisionesQuincenaTodos();
      state = state.copyWith(cargando: false);
      return lista;
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
      return [];
    }
  }

  Future<bool> marcarPagadas(List<String> ids) async {
    state = state.copyWith(cargando: true, error: null);
    try {
      await _service.marcarPagadas(ids);
      state = state.copyWith(cargando: false, exito: 'Comisiones marcadas como pagadas.');
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
