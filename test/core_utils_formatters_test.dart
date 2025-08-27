import 'package:flutter_test/flutter_test.dart';
import 'package:gestao_mvp/core/utils/formatters.dart';

void main() {
  test('formatDate formata corretamente', () {
    final date = DateTime(2023, 5, 10);
    expect(formatDate(date), '10/05/2023');
  });

  test('formatCurrency formata corretamente', () {
    expect(formatCurrency(1234.56), 'R\$ 1.234,56');
  });
}
