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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: colorScheme.primary),
            onPressed: _cargarDatos,
          ),
        ],
      ),
      body: reporteState.cargando
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
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
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Período', style: textTheme.bodySmall),
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

                    Text(
                      'Resumen del Período',
                      style: textTheme.titleLarge,
                    ),

                    const SizedBox(height: 16),

                    _buildResumenCard(
                      context,
                      titulo: 'Ventas Totales',
                      valor: FormatoHelper.formatearMontoCompleto(
                          reporteState.totalVentas),
                      icono: Icons.trending_up,
                      color: Colors.green,
                    ),
                    _buildResumenCard(
                      context,
                      titulo: 'Número de Transacciones',
                      valor: '${reporteState.numVentas}',
                      icono: Icons.receipt_long,
                      color: Colors.blue,
                    ),
                    _buildResumenCard(
                      context,
                      titulo: 'Cobros Realizados',
                      valor: FormatoHelper.formatearMontoCompleto(
                          reporteState.totalCobros),
                      icono: Icons.attach_money,
                      color: Colors.orange,
                    ),
                    _buildResumenCard(
                      context,
                      titulo: 'Saldo Pendiente',
                      valor: FormatoHelper.formatearMontoCompleto(
                          reporteState.saldoPendiente),
                      icono: Icons.pending_actions,
                      color: Colors.purple,
                    ),

                    const SizedBox(height: 24),

                    if (reporteState.distribucionAsesoras.isNotEmpty) ...[
                      Text('Ventas por Asesora', style: textTheme.titleLarge),
                      const SizedBox(height: 16),
                      ..._buildDistribucionAsesoras(
                          context, reporteState.distribucionAsesoras),
                    ],

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: reporteState.cargando
                            ? null
                            : () => _exportarPDF(context, reporteState),
                        icon: const Icon(Icons.download),
                        label: const Text('Exportar Reporte PDF'),
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: fecha,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          onSelect(date);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: textTheme.bodySmall),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd/MM/yyyy').format(fecha),
                  style: textTheme.bodyMedium,
                ),
                Icon(
                  Icons.calendar_today,
                  color: colorScheme.primary,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenCard(
    BuildContext context, {
    required String titulo,
    required String valor,
    required IconData icono,
    required Color color,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final cardColor =
        Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: textTheme.bodySmall),
              const SizedBox(height: 8),
              Text(
                valor,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icono, color: color),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDistribucionAsesoras(
    BuildContext context,
    Map<String, double> distribucion,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final cardColor =
        Theme.of(context).cardTheme.color ?? colorScheme.surface;

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
          color: cardColor,
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
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '#${index + 1}',
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
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
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  FormatoHelper.formatearMonto(asesora.value),
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
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
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor:
                    AlwaysStoppedAnimation<Color>(colorScheme.primary),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${porcentaje.toStringAsFixed(1)}% del total',
              style: textTheme.bodySmall,
            ),
          ],
        ),
      );
    }).toList();
  }

  Future<void> _exportarPDF(
      BuildContext context, ReporteState reporteState) async {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generando PDF...')),
      );
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
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
              pw.Text(
                'Resumen del Período',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              _buildPDFRow(
                  'Ventas Totales',
                  FormatoHelper.formatearMontoCompleto(
                      reporteState.totalVentas)),
              _buildPDFRow(
                  'Número de Transacciones', '${reporteState.numVentas}'),
              _buildPDFRow(
                  'Cobros Realizados',
                  FormatoHelper.formatearMontoCompleto(
                      reporteState.totalCobros)),
              _buildPDFRow(
                  'Saldo Pendiente',
                  FormatoHelper.formatearMontoCompleto(
                      reporteState.saldoPendiente)),
              pw.SizedBox(height: 24),
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
                  data:
                      _buildPDFTableData(reporteState.distribucionAsesoras),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  cellAlignment: pw.Alignment.centerLeft,
                ),
              ],
              pw.SizedBox(height: 32),
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
