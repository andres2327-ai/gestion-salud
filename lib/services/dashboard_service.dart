// lib/services/dashboard_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardStats {
  final double ventasHoy;
  final double montoPendienteTotal;
  final int productosEnStock;
  final int asesorasActivas;
  final int devolucionesHoy;
  final List<Map<String, dynamic>> actividadReciente;

  DashboardStats({
    required this.ventasHoy,
    required this.montoPendienteTotal,
    required this.productosEnStock,
    required this.asesorasActivas,
    required this.devolucionesHoy,
    required this.actividadReciente,
  });
}

class DashboardService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<DashboardStats> obtenerStats() async {
    final ahora = DateTime.now();
    final inicioHoy = DateTime(ahora.year, ahora.month, ahora.day);
    final finHoy = inicioHoy.add(const Duration(days: 1));

    // Ventas de hoy
    final ventasHoySnap = await _db
        .collection('tarjetas')
        .where(
          'fecha_venta',
          isGreaterThanOrEqualTo: Timestamp.fromDate(inicioHoy),
        )
        .where('fecha_venta', isLessThan: Timestamp.fromDate(finHoy))
        .get();

    final ventasHoy = ventasHoySnap.docs.fold<double>(
      0,
      (sum, d) => sum + (d['total_venta'] ?? 0).toDouble(),
    );

    // Monto pendiente total
    final pendientesSnap = await _db
        .collection('tarjetas')
        .where('estado', isEqualTo: 'activa')
        .get();

    final montoPendiente = pendientesSnap.docs.fold<double>(
      0,
      (sum, d) => sum + (d['saldo_pendiente'] ?? 0).toDouble(),
    );

    // Cantidad de productos en stock
    final productosSnap = await _db
        .collection('productos')
        .where('activo', isEqualTo: true)
        .get();
    final productosStock = productosSnap.docs.length;

    // Asesoras activas
    final asesorasSnap = await _db
        .collection('usuarios')
        .where('rol', isEqualTo: 'asesora')
        .where('activo', isEqualTo: true)
        .get();

    // Devoluciones hoy
    final devSnap = await _db
        .collection('devoluciones')
        .where(
          'fecha_devolucion',
          isGreaterThanOrEqualTo: Timestamp.fromDate(inicioHoy),
        )
        .where('fecha_devolucion', isLessThan: Timestamp.fromDate(finHoy))
        .get();

    // Actividad reciente (últimas 10 tarjetas)
    final actividadSnap = await _db
        .collection('tarjetas')
        .orderBy('fecha_venta', descending: true)
        .limit(10)
        .get();

    final actividad = actividadSnap.docs.map((d) {
      final data = d.data();
      return {
        'tipo': 'venta',
        'descripcion': 'Venta a ${data['nombre_cliente']}',
        'asesora': data['nombre_asesora'],
        'monto': data['total_venta'],
        'fecha': data['fecha_venta'],
      };
    }).toList();

    return DashboardStats(
      ventasHoy: ventasHoy,
      montoPendienteTotal: montoPendiente,
      productosEnStock: productosStock,
      asesorasActivas: asesorasSnap.docs.length,
      devolucionesHoy: devSnap.docs.length,
      actividadReciente: actividad,
    );
  }

  // Datos para el reporte de ingresos mensual
  Future<Map<String, dynamic>> reporteMensual(int anio, int mes) async {
    final inicio = DateTime(anio, mes, 1);
    final fin = DateTime(anio, mes + 1, 1);

    final snap = await _db
        .collection('tarjetas')
        .where(
          'fecha_venta',
          isGreaterThanOrEqualTo: Timestamp.fromDate(inicio),
        )
        .where('fecha_venta', isLessThan: Timestamp.fromDate(fin))
        .get();

    double totalMes = 0;
    final Map<String, double> porAsesora = {};

    for (final doc in snap.docs) {
      final data = doc.data();
      final monto = (data['total_venta'] ?? 0).toDouble();
      final asesora = data['nombre_asesora'] ?? 'Sin asesora';
      totalMes += monto;
      porAsesora[asesora] = (porAsesora[asesora] ?? 0) + monto;
    }

    return {
      'total': totalMes,
      'num_ventas': snap.docs.length,
      'por_asesora': porAsesora,
    };
  }

  // Reporte de un día específico
  Future<Map<String, dynamic>> reporteDia(DateTime dia) async {
    final inicio = DateTime(dia.year, dia.month, dia.day);
    final fin = inicio.add(const Duration(days: 1));

    final snap = await _db
        .collection('tarjetas')
        .where(
          'fecha_venta',
          isGreaterThanOrEqualTo: Timestamp.fromDate(inicio),
        )
        .where('fecha_venta', isLessThan: Timestamp.fromDate(fin))
        .get();

    final total = snap.docs.fold<double>(
      0,
      (s, d) => s + (d['total_venta'] ?? 0).toDouble(),
    );

    return {'total': total, 'num_ventas': snap.docs.length};
  }

  // Reporte por rango de fechas (para la pantalla de reportes)
  Future<Map<String, dynamic>> reporteRangoFechas(
      DateTime inicio, DateTime fin) async {
    final inicioTimestamp = Timestamp.fromDate(inicio);
    final finTimestamp = Timestamp.fromDate(fin.add(const Duration(days: 1)));

    // Obtener ventas en el rango de fechas
    final ventasSnap = await _db
        .collection('tarjetas')
        .where('fecha_venta', isGreaterThanOrEqualTo: inicioTimestamp)
        .where('fecha_venta', isLessThan: finTimestamp)
        .get();

    double totalVentas = 0;
    final Map<String, double> porAsesora = {};

    for (final doc in ventasSnap.docs) {
      final data = doc.data();
      final monto = (data['total_venta'] ?? 0).toDouble();
      final asesora = data['nombre_asesora'] ?? 'Sin asesora';
      totalVentas += monto;
      porAsesora[asesora] = (porAsesora[asesora] ?? 0) + monto;
    }

    // Obtener cobros en el rango de fechas
    final cobrosSnap = await _db
        .collection('cobros')
        .where('fecha_cobro', isGreaterThanOrEqualTo: inicioTimestamp)
        .where('fecha_cobro', isLessThan: finTimestamp)
        .get();

    double totalCobros = cobrosSnap.docs.fold<double>(
      0,
      (sum, d) => sum + (d['monto'] ?? 0).toDouble(),
    );

    // Obtener saldo pendiente total (tarjetas activas)
    final pendientesSnap = await _db
        .collection('tarjetas')
        .where('estado', isEqualTo: 'activa')
        .get();

    double saldoPendiente = pendientesSnap.docs.fold<double>(
      0,
      (sum, d) => sum + (d['saldo_pendiente'] ?? 0).toDouble(),
    );

    return {
      'total_ventas': totalVentas,
      'num_ventas': ventasSnap.docs.length,
      'total_cobros': totalCobros,
      'saldo_pendiente': saldoPendiente,
      'por_asesora': porAsesora,
    };
  }
}
