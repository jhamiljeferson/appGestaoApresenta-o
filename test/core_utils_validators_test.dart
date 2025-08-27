import 'package:flutter_test/flutter_test.dart';
import 'package:gestao_mvp/core/utils/validators.dart';

void main() {
  group('validateEmail', () {
    test('retorna erro se vazio', () {
      expect(validateEmail(''), 'Email obrigatório');
      expect(validateEmail(null), 'Email obrigatório');
    });
    test('retorna erro se formato inválido', () {
      expect(validateEmail('abc'), 'Email inválido');
      expect(validateEmail('abc@'), 'Email inválido');
      expect(validateEmail('abc@abc'), 'Email inválido');
      expect(validateEmail('abc@abc.'), 'Email inválido');
    });
    test('retorna null se válido', () {
      expect(validateEmail('teste@email.com'), null);
    });
  });

  group('validatePassword', () {
    test('retorna erro se vazio', () {
      expect(validatePassword(''), 'Senha obrigatória');
      expect(validatePassword(null), 'Senha obrigatória');
    });
    test('retorna erro se menor que 6', () {
      expect(
        validatePassword('12345'),
        'Senha deve ter pelo menos 6 caracteres',
      );
    });
    test('retorna null se válido', () {
      expect(validatePassword('123456'), null);
    });
  });
}
