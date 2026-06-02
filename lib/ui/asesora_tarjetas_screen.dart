import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers.dart';
import '../models/tarjeta_model.dart';
import '../core/theme/app_theme.dart';
import 'asesora_nueva_venta_screen.dart';
import 'venta_detalle_screen.dart';

class AsesoraTarjetasScreen extends ConsumerStatefulWidget {
  const AsesoraTarjetasScreen({super.key});

  @override
  ConsumerState<AsesoraTarjetasScreen> createState() =>
      _AsesoraTarjetasScreenState();
}

class _AsesoraTarjetasScreenState
    extends ConsumerState<AsesoraTarjetasScreen> {
  final _searchCtrl = TextEditingController();
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final perfil = ref.read(usuarioActualProvider);
      if (perfil != null) {
        ref
            .read(tarjetaControllerProvider.notifier)
            .cargarTarjetasAsesora(perfil.uid);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final perfil = ref.watch(usuarioActualProvider);
    final tarjetaState = ref.watch(tarjetaControllerProvider);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fmt = NumberFormat('#,###', 'es_CO');

    final tarjetas = tarjetaState.tarjetas
        .where(
          (t) =>
              _busqueda.isEmpty ||
              t.nombreCliente.toLowerCase().contains(
                _busqueda.toLowerCase(),
              ),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Tarjetas')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (perfil == null) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AsesoraNuevaVentaScreen(
                asesoraUid: perfil.uid,
                asesoraNombre: perfil.nombre,
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _busqueda = v),
              decoration: InputDecoration(
                hintText: 'Buscar cliente...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _busqueda.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _busqueda = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: tarjetaState.cargando
                ? const Center(child: CircularProgressIndicator())
                : tarjetas.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkInk100
                                : AppColors.lightInk100,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(
                            Icons.credit_card_outlined,
                            color: cs.onSurfaceVariant,
                            size: 26,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _busqueda.isNotEmpty
                              ? 'Sin resultados para "$_busqueda"'
                              : 'No hay ventas registradas',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: tarjetas.length,
                    itemBuilder: (_, i) => _TarjetaCard(
                      tarjeta: tarjetas[i],
                      fmt: fmt,
                      isDark: isDark,
                      cs: cs,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VentaDetalleScreen(tarjeta: tarjetas[i]),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaCard extends StatelessWidget {
  final TarjetaModel tarjeta;
  final NumberFormat fmt;
  final bool isDark;
  final ColorScheme cs;
  final VoidCallback onTap;

  const _TarjetaCard({
    required this.tarjeta,
    required this.fmt,
    required this.isDark,
    required this.cs,
    required this.onTap,
  });

  (Color, Color, String) get _estadoStyle {
    switch (tarjeta.estado) {
      case EstadoTarjeta.pagada:
        return (
          isDark ? AppColors.darkJade : AppColors.brandJade,
          isDark ? AppColors.darkJade50 : AppColors.lightJade50,
          'Pagada',
        );
      case EstadoTarjeta.vencida:
        return (
          isDark ? AppColors.darkCoral : AppColors.coral,
          isDark ? AppColors.darkCoral50 : AppColors.coral50,
          'Vencida',
        );
      case EstadoTarjeta.atrasada:
        return (
          isDark ? AppColors.darkAmber : AppColors.amber,
          isDark ? AppColors.darkAmber50 : AppColors.amber50,
          'Atrasada',
        );
      case EstadoTarjeta.activa:
        return (
          isDark ? AppColors.darkViolet : AppColors.violet,
          isDark ? AppColors.darkViolet50 : AppColors.violet50,
          tarjeta.saldoPendiente > 0 ? 'Al día' : 'Pagada',
        );
      case EstadoTarjeta.enDevolucion:
        return (
          isDark ? AppColors.darkViolet : AppColors.violet,
          isDark ? AppColors.darkViolet50 : AppColors.violet50,
          'En devolución',
        );
    }
  }

  String get _iniciales {
    final parts = tarjeta.nombreCliente.split(' ');
    return parts.take(2).map((e) => e.isNotEmpty ? e[0] : '').join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final (estadoColor, estadoBg, estadoLabel) = _estadoStyle;
    final violetColor = isDark ? AppColors.darkViolet : AppColors.violet;
    final violetBg = isDark ? AppColors.darkViolet50 : AppColors.violet50;

    return GestureDetector(
      onTap: onTap,
      child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkInk200 : AppColors.lightInk200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 40 : 6),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: violetBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                _iniciales,
                style: TextStyle(
                  color: violetColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tarjeta.nombreCliente,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Deuda: \$${fmt.format(tarjeta.saldoPendiente)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                if (tarjeta.productos.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    tarjeta.productos.map((p) => p.nombreProducto).join(', '),
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: estadoBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    estadoLabel,
                    style: TextStyle(
                      color: estadoColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${fmt.format(tarjeta.totalVenta)}',
                style: TextStyle(
                  color: violetColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${tarjeta.numCuotas} cuotas',
                style: TextStyle(
                  fontSize: 11,
                  color: cs.onSurfaceVariant,
                ),
              ),
              Text(
                tarjeta.frecuenciaPago.name,
                style: TextStyle(
                  fontSize: 11,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }
}
