// lib/controllers/dashboard_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/dashboard_service.dart';

// ─── Dashboard (admin) ────────────────────────────────────────────────────────
class DashboardState {
  final DashboardStats? stats;
  final bool cargando;
  final String? error;

  const DashboardState({this.stats, this.cargando = false, this.error});

  DashboardState copyWith({
    DashboardStats? stats,
    bool? cargando,
    String? error,
  }) {
    return DashboardState(
      stats: stats ?? this.stats,
      cargando: cargando ?? this.cargando,
      error: error,
    );
  }
}

class DashboardController extends StateNotifier<DashboardState> {
  final DashboardService _service;

  DashboardController(this._service) : super(const DashboardState()) {
    cargar();
  }

  Future<void> cargar() async {
    state = state.copyWith(cargando: true, error: null);
    try {
      final stats = await _service.obtenerStats();
      state = state.copyWith(stats: stats, cargando: false);
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
    }
  }

  Future<void> refrescar() => cargar();
}

// ─── Reportes ─────────────────────────────────────────────────────────────────
class ReporteState {
  final Map<String, dynamic>? datos;
  final bool cargando;
  final String? error;
  final int? mesSeleccionado;
  final int? anioSeleccionado;
  final DateTime? diaSeleccionado;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;

  const ReporteState({
    this.datos,
    this.cargando = false,
    this.error,
    this.mesSeleccionado,
    this.anioSeleccionado,
    this.diaSeleccionado,
    this.fechaInicio,
    this.fechaFin,
  });

  // Distribución por asesora para el gráfico de donas
  Map<String, double> get distribucionAsesoras {
    if (datos == null) return {};
    final raw = datos!['por_asesora'] as Map<String, dynamic>? ?? {};
    return raw.map((k, v) => MapEntry(k, (v as num).toDouble()));
  }

  double get totalMes => (datos?['total'] as num?)?.toDouble() ?? 0;
  int get numVentas => (datos?['num_ventas'] as num?)?.toInt() ?? 0;

  // Propiedades para reportes por rango de fechas
  double get totalVentas => (datos?['total_ventas'] as num?)?.toDouble() ?? 0;
  double get totalCobros => (datos?['total_cobros'] as num?)?.toDouble() ?? 0;
  double get saldoPendiente => (datos?['saldo_pendiente'] as num?)?.toDouble() ?? 0;

  ReporteState copyWith({
    Map<String, dynamic>? datos,
    bool? cargando,
    String? error,
    int? mesSeleccionado,
    int? anioSeleccionado,
    DateTime? diaSeleccionado,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) {
    return ReporteState(
      datos: datos ?? this.datos,
      cargando: cargando ?? this.cargando,
      error: error,
      mesSeleccionado: mesSeleccionado ?? this.mesSeleccionado,
      anioSeleccionado: anioSeleccionado ?? this.anioSeleccionado,
      diaSeleccionado: diaSeleccionado ?? this.diaSeleccionado,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
    );
  }
}

class ReporteController extends StateNotifier<ReporteState> {
  final DashboardService _service;

  ReporteController(this._service) : super(const ReporteState()) {
    // Cargar el mes actual por defecto
    final ahora = DateTime.now();
    cargarMensual(ahora.year, ahora.month);
  }

  Future<void> cargarMensual(int anio, int mes) async {
    state = state.copyWith(
      cargando: true,
      error: null,
      anioSeleccionado: anio,
      mesSeleccionado: mes,
      diaSeleccionado: null,
      fechaInicio: null,
      fechaFin: null,
    );
    try {
      final datos = await _service.reporteMensual(anio, mes);
      state = state.copyWith(datos: datos, cargando: false);
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
    }
  }

  Future<void> cargarDia(DateTime dia) async {
    state = state.copyWith(
      cargando: true,
      error: null,
      diaSeleccionado: dia,
      mesSeleccionado: null,
      fechaInicio: null,
      fechaFin: null,
    );
    try {
      final datos = await _service.reporteDia(dia);
      state = state.copyWith(datos: datos, cargando: false);
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
    }
  }

  /// Cargar reporte por rango de fechas
  Future<void> cargarRangoFechas(
    int anioInicio,
    int mesInicio,
    int diaInicio,
    int anioFin,
    int mesFin,
    int diaFin,
  ) async {
    final inicio = DateTime(anioInicio, mesInicio, diaInicio);
    final fin = DateTime(anioFin, mesFin, diaFin);

    state = state.copyWith(
      cargando: true,
      error: null,
      fechaInicio: inicio,
      fechaFin: fin,
      diaSeleccionado: null,
      mesSeleccionado: null,
    );
    try {
      final datos = await _service.reporteRangoFechas(inicio, fin);
      state = state.copyWith(datos: datos, cargando: false);
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
    }
  }
}
