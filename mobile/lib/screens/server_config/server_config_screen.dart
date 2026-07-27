import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/server_config_provider.dart';
import '../../core/services/server_discovery.dart';
import '../../core/theme/app_theme.dart';

class ServerConfigScreen extends ConsumerStatefulWidget {
  const ServerConfigScreen({super.key});

  @override
  ConsumerState<ServerConfigScreen> createState() =>
      _ServerConfigScreenState();
}

class _ServerConfigScreenState extends ConsumerState<ServerConfigScreen> {
  late TextEditingController _urlController;
  bool _isSearching = true;
  bool _showManualInput = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    final currentUrl = ref.read(serverUrlProvider);
    _urlController = TextEditingController(text: currentUrl);
    _startAutoDiscovery();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _startAutoDiscovery() async {
    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      print('[UI] Iniciando búsqueda automática...');
      final foundUrl = await ServerDiscovery.discoverServer();

      if (foundUrl != null) {
        // ✅ Encontrado!
        print('[UI] Servidor encontrado: $foundUrl');
        await ref.read(serverUrlProvider.notifier).saveUrl(foundUrl);

        if (mounted) {
          setState(() {
            _successMessage = '✅ Servidor encontrado: $foundUrl';
            _isSearching = false;
          });

          // Esperar 2 segundos y navegar
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            context.go('/login');
          }
        }
      } else {
        // ❌ No encontrado, mostrar input manual
        print('[UI] Servidor no encontrado automáticamente');
        if (mounted) {
          setState(() {
            _isSearching = false;
            _showManualInput = true;
            _errorMessage =
                'No se encontró el servidor automáticamente.\nIngresa la IP manualmente.';
          });
        }
      }
    } catch (e) {
      print('[UI] Error en auto-discovery: $e');
      if (mounted) {
        setState(() {
          _isSearching = false;
          _showManualInput = true;
          _errorMessage = 'Error en búsqueda: $e';
        });
      }
    }
  }

  Future<void> _handleManualSave() async {
    setState(() => _isSearching = true);

    try {
      String url = _urlController.text.trim();

      if (url.isEmpty) {
        setState(() {
          _errorMessage = 'La URL no puede estar vacía';
          _isSearching = false;
        });
        return;
      }

      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'http://$url';
      }

      await ref.read(serverUrlProvider.notifier).saveUrl(url);

      if (mounted) {
        setState(() {
          _successMessage = '✅ Servidor guardado correctamente';
        });

        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          context.go('/login');
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.headerGradient,
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 60),
                    Text(
                      'Bovion',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme.displayLarge
                          ?.copyWith(color: Colors.white),
                    )
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .slideY(begin: -0.3),
                    const SizedBox(height: 8),
                    Text(
                      _isSearching
                          ? 'Buscando servidor...'
                          : 'Configurar Servidor',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme.titleMedium
                          ?.copyWith(color: Colors.white70),
                    )
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .slideY(begin: -0.3),
                    const SizedBox(height: 60),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [AppTheme.mediumShadow],
                      ),
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_isSearching) ...[
                            const Center(
                              child: SizedBox(
                                width: 80,
                                height: 80,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Escaneando la red local...',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Buscando servidor Django en:\n192.168.1.x, 192.168.101.x, 10.0.0.x',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey),
                            ),
                          ] else if (_successMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.success,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: AppTheme.success,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _successMessage!,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme.bodyMedium
                                        ?.copyWith(
                                          color: AppTheme.success,
                                        ),
                                  ),
                                ],
                              ),
                            )
                                .animate()
                                .fadeIn()
                                .scale(),
                          ] else if (_showManualInput) ...[
                            Text(
                              'Dirección del Servidor',
                              style: Theme.of(context)
                                  .textTheme.labelLarge
                                  ?.copyWith(color: AppTheme.primary),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ingresa la IP o dominio del servidor backend',
                              style: Theme.of(context)
                                  .textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            if (_errorMessage != null &&
                                _errorMessage!.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: AppTheme.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppTheme.error,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(color: AppTheme.error),
                                ),
                              ),
                            TextField(
                              controller: _urlController,
                              decoration: InputDecoration(
                                hintText:
                                    'ej: 192.168.1.100:8000 o servidor.local:8000',
                                prefixIcon:
                                    const Icon(Icons.dns_outlined),
                              ),
                            )
                                .animate()
                                .fadeIn(delay: 200.ms)
                                .slideY(begin: 0.5),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ejemplos:',
                                    style: Theme.of(context)
                                        .textTheme.labelSmall,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildExample(
                                      '• 192.168.101.14:8000'),
                                  _buildExample(
                                      '• bovion.local:8000'),
                                  _buildExample(
                                      '• servidor.duckdns.org:8000'),
                                ],
                              ),
                            )
                                .animate()
                                .fadeIn(delay: 300.ms)
                                .slideY(begin: 0.3),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _handleManualSave,
                              child: const Text(
                                  'Guardar y continuar'),
                            )
                                .animate()
                                .fadeIn(delay: 400.ms)
                                .slideY(begin: 0.5),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: _startAutoDiscovery,
                              child: const Text(
                                  'Intentar búsqueda automática'),
                            )
                                .animate()
                                .fadeIn(delay: 500.ms)
                                .slideY(begin: 0.5),
                          ],
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 800.ms)
                        .slideY(begin: 0.3),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExample(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
