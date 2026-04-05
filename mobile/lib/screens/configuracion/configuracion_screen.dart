import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_state.dart';
import '../../core/auth/auth_repository.dart';

class ConfiguracionScreen extends ConsumerStatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  ConsumerState<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends ConsumerState<ConfiguracionScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _ranchNameController;
  late TextEditingController _ranchAddressController;
  String _selectedRole = 'Médico Veterinario';
  String _selectedCurrency = 'MXN';
  String _selectedUnit = 'kg';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _ranchNameController = TextEditingController();
    _ranchAddressController = TextEditingController();

    final user = ref.read(authProvider).user;
    if (user != null) {
      _nameController.text = user.nombre_completo;
      _emailController.text = user.email;
      _phoneController.text = user.telefono ?? '';
      _ranchNameController.text = user.nombre_rancho ?? '';
      _ranchAddressController.text = user.direccion_rancho ?? '';
      _selectedRole = user.rol_profesional ?? 'Médico Veterinario';
      _selectedCurrency = user.moneda;
      _selectedUnit = user.unidad_peso;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _ranchNameController.dispose();
    _ranchAddressController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).updateProfile(
            nombreCompleto: _nameController.text,
            telefono: _phoneController.text,
            rolProfesional: _selectedRole,
            nombreRancho: _ranchNameController.text,
            direccionRancho: _ranchAddressController.text,
            moneda: _selectedCurrency,
            unidadPeso: _selectedUnit,
          );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: const Color(0xFF064e3b),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Información Personal',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nombre Completo',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: InputDecoration(
                  labelText: 'Rol Profesional',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: [
                  'Médico Veterinario',
                  'Ing. Zootecnista',
                  'Productor Ganadero',
                  'Estudiante',
                ]
                    .map((role) => DropdownMenuItem(
                          value: role,
                          child: Text(role),
                        ))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedRole = value ?? 'Médico Veterinario'),
              ),
              const SizedBox(height: 32),
              Text(
                'Información del Rancho',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _ranchNameController,
                decoration: InputDecoration(
                  labelText: 'Nombre del Rancho',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _ranchAddressController,
                decoration: InputDecoration(
                  labelText: 'Dirección',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              Text(
                'Preferencias',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCurrency,
                decoration: InputDecoration(
                  labelText: 'Moneda',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: ['MXN', 'USD']
                    .map((curr) => DropdownMenuItem(
                          value: curr,
                          child: Text(curr),
                        ))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedCurrency = value ?? 'MXN'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedUnit,
                decoration: InputDecoration(
                  labelText: 'Unidad de Peso',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: ['kg', 'lb']
                    .map((unit) => DropdownMenuItem(
                          value: unit,
                          child: Text(unit),
                        ))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedUnit = value ?? 'kg'),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF064e3b),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text(
                        'Guardar',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
