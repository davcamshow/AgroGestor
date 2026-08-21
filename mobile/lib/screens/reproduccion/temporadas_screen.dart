import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/models/animal.dart';
import '../../core/providers/animales_provider.dart';
import '../../core/theme/app_theme.dart';

class TemporadasScreen extends ConsumerStatefulWidget {
  const TemporadasScreen({super.key});

  @override
  ConsumerState<TemporadasScreen> createState() => _TemporadasScreenState();
}

class _TemporadasScreenState extends ConsumerState<TemporadasScreen> {
  @override
  Widget build(BuildContext context) {
    final animalesAsync = ref.watch(animalesNotifierProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Temporadas',
            style: TextStyle(color: Colors.white)),
        backgroundColor:
            isDark ? theme.appBarTheme.backgroundColor : AppTheme.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: animalesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (animales) {
          final hembra = animales
              .where((a) => a.sexo == 'M' && a.estado == 'activo')
              .toList();

          final grouped = <String, List>{};
          for (var a in hembra) {
            if (a.fechaNacimiento == null) continue;
            final mes = a.fechaNacimiento!.month;
            String temporada;
            if (mes >= 9 && mes <= 11) {
              temporada = 'Primavera';
            } else if (mes == 12 || mes <= 2) {
              temporada = 'Verano';
            } else if (mes >= 3 && mes <= 5) {
              temporada = 'Otono';
            } else {
              temporada = 'Invierno';
            }
            grouped.putIfAbsent(temporada, () => []).add(a);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildCard('Primavera', Icons.wb_sunny, Colors.orange,
                  grouped['Primavera']?.length ?? 0, 'Sept-Nov'),
              _buildCard('Verano', Icons.wb_sunny, Colors.amber,
                  grouped['Verano']?.length ?? 0, 'Dic-Feb'),
              _buildCard('Otono', Icons.park, Colors.brown,
                  grouped['Otono']?.length ?? 0, 'Mar-May'),
              _buildCard('Invierno', Icons.ac_unit, Colors.blue,
                  grouped['Invierno']?.length ?? 0, 'Jun-Ago'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCard(
      String nombre, IconData icono, Color color, int cantidad, String meses) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [AppTheme.softShadowFor(theme.brightness)],
        border: Border.all(color: color, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // TODO: Implementar la acción al tocar la tarjeta
          // _showAnimalsModal(nombre, animales);
        },
        // Se ha movido el padding adentro del InkWell para que la animación de toque ("ripple")
        // cubra toda la tarjeta correctamente.
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icono, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'Meses: $meses',
                      style: TextStyle(
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$cantidad',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
