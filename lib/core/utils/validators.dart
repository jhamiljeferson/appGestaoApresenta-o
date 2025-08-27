/// Valida se o e-mail está preenchido e em formato válido.
String? validateEmail(String? value) {
  if (value == null || value.isEmpty) return 'Email obrigatório';
  final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  if (!emailRegex.hasMatch(value)) return 'Email inválido';
  return null;
}

/// Valida se a senha está preenchida e tem pelo menos 6 caracteres.
String? validatePassword(String? value) {
  if (value == null || value.isEmpty) return 'Senha obrigatória';
  if (value.length < 6) return 'Senha deve ter pelo menos 6 caracteres';
  return null;
}
