import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/models/animal.dart';
import '../../core/models/evento_sanitario.dart';
import '../../core/models/registro_peso.dart';
import '../../core/providers/animales_provider.dart';
import '../../core/providers/eventos_sanitarios_provider.dart';
import '../../core/providers/registros_peso_provider.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import 'animal_form_sheet.dart';
import 'mover_lote_sheet.dart';
import 'agregar_registro_sheet.dart';
import 'animal_baja_sheet.dart'; // Importa el nuevo sheet

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------
final auditoriaAnimalProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>((ref, animalId) async {
  final client = ref.read(apiClientProvider);
  final response = await client.dio.get('animales/$animalId/auditoria/');
  return (response.data as List).cast<Map<String, dynamic>>();
});

final eventosSanitariosAnimalProvider = FutureProvider.autoDispose
    .family<List<EventoSanitario>, int>((ref, animalId) async {
  final eventos = await ref.watch(eventosSanitariosNotifierProvider.future);
  return eventos.where((e) => e.animalId == animalId).toList();
});

// ---------------------------------------------------------------------------
// Calendar event model
// ---------------------------------------------------------------------------
class _CalendarEvent {
  final String title;
  final String type;
  final bool isProxima;

  _CalendarEvent({
    required this.title,
    required this.type,
    this.isProxima = false,
  });
}

// ---------------------------------------------------------------------------
// Pantalla principal
// ---------------------------------------------------------------------------
class AnimalDetailScreen extends ConsumerStatefulWidget {
  final String animalId;

  const AnimalDetailScreen({super.key, required this.animalId});

  @override
  ConsumerState<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends ConsumerState<AnimalDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animalesAsync = ref.watch(animalesNotifierProvider);
    final theme = Theme.of(context);

