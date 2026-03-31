import 'package:flutter/material.dart';

import '../../../core/calibration/calibration_service.dart';

/// Diálogo para ajustar el offset de calibración del micrófono.
class CalibrationDialog extends StatefulWidget {
  final CalibrationService calibrationService;
  final VoidCallback onChanged;

  const CalibrationDialog({
    super.key,
    required this.calibrationService,
    required this.onChanged,
  });

  @override
  State<CalibrationDialog> createState() => _CalibrationDialogState();
}

class _CalibrationDialogState extends State<CalibrationDialog> {
  late double _currentOffset;

  @override
  void initState() {
    super.initState();
    _currentOffset = widget.calibrationService.offset;
  }

  @override
  Widget build(BuildContext context) {
    final sign = _currentOffset >= 0 ? '+' : '';
    return AlertDialog(
      title: const Text('Calibración del micrófono'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$sign${_currentOffset.toStringAsFixed(1)} dB',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 16),
          Slider(
            value: _currentOffset,
            min: CalibrationService.minOffset,
            max: CalibrationService.maxOffset,
            divisions: 80,
            label: '$sign${_currentOffset.toStringAsFixed(1)} dB',
            onChanged: (value) {
              setState(() {
                _currentOffset = value;
              });
            },
          ),
          const SizedBox(height: 8),
          const Text(
            'Ajusta el offset para compensar la diferencia entre '
            'tu dispositivo y un sonómetro de referencia.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _currentOffset = CalibrationService.defaultOffset;
            });
          },
          child: const Text('Resetear'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () async {
            await widget.calibrationService.setOffset(_currentOffset);
            widget.onChanged();
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: const Text('Aplicar'),
        ),
      ],
    );
  }
}
