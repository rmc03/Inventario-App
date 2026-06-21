import 'package:flutter/material.dart';

class CategoryNameDialog extends StatefulWidget {
  const CategoryNameDialog({
    super.key,
    required this.title,
    required this.categoryExists,
  });

  final String title;
  final bool Function(String name) categoryExists;

  @override
  State<CategoryNameDialog> createState() => _CategoryNameDialogState();
}

class _CategoryNameDialogState extends State<CategoryNameDialog> {
  final _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() => _errorText = 'El nombre es obligatorio');
      return;
    }

    if (widget.categoryExists(value)) {
      setState(() => _errorText = 'Ya existe una categoría con este nombre');
      return;
    }

    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Nombre',
              errorText: _errorText,
            ),
            onChanged: (_) {
              if (_errorText != null) {
                setState(() => _errorText = null);
              }
            },
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Guardar')),
      ],
    );
  }
}
