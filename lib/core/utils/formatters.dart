// Adicione ao pubspec.yaml:
// dependencies:
//   intl: ^0.18.0
import 'package:intl/intl.dart';

/// Formata uma data para o padrão dd/MM/yyyy.
String formatDate(DateTime date) => DateFormat('dd/MM/yyyy').format(date);

/// Formata um valor numérico para moeda brasileira.
String formatCurrency(num value) =>
    NumberFormat.simpleCurrency(locale: 'pt_BR').format(value);
