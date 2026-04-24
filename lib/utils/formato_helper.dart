// lib/utils/formato_helper.dart

/// Helper para formatear valores numéricos con separadores de miles
/// y notación abreviada (K para miles, M para millones)
class FormatoHelper {
  /// Formatea un valor con separadores de miles
  /// Ejemplo: 1000 -> "1,000" | 1000000 -> "1,000,000"
  static String formatearMiles(double valor) {
    if (valor == 0) return '0';
    
    final formato = valor.truncateToDouble() == valor
        ? valor.toInt().toString()
        : valor.toStringAsFixed(2);
    
    // Agregar separadores de miles
    final partes = formato.split('.');
    final entero = partes[0];
    final decimal = partes.length > 1 ? '.${partes[1]}' : '';
    
    final buffer = StringBuffer();
    final length = entero.length;
    
    for (int i = 0; i < length; i++) {
      if (i > 0 && (length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(entero[i]);
    }
    
    return buffer.toString() + decimal;
  }

  /// Formatea un valor con notación abreviada
  /// - Si >= 1,000,000: divide por 1,000,000 y agrega 'M'
  /// - Si >= 1,000: divide por 1,000 y agrega 'K'
  /// - De lo contrario: formato normal con separadores de miles
  /// 
  /// Ejemplos:
  /// - 500 -> "500"
  /// - 1500 -> "1.5K"
  /// - 25000 -> "25K"
  /// - 1500000 -> "1.5M"
  /// - 2500000 -> "2.5M"
  static String formatearAbreviado(double valor) {
    if (valor >= 1000000) {
      // Millones
      final millones = valor / 1000000;
      if (millones == millones.truncateToDouble()) {
        return '${millones.toInt()}M';
      }
      return '${millones.toStringAsFixed(1)}M';
    } else if (valor >= 1000) {
      // Miles
      final miles = valor / 1000;
      if (miles == miles.truncateToDouble()) {
        return '${miles.toInt()}K';
      }
      return '${miles.toStringAsFixed(1)}K';
    } else {
      // Valor normal
      return formatearMiles(valor);
    }
  }

  /// Formatea un valor monetario con símbolo de dólar y notación abreviada
  /// Ejemplo: 1500 -> "$1.5K" | 2500000 -> "$2.5M"
  static String formatearMonto(double valor) {
    return '\$${formatearAbreviado(valor)}';
  }

  /// Formatea un valor monetario completo (sin abreviar)
  /// Ejemplo: 1500 -> "$1,500.00"
  static String formatearMontoCompleto(double valor) {
    return '\$${formatearMiles(valor)}';
  }
}