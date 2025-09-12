import 'package:flutter/material.dart';

class DiscordTokenDialog extends StatefulWidget {
  const DiscordTokenDialog({super.key});

  @override
  State<DiscordTokenDialog> createState() => _DiscordTokenDialogState();
}

class _DiscordTokenDialogState extends State<DiscordTokenDialog> {
  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Paste Discord Access Token'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(hintText: 'Access Token'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(controller.text),
          child: const Text('Continue'),
        ),
      ],
    );
  }
}
