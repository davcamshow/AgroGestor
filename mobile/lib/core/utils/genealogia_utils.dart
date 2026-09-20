import '../models/animal.dart';

class GenealogiaUtils {
  
  /// se le filtra y ordena posibles madres por biología y ubicación
  static List<Animal> obtenerPosiblesMadres(List<Animal> rebanho, int? loteActualId) {
    var madres = rebanho.where((a) {
      final esHembra = a.sexo == 'H';
      final estaActiva = a.estado == 'activo';
      final edadReproductiva = a.edadDias == null || a.edadDias! >= 450; 
      
      return esHembra && estaActiva && edadReproductiva;
    }).toList();

    // ORDENAMIENTO CORREGIDO
    madres.sort((a, b) {
      // 1. Si el usuario YA seleccionó un lote, priorizar las vacas de ese potrero
      if (loteActualId != null) {
        if (a.loteId == loteActualId && b.loteId != loteActualId) return -1;
        if (a.loteId != loteActualId && b.loteId == loteActualId) return 1;
      }

      // 2. Si NO hay lote seleccionado o ambas vacas están en el mismo caso,
      // agrupamos por lote y mandamos a las "sin lote" hasta el final de la lista.
      if (a.loteId != b.loteId) {
        if (a.loteId == null) return 1;
        if (b.loteId == null) return -1;
        return a.loteId!.compareTo(b.loteId!);
      }

      // 3. Desempate: orden alfabético por arete
      return a.numeroArete.compareTo(b.numeroArete);
    });

    return madres;
  }

  //obtener posibles padres por biología
  static List<Animal> obtenerPosiblesPadres(List<Animal> rebanho) {
    return rebanho.where((a) {
      final esMacho = a.sexo == 'M';
      final estaActivo = a.estado == 'activo';
      // Validación de edad para sementales (ej. 12 meses = 365 días)
      final edadReproductiva = a.edadDias == null || a.edadDias! >= 365;
      
      return esMacho && estaActivo && edadReproductiva;
    }).toList()..sort((a, b) => a.numeroArete.compareTo(b.numeroArete));
  }
}