    return animalesAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
            child: Text('Error: $err', style: theme.textTheme.bodyMedium)),
      ),
      data: (animales) {
        final animal = animales
            .where((a) => a.id.toString() == widget.animalId)
            .firstOrNull;

        if (animal == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Animal no encontrado')),
            body: Center(
              child: Text('Animal no encontrado',
                  style: theme.textTheme.bodyMedium),
            ),
          );
        }

        final esActivo = animal.estado == 'activo';

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            title: Text(animal.nombre ?? animal.numeroArete),
            actions: [
              if (esActivo)
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Editar',
                  onPressed: () => _showEditSheet(context, animal),
                ),
              if (esActivo)
                IconButton(
                  icon: const Icon(Icons.compare_arrows),
                  tooltip: 'Mover de lote',
                  color: Colors.white,
                  onPressed: () => _showMoverLoteSheet(context, animal),
                ),
              if (esActivo)
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  tooltip: 'Dar de baja',
                  color: AppTheme.error,
                  onPressed: () =>
                      _showBajaSheet(context, animal), // Llama al nuevo sheet
                ),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withOpacity(0.6),
              indicatorColor: Colors.white,
              tabs: const [
                Tab(text: 'Info'),
                Tab(text: 'Genealogía'),
                Tab(text: 'Auditoría'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildInfoTab(animal, theme),
              _buildGenealogiaTab(animal, theme),
              _AuditoriaTab(animalId: animal.id),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Tab Info
  // ---------------------------------------------------------------------------
  Widget _buildInfoTab(Animal animal, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildHeader(animal, theme).animate().fadeIn().slideY(begin: -0.2),
          const SizedBox(height: 24),
          if (animal.estado != 'activo') ...[
            _buildBajaCard(animal, theme)
                .animate()
                .fadeIn(delay: 150.ms)
                .slideX(),
            const SizedBox(height: 16),
          ],
          _buildInfoCard(animal, theme)
              .animate()
              .fadeIn(delay: 200.ms)
              .slideX(),
          const SizedBox(height: 16),
          _buildRegistrosCard(animal, theme)
              .animate()
              .fadeIn(delay: 300.ms)
              .slideX(),
          const SizedBox(height: 24),
          _buildEventsCalendar(animal, theme)
              .animate()
              .fadeIn(delay: 400.ms)
              .slideY(begin: 0.2),
          const SizedBox(height: 16),
          _buildRegistrationButtons(animal)
              .animate()
              .fadeIn(delay: 500.ms)
              .slideY(begin: 0.2),
          const SizedBox(height: 16),
          _buildRecentEvents(animal, theme)
              .animate()
              .fadeIn(delay: 600.ms)
              .slideY(begin: 0.2),
        ],
      ),
    );
  }

  Widget _buildBajaCard(Animal animal, ThemeData theme) {
    final auditoriaAsync = ref.watch(auditoriaAnimalProvider(animal.id));

    return auditoriaAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
      data: (registros) {
        final notasBaja =
            registros.where((r) => r['campo'] == 'notas_baja').toList();

        notasBaja.sort((a, b) => (a['fecha_cambio'] as String)
            .compareTo(b['fecha_cambio'] as String));
        final ultimoRegistro = notasBaja.lastOrNull;

        if (ultimoRegistro == null) return const SizedBox.shrink();

        final valorNuevo =
            ultimoRegistro['valor_nuevo'] as String? ?? 'Sin detalles de baja';

        return _Card(
          title: 'Detalles de Baja',
          icon: Icons.info,
          theme: theme,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Descripción y Fecha:', style: theme.textTheme.bodySmall),
              const SizedBox(height: 4),
              Text(
                valorNuevo,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Calendario de eventos
  // ---------------------------------------------------------------------------
  Widget _buildEventsCalendar(Animal animal, ThemeData theme) {
    final eventosAsync = ref.watch(eventosSanitariosAnimalProvider(animal.id));
    final pesosAsync = ref.watch(registrosPesoAnimalProvider(animal.id));

    return eventosAsync.when(
      loading: () => const SizedBox(),
      error: (err, _) =>
          Center(child: Text('Error: $err', style: theme.textTheme.bodyMedium)),
      data: (eventos) => pesosAsync.when(
        loading: () => const SizedBox(),
        error: (err, _) => Center(
            child: Text('Error: $err', style: theme.textTheme.bodyMedium)),
        data: (pesos) => _Card(
          title: 'Calendario de Eventos',
          icon: Icons.calendar_month,
          theme: theme,
          child: Column(
            children: [
              TableCalendar<_CalendarEvent>(
                firstDay: DateTime(2020),
                lastDay: DateTime(2030),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  setState(() => _calendarFormat = format);
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                onHeaderLongPressed: (focusedDay) =>
                    _showYearPickerDialog(focusedDay, theme),
                eventLoader: (day) => _getEventsForDay(day, eventos, pesos),
                headerStyle: HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                  formatButtonTextStyle:
                      TextStyle(color: theme.colorScheme.primary),
                  headerMargin: const EdgeInsets.only(bottom: 8),
                  leftChevronIcon: Icon(Icons.chevron_left,
                      color: theme.colorScheme.primary),
                  rightChevronIcon: Icon(Icons.chevron_right,
                      color: theme.colorScheme.primary),
                ),
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: const BoxDecoration(
                    color: AppTheme.info,
                    shape: BoxShape.circle,
                  ),
                  defaultTextStyle:
                      TextStyle(color: theme.textTheme.bodyMedium?.color),
                  weekendTextStyle:
                      TextStyle(color: theme.textTheme.bodyMedium?.color),
                  outsideTextStyle:
                      TextStyle(color: theme.textTheme.bodySmall?.color),
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    if (events.isEmpty) return null;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: events.map((e) {
                        final color = e.isProxima
                            ? AppTheme.warning
                            : _eventTypeColor(e.type);
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
              if (_selectedDay != null) ...[
                Divider(height: 24, color: theme.dividerColor),
                _buildDayEvents(_selectedDay!, eventos, pesos, theme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<_CalendarEvent> _getEventsForDay(
    DateTime day,
    List<EventoSanitario> eventos,
    List<RegistroPeso> pesos,
  ) {
    final events = <_CalendarEvent>[];
    for (final e in eventos) {
      if (isSameDay(e.fechaAplicacion, day)) {
        events.add(_CalendarEvent(
          title: _eventTypeLabel(e.tipo),
          type: e.tipo,
        ));
      }
      if (e.proximaAplicacion != null && isSameDay(e.proximaAplicacion!, day)) {
        events.add(_CalendarEvent(
          title: 'Próxima: ${_eventTypeLabel(e.tipo)}',
          type: e.tipo,
          isProxima: true,
        ));
      }
    }
    for (final p in pesos) {
      if (isSameDay(p.fechaPesaje, day)) {
        events.add(_CalendarEvent(
          title: 'Pesaje: ${p.pesoKg} kg',
          type: 'pesaje',
        ));
      }
    }
    return events;
  }

  Widget _buildDayEvents(
    DateTime day,
    List<EventoSanitario> eventos,
    List<RegistroPeso> pesos,
    ThemeData theme,
  ) {
    final dayEvents = _getEventsForDay(day, eventos, pesos);
    if (dayEvents.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Sin eventos en esta fecha',
          style: theme.textTheme.bodySmall,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Eventos del ${day.day}/${day.month}/${day.year}',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        ...dayEvents.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: e.isProxima
                          ? AppTheme.warning
                          : _eventTypeColor(e.type),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    e.title,
                    style: TextStyle(
                      fontSize: 12,
                      color: e.isProxima
                          ? AppTheme.warning
                          : theme.textTheme.bodyMedium?.color,
                      fontWeight:
                          e.isProxima ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  void _showYearPickerDialog(DateTime focusedDay, ThemeData theme) {
    showDialog(
      context: context,
      builder: (ctx) {
        int selectedYear = focusedDay.year;
        int selectedMonth = focusedDay.month;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => setDialogState(() => selectedYear--),
                ),
                Text('$selectedYear'),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => setDialogState(() => selectedYear++),
                ),
              ],
            ),
            content: SizedBox(
              width: 300,
              height: 300,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: 12,
                itemBuilder: (ctx, index) {
                  final month = index + 1;
                  final isSelected = selectedYear == focusedDay.year &&
                      month == focusedDay.month;
                  final isCurrent =
                      month == selectedMonth && selectedYear == focusedDay.year;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _focusedDay = DateTime(selectedYear, month);
                      });
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : isCurrent
                                ? theme.colorScheme.primary.withOpacity(0.1)
                                : null,
                        borderRadius: BorderRadius.circular(8),
                        border: isCurrent
                            ? Border.all(color: theme.colorScheme.primary)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          _monthName(month),
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : theme.textTheme.bodyMedium?.color,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Botones de registro (peso y eventos)
  // ---------------------------------------------------------------------------
  Widget _buildRegistrationButtons(Animal animal) {
    if (animal.estado != 'activo') return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.scale,
            label: 'Registrar Peso',
            color: AppTheme.secondary,
            onTap: () => _openRegistroSheet(animal, 0),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.medication,
            label: 'Registrar Evento',
            color: AppTheme.info,
            onTap: () => _openRegistroSheet(animal, 1),
          ),
        ),
      ],
    );
  }

  void _openRegistroSheet(Animal animal, int tabIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AgregarRegistroSheet(
        animalId: animal.id,
        animalArete: animal.numeroArete,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Últimos eventos del animal
  // ---------------------------------------------------------------------------
  Widget _buildRecentEvents(Animal animal, ThemeData theme) {
    final eventosAsync = ref.watch(eventosSanitariosAnimalProvider(animal.id));
    final pesosAsync = ref.watch(registrosPesoAnimalProvider(animal.id));

    return eventosAsync.when(
      loading: () => const SizedBox(),
      error: (err, _) =>
          Center(child: Text('Error: $err', style: theme.textTheme.bodyMedium)),
      data: (eventos) => pesosAsync.when(
        loading: () => const SizedBox(),
        error: (err, _) => Center(
            child: Text('Error: $err', style: theme.textTheme.bodyMedium)),
        data: (pesos) {
          final items = <_RecentItem>[
            ...eventos.map((e) => _RecentItem(
                  date: e.fechaAplicacion,
                  title: '${_eventTypeLabel(e.tipo)}: ${e.producto}',
                  type: e.tipo,
                )),
            ...pesos.map((p) => _RecentItem(
                  date: p.fechaPesaje,
                  title: 'Pesaje: ${p.pesoKg} kg',
                  type: 'pesaje',
                )),
          ]..sort((a, b) => b.date.compareTo(a.date));

          final ultimos = items.take(5).toList();

          return _Card(
            title: 'Últimos Registros',
            icon: Icons.history,
            theme: theme,
            child: ultimos.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'Sin registros',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  )
                : Column(
                    children: ultimos.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _eventTypeColor(item.type),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item.title,
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(fontSize: 13),
                              ),
                            ),
                            Text(
                              DateFormat('dd/MM/yy').format(item.date),
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab Genealogía - Árbol genealógico
  // ---------------------------------------------------------------------------
  Widget _buildGenealogiaTab(Animal animal, ThemeData theme) {
    final animalesAsync = ref.watch(animalesNotifierProvider);

    return animalesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) =>
          Center(child: Text('Error: $err', style: theme.textTheme.bodyMedium)),
      data: (animales) {
        final madre = animal.madreId != null
            ? animales.where((a) => a.id == animal.madreId).firstOrNull
            : null;
        final padre = animal.padreId != null
            ? animales.where((a) => a.id == animal.padreId).firstOrNull
            : null;
        final hermanos = animales
            .where((a) =>
                a.id != animal.id &&
                (animal.madreId != null && a.madreId == animal.madreId ||
                    animal.padreId != null && a.padreId == animal.padreId))
            .toList();
        final hijos = animales
            .where((a) => a.madreId == animal.id || a.padreId == animal.id)
            .toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // --- Padres ---
              Row(
                children: [
                  Expanded(
                    child: _buildTreeParentCard(
                      animal: madre,
                      esMadre: true,
                      label: 'Madre',
                      animalId: animal.id,
                      theme: theme,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTreeParentCard(
                      animal: padre,
                      esMadre: false,
                      label: 'Padre',
                      animalId: animal.id,
                      theme: theme,
                    ),
                  ),
                ],
              ).animate().fadeIn().slideY(begin: -0.2),

              // --- Conector ---
              _buildConnector(theme),
              const SizedBox(height: 8),

              // --- Animal actual ---
              GestureDetector(
                onTap: () => _mostrarInfoAnimal(animal, animales, theme),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradientFor(theme.brightness),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [AppTheme.softShadowFor(theme.brightness)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.pets, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        animal.numeroArete,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- Hermanos ---
              if (hermanos.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildFamilySection('Hermanos', hermanos, animales, theme),
              ],

              // --- Hijos ---
              if (hijos.isNotEmpty) ...[
                const SizedBox(height: 20),
                _buildFamilySection('Hijos', hijos, animales, theme),
              ],

              if (hermanos.isEmpty &&
                  hijos.isEmpty &&
                  madre == null &&
                  padre == null)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Column(
                    children: [
                      Icon(Icons.family_restroom,
                          size: 64, color: theme.textTheme.bodySmall?.color),
                      const SizedBox(height: 12),
                      Text(
                        'Sin familia registrada',
                        style:
                            theme.textTheme.bodyMedium?.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Asigna madre y padre desde arriba',
                        style:
                            theme.textTheme.bodySmall?.copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConnector(ThemeData theme) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: 2,
            height: 24,
            color: theme.colorScheme.primary.withOpacity(0.3),
          ),
        ),
        Center(
          child: Container(
            width: 60,
            height: 2,
            color: theme.colorScheme.primary.withOpacity(0.3),
          ),
        ),
        Center(
          child: Container(
            width: 2,
            height: 16,
            color: theme.colorScheme.primary.withOpacity(0.3),
          ),
        ),
      ],
    );
  }

  Widget _buildTreeParentCard({
    required Animal? animal,
    required bool esMadre,
    required String label,
    required int animalId,
    required ThemeData theme,
  }) {
    final color = esMadre ? Colors.pink : Colors.blue;
    final icon = esMadre ? Icons.female : Icons.male;

    return GestureDetector(
      onTap: () {
        if (animal != null) {
          _mostrarInfoAnimal(animal, null, theme);
        } else {
          _seleccionarPadre(context, esMadre, animalId);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [AppTheme.softShadowFor(theme.brightness)],
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withOpacity(0.15),
              child: animal != null
                  ? Text(
                      animal.numeroArete[0].toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    )
                  : Icon(icon, color: color.withOpacity(0.4), size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              animal?.numeroArete ?? 'Sin asignar',
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    animal != null ? FontWeight.w600 : FontWeight.normal,
                color: animal != null
                    ? theme.textTheme.bodyMedium?.color
                    : theme.textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
            ),
            if (animal != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  animal.nombre ?? '',
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilySection(String title, List<Animal> miembros,
      List<Animal> todos, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 2,
            height: 20,
            color: theme.colorScheme.primary.withOpacity(0.3),
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: miembros.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final m = miembros[index];
              final esMacho = m.sexo == 'M';
              return GestureDetector(
                onTap: () => _mostrarInfoAnimal(m, todos, theme),
                child: Container(
                  width: 90,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: esMacho
                          ? Colors.blue.withOpacity(0.3)
                          : Colors.pink.withOpacity(0.3),
                    ),
                    boxShadow: [AppTheme.softShadowFor(theme.brightness)],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: (esMacho ? Colors.blue : Colors.pink)
                            .withOpacity(0.15),
                        child: Icon(
                          esMacho ? Icons.male : Icons.female,
                          size: 18,
                          color: esMacho ? Colors.blue : Colors.pink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        m.numeroArete,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (m.nombre != null)
                        Text(
                          m.nombre!,
                          style:
                              theme.textTheme.bodySmall?.copyWith(fontSize: 9),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _mostrarInfoAnimal(Animal animal, List<Animal>? todos, ThemeData theme) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
              child: Text(
                animal.numeroArete[0].toUpperCase(),
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                animal.nombre ?? animal.numeroArete,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Arete', animal.numeroArete, theme),
            _infoRow('Nombre', animal.nombre ?? 'Sin nombre', theme),
            _infoRow('Sexo', animal.sexo == 'M' ? 'Macho' : 'Hembra', theme),
            _infoRow('Raza', animal.raza ?? 'No especificada', theme),
            _infoRow('Color', animal.color ?? 'No especificado', theme),
            _infoRow(
                'Fecha Nac.',
                animal.fechaNacimiento?.toString().split(' ')[0] ?? 'N/A',
                theme),
            _infoRow('Estado', animal.estado, theme),
            if (todos != null) ...[
              if (animal.madreId != null)
                _infoRow(
                  'Madre',
                  todos
                          .where((a) => a.id == animal.madreId)
                          .firstOrNull
                          ?.numeroArete ??
                      '#${animal.madreId}',
                  theme,
                ),
              if (animal.padreId != null)
                _infoRow(
                  'Padre',
                  todos
                          .where((a) => a.id == animal.padreId)
                          .firstOrNull
                          ?.numeroArete ??
                      '#${animal.padreId}',
                  theme,
                ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodySmall?.copyWith(fontSize: 13)),
          Text(value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              )),
        ],
      ),
    );
  }

  Future<void> _seleccionarPadre(
      BuildContext context, bool esMadre, int animalId) async {
    final animales = await ref.read(animalesNotifierProvider.future);
    final sexoFiltrar = esMadre ? 'H' : 'M';
    final disponibles = animales
        .where((a) => a.sexo == sexoFiltrar && a.id != animalId)
        .toList();

    if (disponibles.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'No hay animales ${esMadre ? "hembra" : "macho"} disponibles'),
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    final seleccionado = await showDialog<Animal>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Asignar ${esMadre ? "Madre" : "Padre"}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: disponibles.length,
            itemBuilder: (context, index) {
              final a = disponibles[index];
              final color = esMadre ? Colors.pink : Colors.blue;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withOpacity(0.15),
                  child: Icon(
                    esMadre ? Icons.female : Icons.male,
                    color: color,
                  ),
                ),
                title: Text(a.numeroArete),
                subtitle: Text(a.nombre ?? a.raza ?? ''),
                onTap: () => Navigator.pop(ctx, a),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (seleccionado != null && mounted) {
      try {
        final client = ref.read(apiClientProvider);
        final field = esMadre ? 'madre' : 'padre';
        await client.dio.patch('animales/$animalId/', data: {
          field: seleccionado.id,
        });
        ref.invalidate(animalesNotifierProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${esMadre ? "Madre" : "Padre"} asignado: ${seleccionado.numeroArete}'),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Diálogo de baja
  // ---------------------------------------------------------------------------
  Future<void> _showBajaDialog(BuildContext context, Animal animal) async {
    final theme = Theme.of(context);
    final causaOptions = [
      ('vendido', 'Venta', Icons.sell_outlined, AppTheme.primary),
      ('muerto', 'Muerte', Icons.close_outlined, AppTheme.primary),
      ('transferido', 'Transferencia', Icons.swap_horiz, AppTheme.primary),
    ];

    String causaSeleccionada = 'vendido';
    DateTime fechaSeleccionada = DateTime.now();
    final notasCtrl = TextEditingController();
    bool isLoading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.remove_circle_outline, color: AppTheme.error),
              const SizedBox(width: 10),
              const Text(
                'Dar de baja',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.pets,
                          size: 18, color: theme.textTheme.bodySmall?.color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Animal: ${animal.nombre ?? animal.numeroArete}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Motivo de baja',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: causaOptions.map((opt) {
                    final (valor, label, icon, color) = opt;
                    final seleccionado = causaSeleccionada == valor;

                    return FilterChip(
                      elevation: seleccionado ? 2 : 0,
                      pressElevation: 4,
                      avatar: Icon(
                        icon,
                        size: 16,
                        color: seleccionado ? Colors.white : color,
                      ),
                      label: Text(label),
                      selected: seleccionado,
                      onSelected: (_) =>
                          setDialogState(() => causaSeleccionada = valor),
                      selectedColor: color,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      shadowColor: color.withOpacity(0.4),
                      checkmarkColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: seleccionado ? color : theme.dividerColor,
                          width: seleccionado ? 1.5 : 1,
                        ),
                      ),
                      labelStyle: TextStyle(
                        color: seleccionado
                            ? Colors.white
                            : theme.textTheme.bodyMedium?.color,
                        fontWeight:
                            seleccionado ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Fecha de baja',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: fechaSeleccionada,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setDialogState(() => fechaSeleccionada = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      border: Border.all(color: theme.dividerColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 18, color: theme.colorScheme.primary),
                        const SizedBox(width: 10),
                        Text(
                          DateFormat('dd/MM/yyyy').format(fechaSeleccionada),
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontSize: 14),
                        ),
                        const Spacer(),
                        Icon(Icons.arrow_drop_down,
                            color: theme.textTheme.bodySmall?.color),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Notas (opcional)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notasCtrl,
                  maxLines: 3,
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Detalle adicional sobre la baja...',
                    hintStyle:
                        theme.textTheme.bodySmall?.copyWith(fontSize: 13),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.dividerColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: theme.colorScheme.primary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
          actionsPadding:
              const EdgeInsets.only(bottom: 16, right: 16, left: 16),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: const Text(
                'Cancelar',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 4),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 1,
              ),
              onPressed: isLoading
                  ? null
                  : () async {
                      setDialogState(() => isLoading = true);
                      try {
                        await ref
                            .read(animalesNotifierProvider.notifier)
                            .registrarBaja(
                              animalId: animal.id,
                              causa: causaSeleccionada,
                              fecha: DateFormat('yyyy-MM-dd')
                                  .format(fechaSeleccionada),
                              notas: notasCtrl.text.trim(),
                            );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '✅ Animal dado de baja: $causaSeleccionada'),
                              backgroundColor: AppTheme.success,
                            ),
                          );
                          context.pop();
                        }
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: AppTheme.error,
                            ),
                          );
                        }
                      }
                    },
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check, size: 18),
              label: const Text(
                'Confirmar baja',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI helpers ---

  Widget _buildHeader(Animal animal, ThemeData theme) {
    final esActivo = animal.estado == 'activo';
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: esActivo
                      ? AppTheme.primaryGradientFor(theme.brightness)
                      : const LinearGradient(
                          colors: [Colors.grey, Color(0xFF9E9E9E)]),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Center(
                  child: Text(
                    animal.numeroArete[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (!esActivo)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.remove_circle,
                      color: _estadoColor(animal.estado),
                      size: 22,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            animal.numeroArete,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          _EstadoBadge(estado: animal.estado),
        ],
      ),
    );
  }

  Widget _buildInfoCard(Animal animal, ThemeData theme) {
    return _Card(
      title: 'Información',
      icon: Icons.info_outline,
      theme: theme,
      child: Column(
        children: [
          _Row(
              'Estado',
              animal.estado[0].toUpperCase() + animal.estado.substring(1),
              theme),
          _Row('Número de Arete', animal.numeroArete, theme),
          _Row('Nombre', animal.nombre ?? 'Sin nombre', theme),
          _Row('Raza', animal.raza ?? 'No especificada', theme),
          _Row('Sexo', animal.sexo == 'M' ? 'Macho' : 'Hembra', theme),
          _Row('Color', animal.color ?? 'No especificado', theme),
          _Row('Peso Nac. (kg)', animal.pesoNacimientoKg?.toString() ?? 'N/A',
              theme),
          _Row('Fecha Nac.',
              animal.fechaNacimiento?.toString().split(' ')[0] ?? 'N/A', theme),
          _Row('Lote', animal.loteId?.toString() ?? 'Sin lote', theme),
        ],
      ),
    );
  }

  Widget _buildRegistrosCard(Animal animal, ThemeData theme) {
    return _Card(
      title: 'Últimos Registros',
      icon: Icons.history,
      theme: theme,
      child: Column(
        children: [
          _Row('Último peso', animal.ultimoPeso?.toString() ?? 'Sin registro',
              theme),
          _Row('Fecha último peso',
              animal.fechaUltimoPeso?.toString().split(' ')[0] ?? 'N/A', theme),
        ],
      ),
    );
  }

  // Nuevo método para mostrar el AnimalBajaSheet
  void _showBajaSheet(BuildContext context, Animal animal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AnimalBajaSheet(animal: animal),
    );
  }

  void _showEditSheet(BuildContext context, Animal animal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AnimalFormSheet(animalToEdit: animal),
    );
  }

  void _showMoverLoteSheet(BuildContext context, Animal animal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MoverLoteSheet(animal: animal),
    );
  }

  Color _estadoColor(String estado) => switch (estado) {
        'activo' => AppTheme.success,
        'vendido' => Colors.purple,
        'muerto' => AppTheme.error,
        'transferido' => Colors.orange,
        _ => Colors.grey,
      };

  Color _eventTypeColor(String type) => switch (type) {
        'vacunacion' => Colors.green,
        'desparasitacion' => Colors.orange,
        'tratamiento' => AppTheme.info,
        'cirugia' => AppTheme.error,
        'pesaje' => AppTheme.secondary,
        _ => Colors.grey,
      };

  String _eventTypeLabel(String type) => switch (type) {
        'vacunacion' => 'Vacunación',
        'desparasitacion' => 'Desparasitación',
        'tratamiento' => 'Tratamiento',
        'cirugia' => 'Cirugía',
        'pesaje' => 'Pesaje',
        _ => type,
      };

  String _monthName(int month) {
    const months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return months[month - 1];
  }
}

// ---------------------------------------------------------------------------
// Modelo auxiliar
// ---------------------------------------------------------------------------
class _RecentItem {
  final DateTime date;
  final String title;
  final String type;

  _RecentItem({
    required this.date,
    required this.title,
    required this.type,
  });
}

// ---------------------------------------------------------------------------
// Tab de Auditoría
// ---------------------------------------------------------------------------
class _AuditoriaTab extends ConsumerWidget {
  final int animalId;
  const _AuditoriaTab({required this.animalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auditoriaAsync = ref.watch(auditoriaAnimalProvider(animalId));
    final theme = Theme.of(context);

    return auditoriaAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) =>
          Center(child: Text('Error: $err', style: theme.textTheme.bodyMedium)),
      data: (registros) {
        if (registros.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history,
                    size: 48, color: theme.textTheme.bodySmall?.color),
                const SizedBox(height: 12),
                Text('Sin cambios registrados',
                    style: theme.textTheme.bodyMedium),
              ],
            ),
          );
        }

        final ordenados = [...registros]..sort((a, b) =>
            (b['fecha_cambio'] as String)
                .compareTo(a['fecha_cambio'] as String));

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: ordenados.length,
          separatorBuilder: (_, __) =>
              Divider(height: 1, color: theme.dividerColor),
          itemBuilder: (context, index) {
            final r = ordenados[index];
            final campo = r['campo'] as String? ?? '';
            final antes = r['valor_anterior'] as String? ?? '-';
            final despues = r['valor_nuevo'] as String? ?? '-';
            final fechaRaw = r['fecha_cambio'] as String? ?? '';
            final fecha = fechaRaw.isNotEmpty
                ? DateFormat('dd/MM/yyyy HH:mm').format(
                    DateTime.tryParse(fechaRaw)?.toLocal() ?? DateTime.now())
                : '';

            return ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
              leading: _campoIcon(campo, theme),
              title: Text(
                _campoLabel(campo),
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style.copyWith(
                            fontSize: 13,
                          ),
                      children: [
                        TextSpan(
                          text: antes.isEmpty ? '(vacío)' : antes,
                          style: const TextStyle(
                            color: Colors.red,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const TextSpan(text: '  →  '),
                        TextSpan(
                          text: despues.isEmpty ? '(vacío)' : despues,
                          style: TextStyle(
                            color: AppTheme.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fecha,
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: (index * 50).ms);
          },
        );
      },
    );
  }

  Widget _campoIcon(String campo, ThemeData theme) {
    final icon = switch (campo) {
      'estado' => Icons.swap_horiz,
      'nombre' => Icons.badge_outlined,
      'raza' => Icons.pets,
      'lote' => Icons.group_outlined,
      'notas_baja' => Icons.note_outlined,
      _ => Icons.edit_outlined,
    };
    return CircleAvatar(
      radius: 18,
      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
      child: Icon(icon, size: 16, color: theme.colorScheme.primary),
    );
  }

  String _campoLabel(String campo) => switch (campo) {
        'estado' => 'Estado',
        'nombre' => 'Nombre',
        'raza' => 'Raza',
        'lote' => 'Lote',
        'numero_arete' => 'Número de arete',
        'sexo' => 'Sexo',
        'color' => 'Color',
        'fecha_nacimiento' => 'Fecha de nacimiento',
        'peso_nacimiento_kg' => 'Peso nacimiento',
        'notas_baja' => 'Notas de baja',
        _ => campo,
      };
}

// ---------------------------------------------------------------------------
// Widgets auxiliares reutilizables
// ---------------------------------------------------------------------------
class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final ThemeData theme;

  const _Card({
    required this.title,
    required this.icon,
    required this.child,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(title, style: theme.textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [AppTheme.softShadowFor(theme.brightness)],
          ),
          child: child,
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;

  const _Row(this.label, this.value, this.theme);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          Flexible(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  final String estado;
  const _EstadoBadge({required this.estado});

  Color get _color => switch (estado) {
        'activo' => AppTheme.success,
        'vendido' => Colors.purple,
        'muerto' => AppTheme.error,
        'transferido' => Colors.orange,
        _ => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        estado[0].toUpperCase() + estado.substring(1),
        style:
            TextStyle(color: _color, fontWeight: FontWeight.w600, fontSize: 13),
      ),
      backgroundColor: _color.withOpacity(0.15),
      side: BorderSide(color: _color.withOpacity(0.4)),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
