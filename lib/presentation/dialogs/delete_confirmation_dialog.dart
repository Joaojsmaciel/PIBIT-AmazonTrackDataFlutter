import 'package:flutter/material.dart';


class DeleteConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onConfirm;
  final String confirmText;
  final String cancelText;

  const DeleteConfirmationDialog({
    Key? key,
    required this.title,
    required this.message,
    required this.onConfirm,
    this.confirmText = 'Deletar',
    this.cancelText = 'Cancelar',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(cancelText),
        ),
        ElevatedButton(
          onPressed: () {
            onConfirm();
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: Text(
            confirmText,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
