import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers.dart';
import '../models/tarjeta_model.dart';
import 'asesora_nueva_venta_screen.dart';

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
      backgroundColor: const Color(0xFF0F1123),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1C3A),
        title: const Text(
          'Mis Tarjetas',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.tealAccent,
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
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: Column(
        children: [
          // Buscador
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _busqueda = v),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar cliente...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1A1C3A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Lista
          Expanded(
            child: tarjetaState.cargando
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.tealAccent),
                  )
                : tarjetas.isEmpty
                ? const Center(
                    child: Text(
                      'No hay ventas registradas',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: tarjetas.length,
                    itemBuilder: (_, i) =>
                        _TarjetaCard(tarjeta: tarjetas[i], fmt: fmt),
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

  const _TarjetaCard({required this.tarjeta, required this.fmt});

  Color get _estadoColor {
    switch (tarjeta.estado) {
      case EstadoTarjeta.pagada:
        return Colors.blue;
      case EstadoTarjeta.vencida:
        return Colors.red;
      case EstadoTarjeta.activa:
        return tarjeta.saldoPendiente > 0 ? Colors.orange : Colors.green;
    }
  }

  String get _estadoLabel {
    switch (tarjeta.estado) {
      case EstadoTarjeta.pagada:
        return 'Pagado';
      case EstadoTarjeta.vencida:
        return 'Atrasado';
      case EstadoTarjeta.activa:
        return tarjeta.saldoPendiente > 0 ? 'Al día' : 'Pagado';
    }
  }

  String get _iniciales {
    final parts = tarjeta.nombreCliente.split(' ');
    return parts.take(2).map((e) => e.isNotEmpty ? e[0] : '').join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1C3A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: _estadoColor.withAlpha(60),
            child: Text(
              _iniciales,
              style: TextStyle(
                color: _estadoColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
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
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Deuda: \$${fmt.format(tarjeta.saldoPendiente)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 4),
                if (tarjeta.productos.isNotEmpty)
                  Text(
                    tarjeta.productos.map((p) => p.nombreProducto).join(', '),
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _estadoColor.withAlpha(40),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _estadoLabel,
                    style: TextStyle(
                      color: _estadoColor,
                      fontSize: 12,
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
                style: const TextStyle(
                  color: Colors.tealAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${tarjeta.numCuotas} cuotas',
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
              Text(
                tarjeta.frecuenciaPago.name,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
