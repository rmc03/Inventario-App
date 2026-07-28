// Validación y sanitización de entradas de usuario.
//
// Centraliza la lógica de validación para formularios y entradas de texto
// para prevenir inyección, desbordamiento y datos inválidos.

/// Límite máximo de caracteres para campos de texto general
const int _kMaxTextLength = 200;

/// Límite para nombres de productos/entidades
const int _kMaxNameLength = 100;

/// Límite para descripciones
const int _kMaxDescriptionLength = 500;

/// Límite para comentarios
const int _kMaxCommentLength = 1000;

/// Límite para códigos de referencia
const int _kMaxCodeLength = 50;

/// Sanitiza texto de entrada eliminando caracteres de control peligrosos
/// y limitando la longitud.
String sanitizeText(String input, {int maxLength = _kMaxTextLength}) {
  final trimmed = input.trim();
  if (trimmed.length > maxLength) {
    return trimmed.substring(0, maxLength);
  }
  // Eliminar caracteres de control excepto tab, newline, carriage return
  return trimmed.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');
}

/// Sanitiza un nombre (producto, categoría, usuario)
String sanitizeName(String input) => sanitizeText(input, maxLength: _kMaxNameLength);

/// Sanitiza una descripción
String sanitizeDescription(String input) => sanitizeText(input, maxLength: _kMaxDescriptionLength);

/// Sanitiza un comentario
String sanitizeComment(String input) => sanitizeText(input, maxLength: _kMaxCommentLength);

/// Sanitiza un código de referencia
String sanitizeCode(String input) => sanitizeText(input, maxLength: _kMaxCodeLength).toUpperCase();

/// Valida email básico
bool isValidEmail(String email) {
  final trimmed = email.trim();
  if (trimmed.isEmpty || trimmed.length > 254) return false;
  // RFC 5322 simplificado - patrón más simple
  final emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  return emailRegex.hasMatch(trimmed);
}

/// Valida que un string no esté vacío después de trim
bool isNotEmpty(String? value) => (value?.trim().isNotEmpty ?? false);

/// Valida longitud mínima
bool hasMinLength(String? value, int min) => (value?.trim().length ?? 0) >= min;

/// Valida longitud máxima
bool hasMaxLength(String? value, int max) => (value?.trim().length ?? 0) <= max;

/// Valida número positivo
bool isPositiveNumber(num? value) => value != null && value > 0;

/// Valida número no negativo
bool isNonNegativeNumber(num? value) => value != null && value >= 0;

/// Valida stock (entero no negativo)
bool isValidStock(int? value) => value != null && value >= 0;

/// Valida precio (positivo, máx 2 decimales)
bool isValidPrice(double? value) {
  if (value == null || value <= 0) return false;
  // Verificar máx 2 decimales
  final str = value.toStringAsFixed(2);
  return double.parse(str) == value;
}

/// Genera mensaje de error estandarizado para validación
String validationErrorMessage({
  required String fieldName,
  bool required = false,
  int? minLength,
  int? maxLength,
  bool isEmail = false,
  bool isPositiveNumber = false,
}) {
  if (required) return '$fieldName es requerido';
  if (isEmail) return 'Ingresa un email válido';
  if (isPositiveNumber) return '$fieldName debe ser un número positivo';
  if (minLength != null) return '$fieldName debe tener al menos $minLength caracteres';
  if (maxLength != null) return '$fieldName no puede exceder $maxLength caracteres';
  return '$fieldName no es válido';
}