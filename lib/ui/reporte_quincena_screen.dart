// lib/ui/reporte_quincena_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../providers.dart';
import '../models/usuario_model.dart';
import '../models/tarjeta_model.dart';
import '../models/prestamo_model.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_snackbar.dart';
import '../services/reporte_personal_service.dart';
import '../utils/formato_helper.dart';

const _meses = [
  '',
  'Enero',
  'Febrero',
  'Marzo',
  'Abril',
  'Mayo',
  'Junio',
  'Julio',
  'Agosto',
  'Septiembre',
  'Octubre',
  'Noviembre',
  'Diciembre',
];

const _mesesCorto = [
  '',
  'Ene',
  'Feb',
  'Mar',
  'Abr',
  'May',
  'Jun',
  'Jul',
  'Ago',
  'Sep',
  'Oct',
  'Nov',
  'Dic',
];

class ReporteQuincenaScreen extends ConsumerStatefulWidget {
  const ReporteQuincenaScreen({super.key});

  @override
  ConsumerState<ReporteQuincenaScreen> createState() =>
      _ReporteQuincenaScreenState();
}

class _ReporteQuincenaScreenState
    extends ConsumerState<ReporteQuincenaScreen> {
  RolUsuario _rol = RolUsuario.asesora;
  UsuarioModel? _empleado;
  int _mes = DateTime.now().month;
  int _anio = DateTime.now().year;
  int _quincena = DateTime.now().day <= 15 ? 1 : 2;
  bool _cargando = false;
  ReportePersonalData? _datos;

  final _service = ReportePersonalService();
  final _fmt = DateFormat('dd/MM/yyyy');
  final _fmtMonto = NumberFormat('#,###', 'es_CO');

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(usuarioControllerProvider.notifier).cargar(),
    );
  }

  ({DateTime inicio, DateTime fin}) get _rangoQuincena {
    if (_quincena == 1) {
      return (
        inicio: DateTime(_anio, _mes, 1),
        fin: DateTime(_anio, _mes, 15, 23, 59, 59),
      );
    } else {
      return (
        inicio: DateTime(_anio, _mes, 16),
        // día 0 del mes siguiente = último día del mes actual
        fin: DateTime(_anio, _mes + 1, 0, 23, 59, 59),
      );
    }
  }

  String get _labelPeriodo =>
      '${_quincena == 1 ? "1ra" : "2da"} Quincena — ${_meses[_mes]} $_anio';

  Future<void> _generarPDF() async {
    if (_empleado == null) {
      appSnackbar(context, 'Selecciona un empleado', error: true);
      return;
    }
    setState(() {
      _cargando = true;
      _datos = null;
    });
    try {
      final rango = _rangoQuincena;
      final datos = await _service.cargarReporte(
        empleado: _empleado!,
        fechaInicio: rango.inicio,
        fechaFin: rango.fin,
        quincena: _quincena,
      );
      if (!mounted) return;
      setState(() => _datos = datos);
      await _abrirPDF(datos);
    } catch (e) {
      if (mounted) appSnackbar(context, 'Error al generar: $e', error: true);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _abrirPDF(ReportePersonalData datos) async {
    final doc = _construirPDF(datos);
    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  // ─── PDF ──────────────────────────────────────────────────────────────────

  pw.Document _construirPDF(ReportePersonalData d) {
    final doc = pw.Document();
    final esAsesora = d.empleado.rol == RolUsuario.asesora;
    final periodoLabel = _quincena == 1 ? '1ra Quincena' : '2da Quincena';
    final periodoCompleto = '$periodoLabel — ${_meses[_mes]} $_anio';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),
        header: (ctx) => _pdfCabecera(d, periodoCompleto, ctx.pageNumber == 1),
        footer: (ctx) => _pdfPie(ctx),
        build: (ctx) => [
          pw.SizedBox(height: 8),
          if (esAsesora) ..._seccionesAsesora(d),
          if (!esAsesora) ..._seccionesCobrador(d),
          pw.SizedBox(height: 20),
          _bloqueResumen(d, esAsesora),
          pw.SizedBox(height: 28),
          _bloqueFirmas(d.empleado.nombre),
        ],
      ),
    );
    return doc;
  }

  // Cabecera PDF
  pw.Widget _pdfCabecera(
      ReportePersonalData d, String periodo, bool esPrimera) {
    if (!esPrimera) {
      return pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 8),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('QUIERO SALUD',
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 10)),
            pw.Text('${d.empleado.nombre} — $periodo',
                style: const pw.TextStyle(fontSize: 9)),
          ],
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text('QUIERO SALUD',
            style: pw.TextStyle(
                fontSize: 22, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 3),
        pw.Text('REPORTE PERSONAL DE QUINCENA',
            style: pw.TextStyle(
                fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 12),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Empleado',
                      style: const pw.TextStyle(
                          fontSize: 8, color: PdfColors.grey600)),
                  pw.Text(d.empleado.nombre,
                      style: pw.TextStyle(
                          fontSize: 13, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text('Cargo',
                      style: const pw.TextStyle(
                          fontSize: 8, color: PdfColors.grey600)),
                  pw.Text(
                      d.empleado.rol == RolUsuario.asesora
                          ? 'Asesora'
                          : 'Cobrador',
                      style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.Spacer(),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Período',
                      style: const pw.TextStyle(
                          fontSize: 8, color: PdfColors.grey600)),
                  pw.Text(periodo,
                      style: pw.TextStyle(
                          fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text('Fechas',
                      style: const pw.TextStyle(
                          fontSize: 8, color: PdfColors.grey600)),
                  pw.Text(
                    '${_fmt.format(d.fechaInicio)} al ${_fmt.format(d.fechaFin)}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 14),
      ],
    );
  }

  // Pie de página PDF
  pw.Widget _pdfPie(pw.Context ctx) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
            top: pw.BorderSide(color: PdfColors.grey400, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generado el ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500),
          ),
          pw.Text(
            'Página ${ctx.pageNumber} de ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }

  // ─── Secciones asesora ────────────────────────────────────────────────────

  List<pw.Widget> _seccionesAsesora(ReportePersonalData d) => [
        _tituloSeccion('VENTAS REALIZADAS', d.ventas.length),
        if (d.ventas.isEmpty)
          _vacioPh('Sin ventas en este período')
        else
          _tablaVentas(d),
        pw.SizedBox(height: 14),
        _tituloSeccion('DEVOLUCIONES', d.devoluciones.length),
        if (d.devoluciones.isEmpty)
          _vacioPh('Sin devoluciones en este período')
        else
          _tablaDevoluciones(d),
        pw.SizedBox(height: 14),
        _tituloSeccion('PRÉSTAMOS SOLICITADOS', d.prestamos.length),
        if (d.prestamos.isEmpty)
          _vacioPh('Sin préstamos en este período')
        else
          _tablaPrestamos(d),
        pw.SizedBox(height: 14),
      ];

  pw.Widget _tablaVentas(ReportePersonalData d) {
    return pw.Table(
      columnWidths: {
        0: const pw.FixedColumnWidth(56),
        1: const pw.FlexColumnWidth(2.2),
        2: const pw.FixedColumnWidth(75),
        3: const pw.FixedColumnWidth(70),
        4: const pw.FixedColumnWidth(70),
        5: const pw.FixedColumnWidth(58),
      },
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      children: [
        _filaEncabezado([
          'Fecha',
          'Cliente',
          'Total Venta',
          'Pago Inicial',
          'Saldo Fin.',
          'Estado',
        ]),
        ...d.ventas.map(
          (t) => pw.TableRow(children: [
            _celda(_fmt.format(t.fechaVenta)),
            _celda(t.nombreCliente),
            _celda(_fm(t.totalVenta), derecha: true),
            _celda(
                t.pagoInicial > 0 ? _fm(t.pagoInicial) : '—',
                derecha: true),
            _celda(_fm(t.saldoPendiente), derecha: true),
            _celda(_estadoT(t.estado), centro: true),
          ]),
        ),
      ],
    );
  }

  pw.Widget _tablaDevoluciones(ReportePersonalData d) {
    return pw.Table(
      columnWidths: {
        0: const pw.FixedColumnWidth(56),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2.5),
        3: const pw.FixedColumnWidth(40),
        4: const pw.FixedColumnWidth(75),
        5: const pw.FixedColumnWidth(62),
      },
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      children: [
        _filaEncabezado(
            ['Fecha', 'Cliente', 'Producto', 'Cant.', 'Monto Dev.', 'Estado']),
        ...d.devoluciones.map(
          (dev) => pw.TableRow(children: [
            _celda(_fmt.format(dev.fechaDevolucion)),
            _celda(dev.nombreCliente),
            _celda(dev.nombreProducto),
            _celda('${dev.cantidadDevuelta}', centro: true),
            _celda(_fm(dev.montoReembolso), derecha: true),
            _celda(_estadoD(dev.estado), centro: true),
          ]),
        ),
      ],
    );
  }

  // ─── Secciones cobrador ───────────────────────────────────────────────────

  List<pw.Widget> _seccionesCobrador(ReportePersonalData d) => [
        _tituloSeccion('CUOTAS COBRADAS', d.cuotasCobradas.length),
        if (d.cuotasCobradas.isEmpty)
          _vacioPh('Sin cuotas cobradas en este período')
        else
          _tablaCuotas(d),
        pw.SizedBox(height: 14),
        _tituloSeccion('PAGOS LIBRES REGISTRADOS', d.pagosRegistrados.length),
        if (d.pagosRegistrados.isEmpty)
          _vacioPh('Sin pagos libres en este período')
        else
          _tablaPagos(d),
        pw.SizedBox(height: 14),
        _tituloSeccion('PRÉSTAMOS SOLICITADOS', d.prestamos.length),
        if (d.prestamos.isEmpty)
          _vacioPh('Sin préstamos en este período')
        else
          _tablaPrestamos(d),
        pw.SizedBox(height: 14),
      ];

  pw.Widget _tablaCuotas(ReportePersonalData d) {
    return pw.Table(
      columnWidths: {
        0: const pw.FixedColumnWidth(62),
        1: const pw.FlexColumnWidth(2.5),
        2: const pw.FixedColumnWidth(50),
        3: const pw.FixedColumnWidth(82),
        4: const pw.FlexColumnWidth(2),
      },
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      children: [
        _filaEncabezado(
            ['Fecha Cobro', 'Cliente', 'Cuota #', 'Monto', 'Observación']),
        ...d.cuotasCobradas.map(
          (c) => pw.TableRow(children: [
            _celda(_fmt.format(c.fechaCobro!)),
            _celda(d.tarjetaClientes[c.tarjetaId] ?? '—'),
            _celda('${c.numeroCuota}', centro: true),
            _celda(_fm(c.monto), derecha: true),
            _celda(c.observacion ?? '—'),
          ]),
        ),
      ],
    );
  }

  pw.Widget _tablaPagos(ReportePersonalData d) {
    return pw.Table(
      columnWidths: {
        0: const pw.FixedColumnWidth(62),
        1: const pw.FlexColumnWidth(2.5),
        2: const pw.FixedColumnWidth(82),
        3: const pw.FlexColumnWidth(2),
      },
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      children: [
        _filaEncabezado(['Fecha', 'Cliente', 'Monto', 'Observación']),
        ...d.pagosRegistrados.map(
          (p) => pw.TableRow(children: [
            _celda(_fmt.format(p.fecha)),
            _celda(d.tarjetaClientes[p.tarjetaId] ?? '—'),
            _celda(_fm(p.monto), derecha: true),
            _celda(p.observacion ?? '—'),
          ]),
        ),
      ],
    );
  }

  // ─── Tabla préstamos (común) ──────────────────────────────────────────────

  pw.Widget _tablaPrestamos(ReportePersonalData d) {
    return pw.Table(
      columnWidths: {
        0: const pw.FixedColumnWidth(62),
        1: const pw.FixedColumnWidth(82),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FixedColumnWidth(68),
      },
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      children: [
        _filaEncabezado(['Fecha Solic.', 'Monto', 'Motivo', 'Estado']),
        ...d.prestamos.map(
          (p) => pw.TableRow(children: [
            _celda(_fmt.format(p.fechaSolicitud)),
            _celda(_fm(p.monto), derecha: true),
            _celda(p.motivo),
            _celda(_estadoP(p.estado), centro: true),
          ]),
        ),
      ],
    );
  }

  // ─── Resumen ──────────────────────────────────────────────────────────────

  pw.Widget _bloqueResumen(ReportePersonalData d, bool esAsesora) {
    final filas = esAsesora
        ? [
            ('Total ventas realizadas:', _fm(d.totalVentas)),
            ('Total pagos iniciales recibidos:', _fm(d.totalIniciales)),
            ('Total monto devuelto:', _fm(d.totalDevuelto)),
            ('Total préstamos solicitados:', _fm(d.totalPrestamos)),
          ]
        : [
            ('Cuotas cobradas:', _fm(d.totalCuotasCobradas)),
            ('Pagos libres registrados:', _fm(d.totalPagosRegistrados)),
            ('TOTAL COBRADO:', _fm(d.totalCobrado)),
            ('Total préstamos solicitados:', _fm(d.totalPrestamos)),
          ];

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey800, width: 0.8),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        children: [
          pw.Container(
            width: double.infinity,
            padding:
                const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const pw.BoxDecoration(
              color: PdfColors.grey900,
              borderRadius: pw.BorderRadius.only(
                topLeft: pw.Radius.circular(5),
                topRight: pw.Radius.circular(5),
              ),
            ),
            child: pw.Text(
              'RESUMEN DEL PERÍODO',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(12),
            child: pw.Column(
              children: filas.asMap().entries.map((e) {
                final esTotales =
                    !esAsesora && e.key == 2; // "TOTAL COBRADO"
                return pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  decoration: esTotales
                      ? const pw.BoxDecoration(
                          border: pw.Border(
                            top: pw.BorderSide(
                                color: PdfColors.grey300, width: 0.5),
                          ),
                        )
                      : null,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        e.value.$1,
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: esTotales
                              ? pw.FontWeight.bold
                              : pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        e.value.$2,
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Firmas ───────────────────────────────────────────────────────────────

  pw.Widget _bloqueFirmas(String nombreEmpleado) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        children: [
          pw.Center(
            child: pw.Text(
              'FIRMAS DE CONFORMIDAD',
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, fontSize: 10),
            ),
          ),
          pw.SizedBox(height: 38),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              // Firma empleado
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                        height: 0.8, color: PdfColors.grey700),
                    pw.SizedBox(height: 6),
                    pw.Center(
                      child: pw.Text('FIRMA DEL TRABAJADOR',
                          style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text('Nombre:  $nombreEmpleado',
                        style: const pw.TextStyle(fontSize: 9)),
                    pw.SizedBox(height: 5),
                    pw.Text('C.C.:  ___________________________',
                        style: const pw.TextStyle(fontSize: 9)),
                    pw.SizedBox(height: 5),
                    pw.Text('Fecha:  ___________________________',
                        style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ),
              pw.SizedBox(width: 48),
              // Firma admin
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                        height: 0.8, color: PdfColors.grey700),
                    pw.SizedBox(height: 6),
                    pw.Center(
                      child: pw.Text('FIRMA DEL ADMINISTRADOR',
                          style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text('Nombre:  ___________________________',
                        style: const pw.TextStyle(fontSize: 9)),
                    pw.SizedBox(height: 5),
                    pw.Text('C.C.:  ___________________________',
                        style: const pw.TextStyle(fontSize: 9)),
                    pw.SizedBox(height: 5),
                    pw.Text('Fecha:  ___________________________',
                        style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Helpers PDF ──────────────────────────────────────────────────────────

  pw.TableRow _filaEncabezado(List<String> labels) {
    return pw.TableRow(
      decoration:
          const pw.BoxDecoration(color: PdfColors.grey200),
      children: labels
          .map(
            (l) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 5, vertical: 5),
              child: pw.Text(
                l,
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 8),
              ),
            ),
          )
          .toList(),
    );
  }

  pw.Widget _celda(String texto,
      {bool derecha = false, bool centro = false}) {
    return pw.Padding(
      padding:
          const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      child: pw.Align(
        alignment: centro
            ? pw.Alignment.center
            : derecha
                ? pw.Alignment.centerRight
                : pw.Alignment.centerLeft,
        child: pw.Text(texto,
            style: const pw.TextStyle(fontSize: 8)),
      ),
    );
  }

  pw.Widget _tituloSeccion(String titulo, int cantidad) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding:
              const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: const pw.BoxDecoration(
            color: PdfColors.grey800,
            borderRadius:
                pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Text(
            '$titulo  ($cantidad)',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
            ),
          ),
        ),
        pw.SizedBox(height: 6),
      ],
    );
  }

  pw.Widget _vacioPh(String msg) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
          borderRadius:
              const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Center(
          child: pw.Text(
            msg,
            style: const pw.TextStyle(
                fontSize: 8, color: PdfColors.grey500),
          ),
        ),
      ),
    );
  }

  String _fm(double v) => '\$${_fmtMonto.format(v)}';

  String _estadoT(EstadoTarjeta e) => switch (e) {
        EstadoTarjeta.activa => 'Activa',
        EstadoTarjeta.pagada => 'Pagada',
        EstadoTarjeta.vencida => 'Vencida',
        EstadoTarjeta.atrasada => 'Atrasada',
        EstadoTarjeta.enDevolucion => 'Devolución',
      };

  String _estadoD(EstadoDevolucion e) => switch (e) {
        EstadoDevolucion.pendiente => 'Pendiente',
        EstadoDevolucion.aprobada => 'Aprobada',
        EstadoDevolucion.rechazada => 'Rechazada',
      };

  String _estadoP(EstadoPrestamo e) => switch (e) {
        EstadoPrestamo.pendiente => 'Pendiente',
        EstadoPrestamo.aprobado => 'Aprobado',
        EstadoPrestamo.rechazado => 'Rechazado',
      };

  // ─── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final jadeColor = isDark ? AppColors.darkJade : AppColors.brandJade;
    final jadeBg = isDark ? AppColors.darkJade50 : AppColors.lightJade50;
    final violetColor = isDark ? AppColors.darkViolet : AppColors.violet;
    final violetBg = isDark ? AppColors.darkViolet50 : AppColors.violet50;
    final borderColor =
        isDark ? AppColors.darkInk200 : AppColors.lightInk200;

    final asesoras = ref.watch(asesorasProvider);
    final cobradores = ref.watch(cobradoresProvider);
    final empleados =
        _rol == RolUsuario.asesora ? asesoras : cobradores;

    return Scaffold(
      appBar: AppBar(title: const Text('Reporte por Quincena')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Tipo de empleado ────────────────────────────────────────────
          _tarjeta(
            isDark: isDark,
            cs: cs,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _etiqueta('TIPO DE EMPLEADO', cs),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _chipRol(
                        label: 'Asesora',
                        icono: Icons.woman_outlined,
                        rol: RolUsuario.asesora,
                        accentColor: violetColor,
                        accentBg: violetBg,
                        isDark: isDark,
                        cs: cs,
                        borderColor: borderColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _chipRol(
                        label: 'Cobrador',
                        icono: Icons.person_outlined,
                        rol: RolUsuario.cobrador,
                        accentColor: jadeColor,
                        accentBg: jadeBg,
                        isDark: isDark,
                        cs: cs,
                        borderColor: borderColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Empleado ────────────────────────────────────────────────────
          _tarjeta(
            isDark: isDark,
            cs: cs,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _etiqueta('EMPLEADO', cs),
                const SizedBox(height: 12),
                if (empleados.isEmpty)
                  Text(
                    'No hay '
                    '${_rol == RolUsuario.asesora ? "asesoras" : "cobradores"}'
                    ' activos',
                    style: TextStyle(
                        color: cs.onSurfaceVariant, fontSize: 13),
                  )
                else
                  // key fuerza rebuild (y reset a null) cuando cambia _rol
                  DropdownButtonFormField<UsuarioModel>(
                    key: ValueKey(_rol),
                    initialValue: _empleado,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      hintText: 'Seleccionar empleado...',
                      prefixIcon:
                          Icon(Icons.person_outline, size: 20),
                    ),
                    items: empleados
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e.nombre,
                                  overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() {
                      _empleado = v;
                      _datos = null;
                    }),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Período ─────────────────────────────────────────────────────
          _tarjeta(
            isDark: isDark,
            cs: cs,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _etiqueta('PERÍODO', cs),
                const SizedBox(height: 12),

                // Selector de año con flechas
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () => setState(() {
                        _anio--;
                        _datos = null;
                      }),
                      icon: const Icon(Icons.chevron_left),
                      iconSize: 28,
                    ),
                    Text(
                      '$_anio',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    IconButton(
                      onPressed: _anio >= DateTime.now().year
                          ? null
                          : () => setState(() {
                                _anio++;
                                _datos = null;
                              }),
                      icon: const Icon(Icons.chevron_right),
                      iconSize: 28,
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Grid de 12 meses
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.9,
                  children: List.generate(12, (i) {
                    final m = i + 1;
                    final now = DateTime.now();
                    final deshabilitado = _anio == now.year && m > now.month;
                    final sel = _mes == m;
                    return GestureDetector(
                      onTap: deshabilitado
                          ? null
                          : () => setState(() {
                                _mes = m;
                                _datos = null;
                              }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 130),
                        decoration: BoxDecoration(
                          color: sel
                              ? jadeColor
                              : deshabilitado
                                  ? Colors.transparent
                                  : cs.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: sel
                                ? jadeColor
                                : deshabilitado
                                    ? borderColor.withAlpha(80)
                                    : borderColor,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _mesesCorto[m],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: sel
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: sel
                                  ? Colors.white
                                  : deshabilitado
                                      ? cs.onSurface.withAlpha(60)
                                      : cs.onSurface,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 12),

                // Quincena
                Row(
                  children: [
                    Expanded(
                      child: _chipQuincena(
                        q: 1,
                        accentColor: jadeColor,
                        accentBg: jadeBg,
                        isDark: isDark,
                        cs: cs,
                        borderColor: borderColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _chipQuincena(
                        q: 2,
                        accentColor: jadeColor,
                        accentBg: jadeBg,
                        isDark: isDark,
                        cs: cs,
                        borderColor: borderColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                Text(
                  _labelPeriodo,
                  style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                      fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),

          // ── Vista previa de datos ────────────────────────────────────────
          if (_datos != null) ...[
            const SizedBox(height: 16),
            _vistaPrevia(_datos!, isDark, cs, jadeColor, jadeBg),
          ],

          const SizedBox(height: 24),

          // ── Botón generar PDF ────────────────────────────────────────────
          SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _cargando ? null : _generarPDF,
              style: ElevatedButton.styleFrom(
                backgroundColor: jadeColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    jadeColor.withAlpha(120),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              icon: _cargando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white),
                    )
                  : const Icon(Icons.picture_as_pdf_outlined,
                      size: 22),
              label: Text(
                _cargando
                    ? 'Consultando datos...'
                    : 'Generar PDF de Quincena',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─── Widgets UI helpers ───────────────────────────────────────────────────

  Widget _tarjeta(
      {required bool isDark,
      required ColorScheme cs,
      required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: isDark
                ? AppColors.darkInk200
                : AppColors.lightInk200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 40 : 6),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _etiqueta(String texto, ColorScheme cs) {
    return Text(
      texto,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: cs.onSurfaceVariant,
        letterSpacing: 0.06,
      ),
    );
  }

  Widget _chipRol({
    required String label,
    required IconData icono,
    required RolUsuario rol,
    required Color accentColor,
    required Color accentBg,
    required bool isDark,
    required ColorScheme cs,
    required Color borderColor,
  }) {
    final sel = _rol == rol;
    return GestureDetector(
      onTap: () => setState(() {
        _rol = rol;
        _empleado = null;
        _datos = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: sel ? accentBg : cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: sel ? accentColor : borderColor,
            width: sel ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono,
                size: 18,
                color: sel ? accentColor : cs.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: sel ? accentColor : cs.onSurfaceVariant,
                fontWeight:
                    sel ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chipQuincena({
    required int q,
    required Color accentColor,
    required Color accentBg,
    required bool isDark,
    required ColorScheme cs,
    required Color borderColor,
  }) {
    final sel = _quincena == q;
    final label =
        q == 1 ? '1ra Quincena\n(días 1 – 15)' : '2da Quincena\n(días 16 – fin)';
    return GestureDetector(
      onTap: () => setState(() {
        _quincena = q;
        _datos = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: sel ? accentBg : cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: sel ? accentColor : borderColor,
            width: sel ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: sel ? accentColor : cs.onSurfaceVariant,
              fontWeight:
                  sel ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _vistaPrevia(
    ReportePersonalData d,
    bool isDark,
    ColorScheme cs,
    Color accent,
    Color bg,
  ) {
    final esAsesora = d.empleado.rol == RolUsuario.asesora;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_outline,
                  size: 18, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Datos cargados — ${d.empleado.nombre}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: accent,
                      fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (esAsesora) ...[
            _filaPrev('Ventas',
                '${d.ventas.length} · ${FormatoHelper.formatearMontoCompleto(d.totalVentas)}',
                cs),
            _filaPrev('Pagos iniciales',
                FormatoHelper.formatearMontoCompleto(d.totalIniciales),
                cs),
            _filaPrev('Devoluciones',
                '${d.devoluciones.length} · ${FormatoHelper.formatearMontoCompleto(d.totalDevuelto)}',
                cs),
            _filaPrev('Préstamos',
                '${d.prestamos.length} · ${FormatoHelper.formatearMontoCompleto(d.totalPrestamos)}',
                cs),
          ] else ...[
            _filaPrev('Cuotas cobradas',
                '${d.cuotasCobradas.length} · ${FormatoHelper.formatearMontoCompleto(d.totalCuotasCobradas)}',
                cs),
            _filaPrev('Pagos libres',
                '${d.pagosRegistrados.length} · ${FormatoHelper.formatearMontoCompleto(d.totalPagosRegistrados)}',
                cs),
            _filaPrev('Total cobrado',
                FormatoHelper.formatearMontoCompleto(d.totalCobrado),
                cs),
            _filaPrev('Préstamos',
                '${d.prestamos.length} · ${FormatoHelper.formatearMontoCompleto(d.totalPrestamos)}',
                cs),
          ],
        ],
      ),
    );
  }

  Widget _filaPrev(String label, String valor, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13, color: cs.onSurfaceVariant)),
          Text(valor,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
