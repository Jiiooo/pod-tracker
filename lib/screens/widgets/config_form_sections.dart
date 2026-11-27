import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/app_tokens.dart';
import '../../utils/ui_helpers.dart';
import '../../widgets/app_widgets.dart';

/// Kartu bagian form dengan label bagian.
class FormSection extends StatelessWidget {
  final String label;
  final List<Widget> children;
  const FormSection({super.key, required this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: Sp.xs),
          child: SectionLabel(label),
        ),
        AppCard(
          padding: const EdgeInsets.all(Sp.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ],
    );
  }
}

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
          borderRadius: Rd.fieldR,
          decoration: const InputDecoration(
            labelText: 'Device / pod',
            prefixIcon: Icon(Icons.devices_other_rounded),
          ),
          items: [
            for (final d in options) DropdownMenuItem(value: d, child: Text(d)),
          ],
          onChanged: (v) => onChanged(v!),
        ),
        AnimatedSize(
          duration: Motion.of(context),
          curve: Motion.curve,
          alignment: Alignment.topCenter,
          child: selectedDevice == 'Lainnya'
              ? Padding(
                  padding: const EdgeInsets.only(top: Sp.m),
                  child: TextFormField(
                    controller: customController,
                    decoration: const InputDecoration(
                      labelText: 'Nama device baru',
                      prefixIcon: Icon(Icons.edit_outlined),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Nama device tidak boleh kosong'
                        : null,
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// Baris tanggal mulai pakai.
class StartDateCard extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;

  const StartDateCard({super.key, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Material(
      color: t.surfaceRaised,
      borderRadius: Rd.fieldR,
      child: InkWell(
        borderRadius: Rd.fieldR,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Sp.l, vertical: Sp.m),
          child: Row(children: [
            Icon(Icons.calendar_month_outlined, color: t.textSecondary),
            const SizedBox(width: Sp.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tanggal mulai pakai', style: context.text.bodySmall),
                  Text('${date.day}/${date.month}/${date.year}',
                      style: context.text.titleSmall
                          ?.copyWith(fontFeatures: AppTokens.tabular)),
                ],
              ),
            ),
            Icon(Icons.edit_calendar_outlined, color: t.textSecondary),
          ]),
        ),
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
        Text('Karakter rasa (pilih satu atau lebih)',
            style: context.text.labelLarge),
        const SizedBox(height: Sp.m),
        Wrap(
          spacing: Sp.s,
          runSpacing: Sp.s,
          children: [
            for (final tag in availableTags)
              FilterChip(
                label: Text(tag,
                    style: TextStyle(
                        color: selectedTags.contains(tag)
                            ? context.scheme.primary
                            : null)),
                selected: selectedTags.contains(tag),
                side: BorderSide(
                    color: selectedTags.contains(tag)
                        ? context.scheme.primary
                        : context.tokens.outline),
                onSelected: (s) => onToggle(tag, s),
              ),
          ],
        ),
      ],
    );
  }
}

/// Dialog animasi sukses setelah menyimpan data.
void showSuccessAnimation(BuildContext context, String message) {
  showActionAnimation(
      context, message, Icons.check_rounded, context.tokens.success);
}

/// Baris input Resistance + Wattage.
class ResistanceWattageRow extends StatelessWidget {
  final TextEditingController resistanceController;
  final TextEditingController wattageController;

  const ResistanceWattageRow(
      {super.key,
      required this.resistanceController,
      required this.wattageController});

  @override
  Widget build(BuildContext context) {
    final numStyle =
        context.text.bodyMedium?.copyWith(fontFeatures: AppTokens.tabular);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: resistanceController,
            style: numStyle,
            decoration: const InputDecoration(labelText: 'Resistance (Ω)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) => v!.isEmpty ? 'Wajib' : null,
          ),
        ),
        const SizedBox(width: Sp.m),
        Expanded(
          child: TextFormField(
            controller: wattageController,
            style: numStyle,
            decoration: const InputDecoration(labelText: 'Wattage (W)'),
            keyboardType: TextInputType.number,
            validator: (v) => v!.isEmpty ? 'Wajib' : null,
          ),
        ),
      ],
    );
  }
}

/// Dropdown airflow dan slider rating rasa.
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
          borderRadius: Rd.fieldR,
          decoration: const InputDecoration(
              labelText: 'Posisi airflow', prefixIcon: Icon(Icons.air_rounded)),
          items: [
            for (final e in ['Tertutup Rapat', 'Setengah', 'Terbuka Penuh'])
              DropdownMenuItem(value: e, child: Text(e)),
          ],
          onChanged: (v) => onAirflowChanged(v!),
        ),
        const SizedBox(height: Sp.xl),
        Row(children: [
          Expanded(child: Text('Rating rasa', style: context.text.labelLarge)),
          RatingStars(rating, size: 18),
          const SizedBox(width: Sp.s),
          Text(rating.toStringAsFixed(1),
              style: context.text.titleSmall
                  ?.copyWith(fontFeatures: AppTokens.tabular)),
        ]),
        Slider(
          value: rating,
          min: 1.0,
          max: 5.0,
          divisions: 40,
          label: rating.toStringAsFixed(1),
          onChanged: (v) => onRatingChanged(double.parse(v.toStringAsFixed(1))),
        ),
      ],
    );
  }
}
