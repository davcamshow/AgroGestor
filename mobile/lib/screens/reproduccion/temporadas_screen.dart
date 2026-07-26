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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Temporadas', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: animalesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (animales) {
          final hembras = animales.where((a) => a.sexo == 'H' && a.estado == 'activo').toList();

          final grouped = <String, List<Animal>>{};
          for (var a in hembras) {
            if (a.fechaNacimiento == null) continue;
            final mes = a.fechaNacimiento!.month;
            String temporada;
            if (mes >= 3 && mes <= 5) temporada = 'Primavera';
            else if (mes >= 6 && mes <= 8) temporada = 'Verano';
            else if (mes >= 9 && mes <= 11) temporada = 'Otono';
            else temporada = 'Invierno';
            grouped.putIfAbsent(temporada, () => []).add(a);
          }

          final seasons = [
            _SeasonData('Primavera', Icons.wb_sunny, Colors.orange, 'Mar-May'),
            _SeasonData('Verano', Icons.wb_sunny, Colors.amber, 'Jun-Ago'),
            _SeasonData('Otono', Icons.park, Colors.brown, 'Sep-Nov'),
            _SeasonData('Invierno', Icons.ac_unit, Colors.blue, 'Dic-Feb'),
          ];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: seasons.map((s) => _buildSeasonCard(s, grouped[s.name] ?? [])).toList(),
          );
        },
      ),
    );
  }

  Widget _buildSeasonCard(_SeasonData season, List<Animal> animales) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [AppTheme.softShadow],
        border: Border.all(color: season.color, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showAnimalsModal(season, animales),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: season.color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(season.icon, color: season.color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(season.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text('Meses: ${season.months}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  if (animales.isNotEmpty)
                    Text('${animales.length} hembras activas', style: TextStyle(color: season.color, fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: season.color, borderRadius: BorderRadius.circular(20)),
              child: Text('${animales.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAnimalsModal(_SeasonData season, List<Animal> animales) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (ctx, scrollController) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Icon(season.icon, color: season.color, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      '${season.name} (${animales.length})',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Meses: ${season.months}', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 16),
                if (animales.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(season.icon, size: 48, color: Colors.grey[300]),
                          const SizedBox(height: 8),
                          Text('Sin animales en $season.name', style: TextStyle(color: Colors.grey[500])),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: animales.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final a = animales[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: season.color.withOpacity(0.2),
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(color: season.color, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text('${a.numeroArete} - ${a.nombre ?? 'Sin nombre'}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Raza: ${a.raza ?? 'N/A'} | Edad: ${a.edadDias != null ? '${a.edadDias} días' : 'N/A'}'),
                              if (a.partosCount != null && a.partosCount! > 0)
                                Text('Partos: ${a.partosCount} | Último parto: ${a.fechaUltimoParto != null ? DateFormat('dd/MM/yyyy').format(a.fechaUltimoParto!) : 'N/A'}'),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.pop(ctx);
                            context.push('/animales/${a.id}');
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SeasonData {
  final String name;
  final IconData icon;
  final Color color;
  final String months;

  const _SeasonData(this.name, this.icon, this.color, this.months);
}
