import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/pod_config.dart';
import '../providers/pod_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widgets/config_form_sections.dart';
import 'widgets/image_picker_card.dart';

class AddConfigScreen extends StatefulWidget {
  final PodConfig? configToEdit;
  const AddConfigScreen({super.key, this.configToEdit});

  @override
  State<AddConfigScreen> createState() => _AddConfigScreenState();
}

class _AddConfigScreenState extends State<AddConfigScreen> {
  final _formKey = GlobalKey<FormState>();

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

    _liquidController = TextEditingController(text: isEdit ? widget.configToEdit!.liquidName : '');
    _resistanceController = TextEditingController(text: isEdit ? widget.configToEdit!.resistance.toString() : '');
    _wattageController = TextEditingController(text: isEdit ? widget.configToEdit!.optimalWattage.toString() : '');
    _priceController = TextEditingController(text: isEdit ? widget.configToEdit!.price.toInt().toString() : '');
    _customDeviceController = TextEditingController();

    if (isEdit) {
      _airflow = widget.configToEdit!.airflowLevel;
      _rating = widget.configToEdit!.flavorRating;
      _selectedDate = widget.configToEdit!.dateStarted;
      _selectedTags = List.from(widget.configToEdit!.flavorTags);

      // LANGSUNG MASUKKAN PATH ATAU LINK DARI DATABASE
      _currentImagePath = widget.configToEdit!.imagePath;

      if (_deviceOptions.contains(widget.configToEdit!.deviceName)) {
        _selectedDevice = widget.configToEdit!.deviceName;
      } else {
        _selectedDevice = 'Lainnya';
        _customDeviceController.text = widget.configToEdit!.deviceName;
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


  void _saveData() async {
    if (_formKey.currentState!.validate()) {
      final finalDeviceName = _selectedDevice == 'Lainnya'
          ? _customDeviceController.text
          : _selectedDevice;

      final currentUser = Supabase.instance.client.auth.currentUser;

      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesi terputus! Silakan kembali dan Login ulang.'),
            backgroundColor: Colors.red,
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

      showSuccessAnimation(context, widget.configToEdit != null ? 'Data Diperbarui!' : 'Berhasil Disimpan!');
      await Future.delayed(const Duration(milliseconds: 1200));

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _liquidController.dispose();
    _resistanceController.dispose();
    _wattageController.dispose();
    _priceController.dispose();
    _customDeviceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.configToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Settingan' : 'Catat Settingan Baru'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // --- AREA FOTO BOTOL LIQUID (SUDAH MENDUKUNG CLOUD) ---
            ImagePickerCard(imagePath: _currentImagePath, onTap: _showImageSourceDialog),
            const SizedBox(height: 24),

            DeviceSelector(
              selectedDevice: _selectedDevice,
              options: _deviceOptions,
              customController: _customDeviceController,
              onChanged: (value) => setState(() {
                _selectedDevice = value;
                if (_selectedDevice != 'Lainnya') {
                  _customDeviceController.clear();
                }
              }),
            ),

            const SizedBox(height: 16),

            StartDateCard(date: _selectedDate, onTap: _pickDate),
            const SizedBox(height: 16),

            TextFormField(
              controller: _liquidController,
              decoration: const InputDecoration(labelText: 'Nama Liquid', border: OutlineInputBorder()),
              validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 16),

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
            const SizedBox(height: 16),

            ResistanceWattageRow(
              resistanceController: _resistanceController,
              wattageController: _wattageController,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Harga (Rp)', border: OutlineInputBorder(), prefixText: 'Rp '),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            AirflowAndRatingSection(
              airflow: _airflow,
              rating: _rating,
              onAirflowChanged: (val) => setState(() => _airflow = val),
              onRatingChanged: (val) => setState(() => _rating = val),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _saveData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                child: Text(isEdit ? 'Update Settingan' : 'Simpan Settingan', style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
