import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/pod_config.dart';
import '../providers/pod_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_widgets.dart';
import 'widgets/config_form_sections.dart';
import 'widgets/image_picker_card.dart';

class AddConfigScreen extends StatefulWidget {
  final PodConfig? configToEdit;

  /// Isi form dari config lama, tapi simpan sebagai entri baru (id baru,
  /// tanggal hari ini, aktif).
  final PodConfig? prefillFrom;
  const AddConfigScreen({super.key, this.configToEdit, this.prefillFrom});

  @override
  State<AddConfigScreen> createState() => _AddConfigScreenState();
}

class _AddConfigScreenState extends State<AddConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;

  // Kunci + fokus field wajib, urut sesuai posisi di layar.
  final _customDeviceKey = GlobalKey<FormFieldState<String>>();
  final _liquidKey = GlobalKey<FormFieldState<String>>();
  final _resistanceKey = GlobalKey<FormFieldState<String>>();
  final _wattageKey = GlobalKey<FormFieldState<String>>();
  final _customDeviceFocus = FocusNode();
  final _liquidFocus = FocusNode();
  final _resistanceFocus = FocusNode();
  final _wattageFocus = FocusNode();

  late TextEditingController _liquidController;
  late TextEditingController _resistanceController;
  late TextEditingController _wattageController;
  late TextEditingController _priceController;
  late TextEditingController _customDeviceController;

  String _airflow = 'Setengah';
  double _rating = 3.0;
  DateTime _selectedDate = DateTime.now();

  // KITA UBAH VARIABEL INI MENJADI STRING AGAR BISA MENYIMPAN LINK INTERNET ATAU PATH LOKAL
  String? _currentImagePath;

  List<String> _selectedTags = [];
  final List<String> _availableTags = ['Fruity', 'Creamy', 'Mint', 'Tobacco', 'Pastry', 'Beverage'];

  String _selectedDevice = 'Oxva Nexlim';
  final List<String> _deviceOptions = [
    'Oxva Nexlim',
    'Oxva Xlim Ultra 3',
    'Thelema Nano Lost Vape',
    'Lainnya'
  ];

  @override
  void initState() {
    super.initState();
    final isEdit = widget.configToEdit != null;
    final source = widget.configToEdit ?? widget.prefillFrom;

    _liquidController = TextEditingController(text: source?.liquidName ?? '');
    _resistanceController = TextEditingController(text: source?.resistance.toString() ?? '');
    _wattageController = TextEditingController(text: source?.optimalWattage.toString() ?? '');
    _priceController = TextEditingController(text: source?.price.toInt().toString() ?? '');
    _customDeviceController = TextEditingController();

    if (source != null) {
      _airflow = source.airflowLevel;
      _rating = source.flavorRating;
      // Entri baru dari riwayat selalu mulai hari ini.
      if (isEdit) _selectedDate = source.dateStarted;
      _selectedTags = List.from(source.flavorTags);

      // LANGSUNG MASUKKAN PATH ATAU LINK DARI DATABASE
      _currentImagePath = source.imagePath;

      if (_deviceOptions.contains(source.deviceName)) {
        _selectedDevice = source.deviceName;
      } else {
        _selectedDevice = 'Lainnya';
        _customDeviceController.text = source.deviceName;
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 70, maxWidth: 1280, maxHeight: 1280);

    if (pickedFile != null) {
      setState(() {
        _currentImagePath = pickedFile.path;
      });
    }
  }

  void _showImageSourceDialog() {
    showImageSourceSheet(
      context: context,
      hasImage: _currentImagePath != null,
      onCamera: () => _pickImage(ImageSource.camera),
      onGallery: () => _pickImage(ImageSource.gallery),
      onRemove: () => setState(() => _currentImagePath = null),
    );
  }


  void _scrollToFirstError() {
    final fields = [
      (_customDeviceKey, _customDeviceFocus),
      (_liquidKey, _liquidFocus),
      (_resistanceKey, _resistanceFocus),
      (_wattageKey, _wattageFocus),
    ];
    for (final (key, focus) in fields) {
      final ctx = key.currentContext;
      if (key.currentState?.hasError == true && ctx != null) {
        HapticFeedback.lightImpact();
        Scrollable.ensureVisible(ctx,
            duration: Motion.normal, curve: Motion.curve, alignment: 0.2);
        focus.requestFocus();
        return;
      }
    }
  }

  void _saveData() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToFirstError());
      return;
    }
    {
      final finalDeviceName = _selectedDevice == 'Lainnya'
          ? _customDeviceController.text
          : _selectedDevice;

      final currentUser = Supabase.instance.client.auth.currentUser;

      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesi terputus! Silakan kembali dan Login ulang.'),
          ),
        );
        return;
      }

      final myUserId = currentUser.id;

      final newData = PodConfig(
        id: widget.configToEdit?.id ?? DateTime.now().toString(),
        userId: myUserId,
        deviceName: finalDeviceName,
        resistance: double.parse(_resistanceController.text),
        liquidName: _liquidController.text,
        optimalWattage: int.parse(_wattageController.text),
        airflowLevel: _airflow,
        flavorRating: _rating,
        dateStarted: _selectedDate,
        price: _priceController.text.isEmpty ? 0.0 : double.parse(_priceController.text),
        imagePath: _currentImagePath, // <--- MASUKKAN PATH/LINK TERBARU
        flavorTags: _selectedTags,
      );

      final provider = Provider.of<PodProvider>(context, listen: false);
      if (widget.configToEdit != null) {
        provider.updateConfig(newData); // Memanggil updateConfig dengan data baru
      } else {
        provider.addConfig(newData);
      }

      // The dialog closes itself; only pop this form afterwards.
      await showSuccessAnimation(context, widget.configToEdit != null ? 'Data Diperbarui!' : 'Berhasil Disimpan!');
      if (mounted) Navigator.pop(context);
    }
  }

  Widget _buildHistoryHint() {
    final history = context.read<PodProvider>().historyFor(
          _liquidController.text,
          excludeId: widget.configToEdit?.id,
        );
    if (history == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Text(
        'Riwayat: ${history.count}x dicatat • rating terakhir ${history.lastRating}',
        style: context.text.bodySmall?.copyWith(color: context.scheme.primary),
      ),
    );
  }

  @override
  void dispose() {
    _liquidController.dispose();
    _resistanceController.dispose();
    _wattageController.dispose();
    _priceController.dispose();
    _customDeviceController.dispose();
    _customDeviceFocus.dispose();
    _liquidFocus.dispose();
    _resistanceFocus.dispose();
    _wattageFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.configToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit setingan' : 'Catat setingan baru'),
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: _autovalidate,
        child: MaxWidth(
          width: 640,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(Sp.l, Sp.s, Sp.l, Sp.xxl),
            children: [
              ImagePickerCard(
                  imagePath: _currentImagePath, onTap: _showImageSourceDialog),
              const SizedBox(height: Sp.xl),
              FormSection(label: 'Perangkat', children: [
                DeviceSelector(
                  selectedDevice: _selectedDevice,
                  options: _deviceOptions,
                  customController: _customDeviceController,
                  customFieldKey: _customDeviceKey,
                  customFocusNode: _customDeviceFocus,
                  onChanged: (value) => setState(() {
                    _selectedDevice = value;
                    if (_selectedDevice != 'Lainnya') {
                      _customDeviceController.clear();
                    }
                  }),
                ),
                const SizedBox(height: Sp.m),
                StartDateCard(date: _selectedDate, onTap: _pickDate),
              ]),
              const SizedBox(height: Sp.xl),
              FormSection(label: 'Liquid', children: [
                TextFormField(
                  key: _liquidKey,
                  focusNode: _liquidFocus,
                  controller: _liquidController,
                  decoration: const InputDecoration(labelText: 'Nama liquid'),
                  validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
                  onChanged: (_) => setState(() {}),
                ),
                _buildHistoryHint(),
                const SizedBox(height: Sp.l),
                FlavorTagSelector(
                  availableTags: _availableTags,
                  selectedTags: _selectedTags,
                  onToggle: (tag, selected) => setState(() {
                    if (selected) {
                      _selectedTags.add(tag);
                    } else {
                      _selectedTags.remove(tag);
                    }
                  }),
                ),
                const SizedBox(height: Sp.l),
                TextFormField(
                  controller: _priceController,
                  style: context.text.bodyMedium
                      ?.copyWith(fontFeatures: AppTokens.tabular),
                  decoration: const InputDecoration(
                      labelText: 'Harga (Rp)', prefixText: 'Rp '),
                  keyboardType: TextInputType.number,
                ),
              ]),
              const SizedBox(height: Sp.xl),
              FormSection(label: 'Setelan', children: [
                ResistanceWattageRow(
                  resistanceController: _resistanceController,
                  wattageController: _wattageController,
                  resistanceKey: _resistanceKey,
                  wattageKey: _wattageKey,
                  resistanceFocus: _resistanceFocus,
                  wattageFocus: _wattageFocus,
                ),
                const SizedBox(height: Sp.m),
                AirflowAndRatingSection(
                  airflow: _airflow,
                  rating: _rating,
                  onAirflowChanged: (val) => setState(() => _airflow = val),
                  onRatingChanged: (val) => setState(() => _rating = val),
                ),
              ]),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(Sp.l, Sp.m, Sp.l, Sp.m),
          decoration: BoxDecoration(
            color: context.scheme.surface,
            border: Border(top: BorderSide(color: context.tokens.outline)),
          ),
          child: MaxWidth(
            width: 640,
            child: FilledButton(
              onPressed: _saveData,
              child: Text(isEdit ? 'Update setingan' : 'Simpan setingan'),
            ),
          ),
        ),
      ),
    );
  }
}
