import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';

class ArbolGenealogicoScreen extends ConsumerStatefulWidget {
  final int animalId;

  const ArbolGenealogicoScreen({super.key, required this.animalId});

  @override
  ConsumerState<ArbolGenealogicoScreen> createState() => _ArbolGenealogicoScreenState();
}

class _ArbolGenealogicoScreenState extends ConsumerState<ArbolGenealogicoScreen> {
  Map<String, dynamic>? _arbol;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadArbol());
  }

  Future<void> _loadArbol() async {
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/arbol-genealogico/${widget.animalId}/');
      setState(() {
        _arbol = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Árbol Genealógico', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        ' ancestros',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildAncestorCard(
                        _arbol?['animal'],
                        'Animal Principal',
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildAncestorCard(
                              _arbol?['animal']?['padre'],
                              'Padre',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildAncestorCard(
                              _arbol?['animal']?['madre'],
                              'Madre',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        ' Crías Recientes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildCriasList(),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadArbol,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Actualizar'),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildAncestorCard(Map<String, dynamic>? animal, String rol) {
    if (animal == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            Icon(Icons.help_outline, color: Colors.grey[400], size: 32),
            const SizedBox(height: 8),
            Text(
              rol,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const Text(
              'Sin registro',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [AppTheme.softShadow],
      ),
      child: Column(
        children: [
          Icon(
            animal['sexo'] == 'M' ? Icons.male : Icons.female,
            color: animal['sexo'] == 'M' ? Colors.blue : Colors.pink,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            animal['numero_arete'] ?? 'N/A',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          if (animal['nombre'] != null)
            Text(
              animal['nombre'],
              style: TextStyle(color: Colors.grey[600]),
            ),
          if (animal['raza'] != null)
            Text(
              animal['raza'],
              style: TextStyle(color: Colors.grey),
            ),
          Text(
            rol,
            style: const TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriasList() {
    final crias = _arbol?['crias'] as List? ?? [];
    
    if (crias.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'No hay crías registradas',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: crias.length,
      itemBuilder: (context, index) {
        final cria = crias[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [AppTheme.softShadow],
          ),
          child: Row(
            children: [
              Icon(
                cria['sexo'] == 'M' ? Icons.male : Icons.female,
                color: cria['sexo'] == 'M' ? Colors.blue : Colors.pink,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cria['numero_arete'] ?? 'N/A',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (cria['nombre'] != null)
                      Text(cria['nombre'], style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
              if (cria['fecha_nacimiento'] != null)
                Text(
                  _formatDate(cria['fecha_nacimiento']),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      return dateStr.substring(0, 10);
    } catch (_) {
      return dateStr;
    }
  }
}