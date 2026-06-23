// lib/services/reporte_personal_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tarjeta_model.dart';
import '../models/usuario_model.dart';
import '../models/prestamo_model.dart';

// ─── Pago libre registrado (datos ya procesados, sin Timestamp) ───────────────
class PagoRegistrado {
  final String tarjetaId;
  final DateTime fecha;
  final double monto;
  final String? observacion;

  const PagoRegistrado({
    required this.tarjetaId,
    required this.fecha,
    required this.monto,
    this.observacion,
  });
}

// ─── Datos del reporte de quincena ────────────────────────────────────────────
class ReportePersonalData {
  final UsuarioModel empleado;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final int quincena;

  // Asesora
  final List<TarjetaModel> ventas;
  final List<DevolucionModel> devoluciones;

  // Cobrador
  final List<CuotaModel> cuotasCobradas;
  final List<PagoRegistrado> pagosRegistrados;

  // Común
  final List<PrestamoModel> prestamos;

  // tarjetaId -> nombreCliente (para cobradores)
  final Map<String, String> tarjetaClientes;

  const ReportePersonalData({
    required this.empleado,
    required this.fechaInicio,
    required this.fechaFin,
    required this.quincena,
    this.ventas = const [],
    this.devoluciones = const [],
    this.cuotasCobradas = const [],
    this.pagosRegistrados = const [],
    this.prestamos = const [],
    this.tarjetaClientes = const {},
  });

  // Totales asesora
  double get totalVentas =>
      ventas.fold(0.0, (s, t) => s + t.totalVenta);
  double get totalIniciales =>
      ventas.fold(0.0, (s, t) => s + t.pagoInicial);
  double get totalDevuelto =>
      devoluciones.fold(0.0, (s, d) => s + d.montoReembolso);

  // Totales cobrador
  double get totalCuotasCobradas =>
      cuotasCobradas.fold(0.0, (s, c) => s + c.monto);
  double get totalPagosRegistrados =>
      pagosRegistrados.fold(0.0, (s, p) => s + p.monto);
  double get totalCobrado => totalCuotasCobradas + totalPagosRegistrados;

  // Común
  double get totalPrestamos =>
      prestamos.fold(0.0, (s, p) => s + p.monto);
}

// ─── Servicio ─────────────────────────────────────────────────────────────────
class ReportePersonalService {
  final _db = FirebaseFirestore.instance;

  Future<ReportePersonalData> cargarReporte({
    required UsuarioModel empleado,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required int quincena,
  }) async {
    final fin = DateTime(
        fechaFin.year, fechaFin.month, fechaFin.day, 23, 59, 59);

    if (empleado.rol == RolUsuario.asesora) {
      return _cargarAsesora(empleado, fechaInicio, fin, quincena);
    } else {
      return _cargarCobrador(empleado, fechaInicio, fin, quincena);
    }
  }

  bool _enRango(DateTime fecha, DateTime inicio, DateTime fin) =>
      !fecha.isBefore(inicio) && !fecha.isAfter(fin);

  Future<ReportePersonalData> _cargarAsesora(
    UsuarioModel empleado,
    DateTime inicio,
    DateTime fin,
    int quincena,
  ) async {
    final results = await Future.wait([
      _db
          .collection('tarjetas')
          .where('asesora_uid', isEqualTo: empleado.uid)
          .get(),
      _db
          .collection('devoluciones')
          .where('asesora_uid', isEqualTo: empleado.uid)
          .get(),
      _db
          .collection('prestamos')
          .where('usuario_uid', isEqualTo: empleado.uid)
          .get(),
    ]);

    final ventas = results[0]
        .docs
        .map((d) => TarjetaModel.fromMap(d.data(), d.id))
        .where((t) => _enRango(t.fechaVenta, inicio, fin))
        .toList()
      ..sort((a, b) => a.fechaVenta.compareTo(b.fechaVenta));

    final devoluciones = results[1]
        .docs
        .map((d) => DevolucionModel.fromMap(d.data(), d.id))
        .where((d) => _enRango(d.fechaDevolucion, inicio, fin))
        .toList()
      ..sort((a, b) => a.fechaDevolucion.compareTo(b.fechaDevolucion));

    final prestamos = results[2]
        .docs
        .map((d) => PrestamoModel.fromMap(d.data(), d.id))
        .where((p) => _enRango(p.fechaSolicitud, inicio, fin))
        .toList()
      ..sort((a, b) => a.fechaSolicitud.compareTo(b.fechaSolicitud));

    return ReportePersonalData(
      empleado: empleado,
      fechaInicio: inicio,
      fechaFin: fin,
      quincena: quincena,
      ventas: ventas,
      devoluciones: devoluciones,
      prestamos: prestamos,
    );
  }

  Future<ReportePersonalData> _cargarCobrador(
    UsuarioModel empleado,
    DateTime inicio,
    DateTime fin,
    int quincena,
  ) async {
    final results = await Future.wait([
      _db
          .collection('cuotas')
          .where('cobrador_uid', isEqualTo: empleado.uid)
          .where('estado', isEqualTo: EstadoCuota.cobrada.name)
          .get(),
      _db
          .collection('pagos_registrados')
          .where('cobrador_uid', isEqualTo: empleado.uid)
          .get(),
      _db
          .collection('prestamos')
          .where('usuario_uid', isEqualTo: empleado.uid)
          .get(),
    ]);

    final cuotas = results[0]
        .docs
        .map((d) => CuotaModel.fromMap(d.data(), d.id))
        .where((c) =>
            c.fechaCobro != null && _enRango(c.fechaCobro!, inicio, fin))
        .toList()
      ..sort((a, b) => a.fechaCobro!.compareTo(b.fechaCobro!));

    final pagos = results[1].docs.map((d) {
      final data = d.data();
      final ts = data['fecha'];
      final fecha =
          ts != null ? (ts as Timestamp).toDate() : DateTime.now();
      return PagoRegistrado(
        tarjetaId: data['tarjeta_id'] as String? ?? '',
        fecha: fecha,
        monto: (data['monto'] as num?)?.toDouble() ?? 0,
        observacion: data['observacion'] as String?,
      );
    }).where((p) => _enRango(p.fecha, inicio, fin)).toList()
      ..sort((a, b) => a.fecha.compareTo(b.fecha));

    final prestamos = results[2]
        .docs
        .map((d) => PrestamoModel.fromMap(d.data(), d.id))
        .where((p) => _enRango(p.fechaSolicitud, inicio, fin))
        .toList()
      ..sort((a, b) => a.fechaSolicitud.compareTo(b.fechaSolicitud));

    // Lookup nombre_cliente por tarjeta_id
    final tarjetaIds = <String>{
      ...cuotas.map((c) => c.tarjetaId),
      ...pagos.map((p) => p.tarjetaId),
    }..remove('');

    final Map<String, String> tarjetaClientes = {};
    if (tarjetaIds.isNotEmpty) {
      final idsList = tarjetaIds.toList();
      for (int i = 0; i < idsList.length; i += 10) {
        final chunk =
            idsList.sublist(i, (i + 10).clamp(0, idsList.length));
        final snap = await _db
            .collection('tarjetas')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (final doc in snap.docs) {
          tarjetaClientes[doc.id] =
              doc.data()['nombre_cliente'] as String? ?? '';
        }
      }
    }

    return ReportePersonalData(
      empleado: empleado,
      fechaInicio: inicio,
      fechaFin: fin,
      quincena: quincena,
      cuotasCobradas: cuotas,
      pagosRegistrados: pagos,
      prestamos: prestamos,
      tarjetaClientes: tarjetaClientes,
    );
  }
}
