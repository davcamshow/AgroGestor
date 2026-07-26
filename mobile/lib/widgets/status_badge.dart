import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({required this.status, super.key});

  Color _getColor() {
    return switch (status.toLowerCase()) {
      'activo' || 'activa' => Colors.blue,
      'en revisión' || 'revision' => Colors.amber,
      'archivada' => Colors.grey,
      'crítico' => Colors.red,
      'adecuado' => Colors.green,
      'bajo' => Colors.orange,
      'vendido' => Colors.purple,
      'cuarentena' => Colors.indigo,
      'engorda' => Colors.purple,
      'destete' => Colors.indigo,
      'mantenimiento' => Colors.teal,
      'lactancia' => Colors.pink,
      _ => Colors.grey,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        border: Border.all(color: color.withOpacity(0.6)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: theme.textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
