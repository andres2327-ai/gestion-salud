import 'package:flutter/material.dart';

class OrderCard extends StatelessWidget {
  final String id;
  final String clienteNombre;
  final double total;
  final int cuotas;
  final double montoCuota;
  final String estado;
  final int productosCount;
  final DateTime fechaPedido;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onMarkAsDelivered;
  final VoidCallback? onCancel;

  const OrderCard({
    Key? key,
    required this.id,
    required this.clienteNombre,
    required this.total,
    required this.cuotas,
    required this.montoCuota,
    required this.estado,
    required this.productosCount,
    required this.fechaPedido,
    this.onTap,
    this.onEdit,
    this.onMarkAsDelivered,
    this.onCancel,
  }) : super(key: key);

  bool get _entregada => estado == 'entregada';
  bool get _cancelada => estado == 'cancelada';

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;

    switch (estado) {
      case 'entregada':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'cancelada':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending_actions;
    }

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Orden #${id.substring(0, 8)}',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          clienteNombre.isNotEmpty
                              ? clienteNombre
                              : 'Cliente desconocido',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      if (!_entregada && !_cancelada)
                        PopupMenuItem(
                          child: const Text('Editar'),
                          onTap: onEdit,
                        ),
                      if (!_entregada && !_cancelada)
                        PopupMenuItem(
                          child: const Text('Marcar como entregada'),
                          onTap: onMarkAsDelivered,
                        ),
                      if (!_entregada && !_cancelada)
                        PopupMenuItem(
                          child: const Text('Cancelar'),
                          onTap: onCancel,
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '\$${total.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$cuotas cuota${cuotas > 1 ? 's' : ''}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '\$${montoCuota.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Chip(
                    label: Text(
                      estado[0].toUpperCase() + estado.substring(1),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    backgroundColor: statusColor,
                    avatar: Icon(statusIcon, color: Colors.white, size: 16),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '$productosCount producto${productosCount > 1 ? 's' : ''}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                'Fecha: ${fechaPedido.toString().split(' ')[0]}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
