import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers.dart';
import '../models/tarjeta_model.dart';
import '../models/usuario_model.dart';

class AdminAsignarTarjetasScreen extends ConsumerStatefulWidget {
  final UsuarioModel cobrador;

  const AdminAsignarTarjetasScreen({super.key, required this.cobrador});

  @override
  ConsumerState<AdminAsignarTarjetasScreen> createState() =>
      _AdminAsignarTarjetasScreenState();
}

class _AdminAsignarTarjetasScreenState
    extends ConsumerState<AdminAsignarTarjetasScreen> {
  late final Stream<List<TarjetaModel>> _tarjetasStream;

  @override
  void initState() {
    super.initState();
    _tarjetasStream =
        ref.read(tarjetaServiceProvider).streamTodasLasTarjetas();
    Future.microtask(() {
      ref
          .read(cobroControllerProvider.notifier)
          .escucharAsignacionesCobrador(widget.cobrador.uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cobroState = ref.watch(cobroControllerProvider);
    final perfil = ref.watch(usuarioActualProvider);
    final fmt = NumberFormat('#,###', 'es_CO');

    final asignadasIds = cobroState.asignaciones
        .where((a) => a.activa)
        .map((a) => a.tarjetaId)
        .toSet();

    return Scaffold(
      backgroundColor: const Color(0xFF0F1123),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1C3A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Asignar Tarjetas',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            Text(
              widget.cobrador.nombre,
              style: const TextStyle(color: Colors.tealAccent, fontSize: 12),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: StreamBuilder<List<TarjetaModel>>(
        stream: _tarjetasStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.tealAccent),
            );
          }

          final tarjetasActivas = (snapshot.data ?? [])
              .where((t) => t.estado == EstadoTarjeta.activa)
              .toList();

          if (tarjetasActivas.isEmpty) {
            return const Center(
              child: Text(
                'No hay tarjetas activas',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tarjetasActivas.length,
            itemBuilder: (_, i) {
              final tarjeta = tarjetasActivas[i];
              final yaAsignada = asignadasIds.contains(tarjeta.tarjetaId);

              return _TarjetaAsignableCard(
                tarjeta: tarjeta,
                fmt: fmt,
                yaAsignada: yaAsignada,
                onAsignar: yaAsignada
                    ? null
                    : () => _asignar(
                          context,
                          tarjeta,
                          perfil?.uid ?? '',
                        ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _asignar(
    BuildContext context,
    TarjetaModel tarjeta,
    String adminUid,
  ) async {
    final ok = await ref
        .read(cobroControllerProvider.notifier)
        .asignarTarjeta(
          cobradorUid: widget.cobrador.uid,
          nombreCobrador: widget.cobrador.nombre,
          tarjetaId: tarjeta.tarjetaId,
          nombreCliente: tarjeta.nombreCliente,
          adminUid: adminUid,
        );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Tarjeta de ${tarjeta.nombreCliente} asignada a ${widget.cobrador.nombre}'
                : 'Error al asignar tarjeta',
          ),
          backgroundColor: ok ? Colors.green : Colors.red,
        ),
      );
    }
  }
}

class _TarjetaAsignableCard extends StatelessWidget {
  final TarjetaModel tarjeta;
  final NumberFormat fmt;
  final bool yaAsignada;
  final VoidCallback? onAsignar;

  const _TarjetaAsignableCard({
    required this.tarjeta,
    required this.fmt,
    required this.yaAsignada,
    this.onAsignar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1C3A),
        borderRadius: BorderRadius.circular(12),
        border: yaAsignada
            ? Border.all(color: Colors.tealAccent.withAlpha(60))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tarjeta.nombreCliente,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Saldo: \$${fmt.format(tarjeta.saldoPendiente)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                if (tarjeta.nombreAsesora.isNotEmpty)
                  Text(
                    'Asesora: ${tarjeta.nombreAsesora}',
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                if (tarjeta.productos.isNotEmpty)
                  Text(
                    tarjeta.productos.map((p) => p.nombreProducto).join(', '),
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          yaAsignada
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.tealAccent.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Asignada',
                    style: TextStyle(color: Colors.tealAccent, fontSize: 12),
                  ),
                )
              : OutlinedButton(
                  onPressed: onAsignar,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.tealAccent,
                    side: const BorderSide(color: Colors.tealAccent),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Asignar', style: TextStyle(fontSize: 12)),
                ),
        ],
      ),
    );
  }
}
