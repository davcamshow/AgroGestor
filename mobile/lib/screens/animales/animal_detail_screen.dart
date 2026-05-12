import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/models/animal.dart';
import '../../core/models/evento_sanitario.dart';
import '../../core/models/registro_peso.dart';
import '../../core/providers/animales_provider.dart';
import '../../core/providers/eventos_sanitarios_provider.dart';
import '../../core/providers/registros_peso_provider.dart';
import '../../core/theme/app_theme.dart';
import 'animal_form_sheet.dart';
import 'agregar_registro_sheet.dart';

class AnimalDetailScreen extends ConsumerStatefulWidget {
  final String animalId;

  const AnimalDetailScreen({super.key, required this.animalId});

  @override
  ConsumerState<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends ConsumerState<AnimalDetailScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  List<EventoSanitario> _eventosDelMes = [];

  @override
  Widget build(BuildContext context) {
    final animalesAsync = ref.watch(animalesNotifierProvider);
    final eventosAsync = ref.watch(eventosSanitariosNotifierProvider);
    final registrosAsync = ref.watch(registrosPesoAnimalProvider(int.tryParse(widget.animalId) ?? 0));

    return animalesAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Error: $err')),
      ),
      data: (animales) {
        final animal = animales.where((a) => a.id.toString() == widget.animalId).firstOrNull;
        
        if (animal == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Animal no encontrado')),
            body: const Center(child: Text('Animal no encontrado')),
          );
        }

        final eventosAnimal = eventosAsync.valueOrNull
                ?.where((e) => e.animalId == animal.id)
                .toList() ??
            [];

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/dashboard');
                }
              },
            ),
            title: Text(animal.nombre ?? animal.numeroArete),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showEditSheet(context, animal),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  ref.invalidate(animalesNotifierProvider);
                  ref.invalidate(registrosPesoAnimalProvider(int.tryParse(widget.animalId) ?? 0));
                  ref.invalidate(eventosSanitariosNotifierProvider);
                },
              ),
            ],
          ),
