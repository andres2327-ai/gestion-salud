import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../providers.dart';
import '../controllers/dashboard_controller.dart';
import '../utils/formato_helper.dart';

class ReportesScreen extends ConsumerStatefulWidget {
  const ReportesScreen({super.key});

  @override
  ConsumerState<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends ConsumerState<ReportesScreen> {
  DateTime _fechaInicio = DateTime.now().subtract(const Duration(days: 30));
  DateTime _fechaFin = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Cargar datos iniciales
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatos();
    });
  }

  void _cargarDatos() {
    ref.read(reporteControllerProvider.notifier).cargarRangoFechas(
          _fechaInicio.year,
          _fechaInicio.month,
          _fechaInicio.day,
          _fechaFin.year,
          _fechaFin.month,
          _fechaFin.day,
        );
  }

  @override
  Widget build(BuildContext context) {
    final reporteState = ref.watch(reporteControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1123),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1C3A),
        title: const Text('Reportes', style: TextStyle(color: Colors.white)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.tealAccent),
            onPressed: _cargarDatos,
          ),
        ],
      ),
      body: reporteState.cargando
          ? const Center(
              child: CircularProgressIndicator(color: Colors.tealAccent),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Selector de periodo
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1C3A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Período',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDateSelector(
                                  context,
                                  'Desde',
                                  _fechaInicio,
                                  (date) {
                                    setState(() {
                                      _fechaInicio = date;
                                      _cargarDatos();
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildDateSelector(
                                  context,
                                  'Hasta',
                                  _fechaFin,
                                  (date) {
                                    setState(() {
                                      _fechaFin = date;
                                      _cargarDatos();
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Resumen del período
                    const Text(
                      'Resumen del Período',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    _buildResumenCard(
                      titulo: 'Ventas Totales',
                      valor: FormatoHelper.formatearMontoCompleto(
                          reporteState.totalVentas),
                      icono: Icons.trending_up,
                      color: Colors.green,
                    ),
                    _buildResumenCard(
                      titulo: 'Número de Transacciones',
                      valor: '${reporteState.numVentas}',
                      icono: Icons.receipt_long,
                      color: Colors.blue,
                    ),
                    _buildResumenCard(
                      titulo: 'Cobros Realizados',
                      valor: FormatoHelper.formatearMontoCompleto(
                          reporteState.totalCobros),
                      icono: Icons.attach_money,
                      color: Colors.orange,
                    ),
                    _buildResumenCard(
                      titulo: 'Saldo Pendiente',
                      valor: FormatoHelper.formatearMontoCompleto(
                          reporteState.saldoPendiente),
                      icono: Icons.pending_actions,
                      color: Colors.purple,
                    ),

                    const SizedBox(height: 24),

                    // Distribución por asesora
                    if (reporteState.distribucionAsesoras.isNotEmpty) ...[
                      const Text(
                        'Ventas por Asesora',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._buildDistribucionAsesoras(
                          reporteState.distribucionAsesoras),
                    ],

                    const SizedBox(height: 24),

                    // Botón de exportar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: reporteState.cargando
                            ? null
                            : () => _exportarPDF(context, reporteState),
                        icon: const Icon(Icons.download),
                        label: const Text('Exportar Reporte PDF'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Colors.tealAccent,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDateSelector(
    BuildContext context,
    String label,
    DateTime fecha,
    Function(DateTime) onSelect,
  ) {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: fecha,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: ThemeData.dark().copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: Colors.tealAccent,
                  surface: Color(0xFF1A1C3A),
                ),
              ),
              child: child!,
            );
          },
        );
        if (date != null) {
          onSelect(date);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1123),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.tealAccent.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 10),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd/MM/yyyy').format(fecha),
                  style: const TextStyle(color: Colors.white),
                ),
                const Icon(
                  Icons.calendar_today,
                  color: Colors.tealAccent,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenCard({
    required String titulo,
    required String valor,
    required IconData icono,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1C3A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Text(
                valor,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icono, color: color),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDistribucionAsesoras(Map<String, double> distribucion) {
    // Ordenar por ventas (mayor a menor)
    final sortedEntries = distribucion.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final total = distribucion.values.fold<double>(0, (sum, v) => sum + v);

    return sortedEntries.asMap().entries.map((entry) {
      final index = entry.key;
      final asesora = entry.value;
      final porcentaje = total > 0 ? (asesora.value / total * 100) : 0.0;

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1C3A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.tealAccent.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '#${index + 1}',
                      style: const TextStyle(
                        color: Colors.tealAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    asesora.key,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  FormatoHelper.formatearMonto(asesora.value),
                  style: const TextStyle(
                    color: Colors.tealAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: porcentaje / 100,
                backgroundColor: Colors.grey.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.tealAccent),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${porcentaje.toStringAsFixed(1)}% del total',
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
      );
    }).toList();
  }

  Future<void> _exportarPDF(
      BuildContext context, ReporteState reporteState) async {
    // Mostrar indicador de carga
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📥 Generando PDF...')),
      );
    }

    final pdf = pw.Document();

    // Generar contenido del PDF
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Encabezado
              pw.Center(
                child: pw.Text(
                  'Reporte de Ventas',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'Período: ${DateFormat('dd/MM/yyyy').format(_fechaInicio)} - ${DateFormat('dd/MM/yyyy').format(_fechaFin)}',
                  style: const pw.TextStyle(fontSize: 14),
                ),
              ),
              pw.SizedBox(height: 24),

              // Resumen
              pw.Text(
                'Resumen del Período',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              _buildPDFRow('Ventas Totales',
                  FormatoHelper.formatearMontoCompleto(reporteState.totalVentas)),
              _buildPDFRow('Número de Transacciones',
                  '${reporteState.numVentas}'),
              _buildPDFRow('Cobros Realizados',
                  FormatoHelper.formatearMontoCompleto(reporteState.totalCobros)),
              _buildPDFRow('Saldo Pendiente',
                  FormatoHelper.formatearMontoCompleto(reporteState.saldoPendiente)),
              pw.SizedBox(height: 24),

              // Distribución por asesora
              if (reporteState.distribucionAsesoras.isNotEmpty) ...[
                pw.Text(
                  'Ventas por Asesora',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Table.fromTextArray(
                  headers: ['#', 'Asesora', 'Ventas', 'Porcentaje'],
                  data: _buildPDFTableData(reporteState.distribucionAsesoras),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  cellAlignment: pw.Alignment.centerLeft,
                ),
              ],

              pw.SizedBox(height: 32),

              // Pie de página
              pw.Center(
                child: pw.Text(
                  'Generado el ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Mostrar vista previa para imprimir/guardar
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  pw.Widget _buildPDFRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label),
          pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  List<List<String>> _buildPDFTableData(Map<String, double> distribucion) {
    final total = distribucion.values.fold<double>(0, (sum, v) => sum + v);
    final sortedEntries = distribucion.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.asMap().entries.map((entry) {
      final index = entry.key;
      final asesora = entry.value;
      final porcentaje = total > 0 ? (asesora.value / total * 100) : 0.0;

      return [
        '#${index + 1}',
        asesora.key,
        FormatoHelper.formatearMontoCompleto(asesora.value),
        '${porcentaje.toStringAsFixed(1)}%',
      ];
    }).toList();
  }
}
