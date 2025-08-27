import 'package:flutter/material.dart';

/// Botão compartilhado reutilizável com suporte a loading.
class SharedButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool loading;

  const SharedButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }
}
