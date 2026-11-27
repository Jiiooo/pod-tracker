import 'package:flutter/material.dart';

/// Dropdown device + kolom nama device kustom ketika memilih "Lainnya".
class DeviceSelector extends StatelessWidget {
  final String selectedDevice;
  final List<String> options;
  final TextEditingController customController;
  final ValueChanged<String> onChanged;

  const DeviceSelector({
    super.key,
    required this.selectedDevice,
    required this.options,
    required this.customController,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          initialValue: selectedDevice,
          decoration: InputDecoration(
            labelText: 'Pilih Device / Pod',
            prefixIcon: const Icon(Icons.vape_free),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: options.map((String device) {
            return DropdownMenuItem<String>(value: device, child: Text(device));
          }).toList(),
          onChanged: (String? newValue) => onChanged(newValue!),
        ),
        if (selectedDevice == 'Lainnya') ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: customController,
            decoration: InputDecoration(
              labelText: 'Ketik Nama Device Baru',
              prefixIcon: const Icon(Icons.edit),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Nama device tidak boleh kosong';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }
}

/// Kartu tanggal mulai pakai.
class StartDateCard extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;

  const StartDateCard({super.key, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: ListTile(
        leading: const Icon(Icons.calendar_month),
        title: const Text('Tanggal Mulai Pakai'),
        subtitle: Text('${date.day}/${date.month}/${date.year}'),
        trailing: const Icon(Icons.edit_calendar),
        onTap: onTap,
      ),
    );
  }
}

/// Pilihan karakter rasa (FilterChip).
class FlavorTagSelector extends StatelessWidget {
  final List<String> availableTags;
  final List<String> selectedTags;
  final void Function(String tag, bool selected) onToggle;

  const FlavorTagSelector({
    super.key,
    required this.availableTags,
    required this.selectedTags,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Karakter Rasa (Pilih 1 atau lebih):', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 0.0,
          children: availableTags.map((tag) {
            return FilterChip(
              label: Text(tag),
              selected: selectedTags.contains(tag),
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
              checkmarkColor: Theme.of(context).colorScheme.primary,
              onSelected: (bool selected) => onToggle(tag, selected),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Dialog animasi sukses setelah menyimpan data.
void showSuccessAnimation(BuildContext context, String message) {
  showGeneralDialog(
    context: context,
    barrierDismissible: false,
    pageBuilder: (_, _, _) => const SizedBox(),
    transitionBuilder: (ctx, anim1, anim2, child) {
      return ScaleTransition(
        scale: CurvedAnimation(parent: anim1, curve: Curves.elasticOut),
        child: AlertDialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          content: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(20)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 72),
                const SizedBox(height: 16),
                Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 500),
  );
}

/// Baris input Resistance + Wattage.
class ResistanceWattageRow extends StatelessWidget {
  final TextEditingController resistanceController;
  final TextEditingController wattageController;

  const ResistanceWattageRow({super.key, required this.resistanceController, required this.wattageController});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: resistanceController,
            decoration: const InputDecoration(labelText: 'Resistance (Ohm)', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
            validator: (value) => value!.isEmpty ? 'Wajib' : null,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: wattageController,
            decoration: const InputDecoration(labelText: 'Wattage (W)', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
            validator: (value) => value!.isEmpty ? 'Wajib' : null,
          ),
        ),
      ],
    );
  }
}

/// Dropdown airflow, slider rating rasa.
class AirflowAndRatingSection extends StatelessWidget {
  final String airflow;
  final double rating;
  final ValueChanged<String> onAirflowChanged;
  final ValueChanged<double> onRatingChanged;

  const AirflowAndRatingSection({
    super.key,
    required this.airflow,
    required this.rating,
    required this.onAirflowChanged,
    required this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: airflow,
          decoration: const InputDecoration(labelText: 'Posisi Airflow', border: OutlineInputBorder()),
          items: ['Tertutup Rapat', 'Setengah', 'Terbuka Penuh'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (val) => onAirflowChanged(val!),
        ),
        const SizedBox(height: 24),
        Text('Rating Rasa: ${rating.toStringAsFixed(1)} / 5.0', style: const TextStyle(fontWeight: FontWeight.bold)),
        Slider(
          value: rating, min: 1.0, max: 5.0, divisions: 40,
          label: rating.toStringAsFixed(1),
          onChanged: (val) => onRatingChanged(double.parse(val.toStringAsFixed(1))),
        ),
      ],
    );
  }
}
