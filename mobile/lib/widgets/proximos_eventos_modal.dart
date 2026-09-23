import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'blur_bottom_sheet.dart';

void mostrarBottomSheetEventosProximos(
  BuildContext context, {
  required List<dynamic>
      eventos, // Pasa aquí tu lista de eventos (ej: List<EventoModel>)
}) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  showBlurBottomSheet(
    context: context,
    maxHeight: MediaQuery.sizeOf(context).height * 0.75,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabecera
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 8, 0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.info.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.event_available_rounded,
                  color: AppTheme.info,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Próximos Eventos',
                  style: theme.textTheme.titleLarge,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Divider(height: 24),
        ),

        // Lista dinámica o estado vacío
        Flexible(
          child: eventos.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_busy_rounded,
                          size: 48,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No hay eventos próximos programados',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: eventos.length,
                  itemBuilder: (context, index) {
                    final evento = eventos[index];

                    // Mapea los campos de tu modelo/mapa:
                    final titulo = evento.titulo ??
                        evento['titulo'] ??
                        'Evento sin título';
                    final fecha = evento.fecha ?? evento['fecha'] ?? '';
                    final tipo = evento.tipo ?? evento['tipo'] ?? 'General';

                    return _buildEventoItem(
                      context,
                      titulo: titulo.toString(),
                      fecha: fecha.toString(),
                      tipo: tipo.toString(),
                    );
                  },
                ),
        ),
      ],
    ),
  );
}

Widget _buildEventoItem(
  BuildContext context, {
  required String titulo,
  required String fecha,
  required String tipo,
}) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  // Asigna icono y color según el tipo de evento
  final (IconData icono, Color color) = switch (tipo.toLowerCase()) {
    'sanitario' || 'salud' || 'vacuna' => (
        Icons.medical_services_outlined,
        Colors.teal
      ),
    'reproduccion' || 'parto' || 'celo' => (
        Icons.pets_rounded,
        Colors.purpleAccent
      ),
    'alimentacion' || 'dieta' => (Icons.grass_rounded, Colors.orange),
    _ => (Icons.calendar_today_rounded, theme.colorScheme.primary),
  };

  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.03),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.04),
      ),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icono, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              if (fecha.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        fecha,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            tipo,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    ),
  );
}
