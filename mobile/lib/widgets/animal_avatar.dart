import 'package:flutter/material.dart';
import '../core/models/animal.dart';
import '../core/theme/app_theme.dart';


const String baseUrl = 'http:// 192.168.0.9:8000'; 

class AnimalAvatar extends StatelessWidget {
  final Animal animal;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool dimmed;

  const AnimalAvatar({
    super.key,
    required this.animal,
    this.radius = 20,
    this.backgroundColor,
    this.foregroundColor,
    this.dimmed = false,
  });

  String get _inicial {
    final arete = animal.numeroArete.trim();
    if (arete.isEmpty) return '?';
    return arete[0].toUpperCase();
  }

  // NUEVO: Método para asegurar que la URL esté completa
  String _obtenerUrlCompleta(String ruta) {
    if (ruta.startsWith('http')) {
      return ruta; // Si ya viene completa desde el backend, la dejamos igual
    }
    // Si viene relativa (ej: /media/fotos/img.jpg), le pegamos el dominio/IP
    return '$baseUrl$ruta';
  }

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final bg = backgroundColor ?? AppTheme.secondary.withOpacity(0.2);
    final fg = foregroundColor ?? AppTheme.secondary;

    Widget fallback() => ColoredBox(
          color: bg,
          child: Center(
            child: Text(
              _inicial,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.85,
              ),
            ),
          ),
        );

    final foto = animal.fotoUrl;
    
    final content = (foto == null || foto.isEmpty)
        ? fallback()
        : Image.network(
            _obtenerUrlCompleta(foto), // Usamos la URL formateada
            width: size,
            height: size,
            fit: BoxFit.cover,
            // Si hay un error de conexión o la imagen no existe, mostramos la inicial
            errorBuilder: (_, __, ___) => fallback(),
          );

    return Opacity(
      opacity: dimmed ? 0.55 : 1,
      child: ClipOval(
        child: SizedBox(width: size, height: size, child: content),
      ),
    );
  }
}