body: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(animalesNotifierProvider);
              ref.invalidate(registrosPesoAnimalProvider(int.tryParse(widget.animalId) ?? 0));
              ref.invalidate(eventosSanitariosNotifierProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(animal).animate().fadeIn().slideY(begin: -0.2),
                  const SizedBox(height: 24),
                  
                  _buildSection('Información', Icons.info_outline, [
                    _buildInfoCard(animal),
                  ]).animate().fadeIn(delay: 200.ms).slideX(),
                  const SizedBox(height: 16),
                  
                  _buildSection('Genealogía', Icons.family_restroom, [
                    _buildGenealogiaCard(animal, animales),
                  ]).animate().fadeIn(delay: 300.ms).slideX(),
                  const SizedBox(height: 16),
                  
                  _buildSection('Registros', Icons.history, [
                    _buildRegistrosCard(animal, eventosAnimal, registrosAsync),
                  ]).animate().fadeIn(delay: 400.ms).slideX(),
                  const SizedBox(height: 16),
                  
                  _buildSection('Calendario de Eventos', Icons.calendar_month, [
                    _buildCalendarioCard(animal, eventosAnimal),
                  ]).animate().fadeIn(delay: 500.ms).slideX(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(Animal animal) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
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
          const SizedBox(height: 12),
          Text(
            animal.numeroArete,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Chip(
            label: Text(animal.estado ?? 'activo'),
            backgroundColor: AppTheme.success.withOpacity(0.2),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildInfoCard(Animal animal) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [AppTheme.softShadow],
      ),
      child: Column(
        children: [
          _buildRow('Número de Arete', animal.numeroArete),
          _buildRow('Nombre', animal.nombre ?? 'Sin nombre'),
          _buildRow('Raza', animal.raza ?? 'No especificada'),
          _buildRow('Sexo', animal.sexo == 'M' ? 'Macho' : 'Hembra'),
          _buildRow('Color', animal.color ?? 'No especificado'),
          _buildRow('Peso Nac. (kg)', animal.pesoNacimientoKg ?? 'N/A'),
          _buildRow('Fecha Nac.', animal.fechaNacimiento?.toString().split(' ')[0] ?? 'N/A'),
          _buildRow('Lote', animal.loteId?.toString() ?? 'Sin lote'),
        ],
      ),
    );
  }

  Widget _buildGenealogiaCard(Animal animal, List<Animal> allAnimales) {
    final madre = animal.madreId != null
        ? allAnimales.where((a) => a.id == animal.madreId).firstOrNull
        : null;
    final padre = animal.padreId != null
        ? allAnimales.where((a) => a.id == animal.padreId).firstOrNull
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [AppTheme.softShadow],
      ),
      child: Column(
        children: [
          _buildGenealogiaRow('Madre', madre, Icons.female),
          const Divider(),
          _buildGenealogiaRow('Padre', padre, Icons.male),
        ],
      ),
    );
  }

  Widget _buildGenealogiaRow(String label, Animal? parentesco, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: parentesco != null ? AppTheme.primary : Colors.grey, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey)),
                Text(
                  parentesco != null ? '${parentesco.numeroArete}${parentesco.nombre != null ? " - ${parentesco.nombre}" : ""}' : 'Sin registrar',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: parentesco != null ? Colors.black : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          if (parentesco != null)
            IconButton(
              icon: const Icon(Icons.visibility, size: 18),
              onPressed: () => context.go('/animales/${parentesco.id}'),
            ),
        ],
      ),
    );
  }

  Widget _buildRegistrosCard(Animal animal, List<EventoSanitario> eventos, AsyncValue<List<RegistroPeso>> registrosAsync) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [AppTheme.softShadow],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _mostrarHistorialPesajes(context, registrosAsync),
            child: _buildRow('Último peso', animal.ultimoPesoKg ?? 'Sin registro', isLink: true),
          ),
          _buildRow('Fecha último peso', animal.fechaUltimoPeso?.toString().split(' ')[0] ?? 'N/A'),
          InkWell(
            onTap: () => _mostrarHistorialEventos(context, eventos),
            child: _buildRow('Total eventos sanitarios', '${eventos.length}', isLink: true),
          ),
          InkWell(
            onTap: () => _mostrarHistorialEventos(context, eventos),
            child: _buildRow('Último evento', eventos.isNotEmpty ? _formatearFecha(eventos.first.fechaAplicacion) : 'N/A', isLink: true),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _mostrarAgregarRegistro(context, animal),
              icon: const Icon(Icons.add),
              label: const Text('Agregar Registro'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarioCard(Animal animal, List<EventoSanitario> eventos) {
    _eventosDelMes = eventos.where((e) {
      if (e.fechaAplicacion.month == _focusedDay.month &&
          e.fechaAplicacion.year == _focusedDay.year) {
        return true;
      }
      if (e.proximaAplicacion != null &&
          e.proximaAplicacion!.month == _focusedDay.month &&
          e.proximaAplicacion!.year == _focusedDay.year) {
        return true;
      }
      return false;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [AppTheme.softShadow],
      ),
      child: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _mostrarEventosDelDia(context, selectedDay, eventos);
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: AppTheme.info,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            eventLoader: (day) {
              return eventos.where((e) {
                return isSameDay(e.fechaAplicacion, day) ||
                    (e.proximaAplicacion != null && isSameDay(e.proximaAplicacion!, day));
              }).toList();
            },
          ),
          const SizedBox(height: 16),
          if (_eventosDelMes.isNotEmpty) ...[
            const Text('Eventos del mes:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._eventosDelMes.map((e) => Card(
              child: ListTile(
                leading: Icon(_getTipoIcon(e.tipo), color: AppTheme.info),
                title: Text('${_getTipoLabel(e.tipo)} - ${e.producto}'),
                subtitle: Text(_formatearFecha(e.fechaAplicacion)),
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isLink ? AppTheme.primary : null,
              decoration: isLink ? TextDecoration.underline : null,
            ),
          ),
        ],
      ),
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

  void _mostrarHistorialEventos(BuildContext context, List<EventoSanitario> eventos) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Historial de Eventos'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: eventos.isEmpty
              ? const Center(child: Text('No hay eventos registrados'))
              : ListView.builder(
                  itemCount: eventos.length,
                  itemBuilder: (context, index) {
                    final evento = eventos[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.info.withOpacity(0.2),
                          child: Icon(_getTipoIcon(evento.tipo), color: AppTheme.info),
                        ),
                        title: Text('${_getTipoLabel(evento.tipo)} - ${evento.producto}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Fecha: ${_formatearFecha(evento.fechaAplicacion)}'),
                            if (evento.dosis != null) Text('Dósis: ${evento.dosis}'),
                            if (evento.proximaAplicacion != null)
                              Text(
                                'Próxima: ${_formatearFecha(evento.proximaAplicacion!)}',
                                style: TextStyle(color: AppTheme.info),
                              ),
                          ],
                        ),
                        trailing: evento.costo > 0
                            ? Text('\$${evento.costo.toStringAsFixed(0)}')
                            : null,
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _mostrarHistorialPesajes(BuildContext context, AsyncValue<List<RegistroPeso>> registrosAsync) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Historial de Pesajes'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: registrosAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (registros) => registros.isEmpty
                ? const Center(child: Text('No hay pesajes registrados'))
                : ListView.builder(
                    itemCount: registros.length,
                    itemBuilder: (context, index) {
                      final reg = registros[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.secondary.withOpacity(0.2),
                            child: const Icon(Icons.scale, color: AppTheme.secondary),
                          ),
                          title: Text('${reg.pesoKg} kg'),
                          subtitle: Text(_formatearFecha(reg.fechaPesaje)),
                          trailing: reg.gananciaDiariaKg != null
                              ? Text('${reg.gananciaDiariaKg} kg/día')
                              : null,
                        ),
                      );
                    },
                  ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _mostrarAgregarRegistro(BuildContext context, Animal animal) {
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

  void _mostrarEventosDelDia(BuildContext context, DateTime dia, List<EventoSanitario> eventos) {
    final eventosDelDia = eventos.where((e) {
      return isSameDay(e.fechaAplicacion, dia) ||
          (e.proximaAplicacion != null && isSameDay(e.proximaAplicacion!, dia));
    }).toList();

    if (eventosDelDia.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eventos del ${_formatearFecha(dia)}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: eventosDelDia.length,
            itemBuilder: (context, index) {
              final evento = eventosDelDia[index];
              return Card(
                child: ListTile(
                  leading: Icon(_getTipoIcon(evento.tipo), color: AppTheme.info),
                  title: Text('${_getTipoLabel(evento.tipo)} - ${evento.producto}'),
                  subtitle: Text(evento.dosis ?? ''),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  IconData _getTipoIcon(String tipo) {
    switch (tipo) {
      case 'vacunacion':
        return Icons.vaccines;
      case 'desparasitacion':
        return Icons.medication;
      case 'tratamiento':
        return Icons.healing;
      case 'cirugia':
        return Icons.medical_services;
      default:
        return Icons.event;
    }
  }

  String _getTipoLabel(String tipo) {
    switch (tipo) {
      case 'vacunacion':
        return 'Vacunación';
      case 'desparasitacion':
        return 'Desparasitación';
      case 'tratamiento':
        return 'Tratamiento';
      case 'cirugia':
        return 'Cirugía';
      default:
        return tipo;
    }
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }
}
