import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pod_tracker/utils/photo_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/pod_config.dart';
import '../providers/pod_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Ambil dari Kamera'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_currentImagePath != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Hapus Foto', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _currentImagePath = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showSuccessAnimation(String message) {
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

      _showSuccessAnimation(widget.configToEdit != null ? 'Data Diperbarui!' : 'Berhasil Disimpan!');
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
            Center(
              child: GestureDetector(
                onTap: _showImageSourceDialog,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade400, width: 2, style: BorderStyle.solid),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: _currentImagePath != null
                  // CEK APAKAH FOTO DARI INTERNET ATAU MEMORI HP
                      ? StoragePhoto(value: _currentImagePath!, fit: BoxFit.cover)
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, size: 50, color: Colors.grey.shade600),
                      const SizedBox(height: 8),
                      Text('Tambah Foto Liquid', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            DropdownButtonFormField<String>(
              initialValue: _selectedDevice,
              decoration: InputDecoration(
                labelText: 'Pilih Device / Pod',
                prefixIcon: const Icon(Icons.vape_free),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: _deviceOptions.map((String device) {
                return DropdownMenuItem<String>(
                  value: device,
                  child: Text(device),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedDevice = newValue!;
                  if (_selectedDevice != 'Lainnya') {
                    _customDeviceController.clear();
                  }
                });
              },
            ),

            if (_selectedDevice == 'Lainnya') ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _customDeviceController,
                decoration: InputDecoration(
                  labelText: 'Ketik Nama Device Baru',
                  prefixIcon: const Icon(Icons.edit),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) {
                  if (_selectedDevice == 'Lainnya' && (value == null || value.trim().isEmpty)) {
                    return 'Nama device tidak boleh kosong';
                  }
                  return null;
                },
              ),
            ],

            const SizedBox(height: 16),

            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: ListTile(
                leading: const Icon(Icons.calendar_month),
                title: const Text('Tanggal Mulai Pakai'),
                subtitle: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                trailing: const Icon(Icons.edit_calendar),
                onTap: _pickDate,
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _liquidController,
              decoration: const InputDecoration(labelText: 'Nama Liquid', border: OutlineInputBorder()),
              validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 16),

            const Text('Karakter Rasa (Pilih 1 atau lebih):', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 0.0,
              children: _availableTags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  selectedColor: Theme.of(context).colorScheme.primaryContainer,
                  checkmarkColor: Theme.of(context).colorScheme.primary,
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _resistanceController,
                    decoration: const InputDecoration(labelText: 'Resistance (Ohm)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (value) => value!.isEmpty ? 'Wajib' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _wattageController,
                    decoration: const InputDecoration(labelText: 'Wattage (W)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (value) => value!.isEmpty ? 'Wajib' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Harga (Rp)', border: OutlineInputBorder(), prefixText: 'Rp '),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _airflow,
              decoration: const InputDecoration(labelText: 'Posisi Airflow', border: OutlineInputBorder()),
              items: ['Tertutup Rapat', 'Setengah', 'Terbuka Penuh'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => _airflow = val!),
            ),
            const SizedBox(height: 24),
            Text('Rating Rasa: ${_rating.toStringAsFixed(1)} / 5.0', style: const TextStyle(fontWeight: FontWeight.bold)),
            Slider(
              value: _rating, min: 1.0, max: 5.0, divisions: 40,
              label: _rating.toStringAsFixed(1),
              onChanged: (val) => setState(() => _rating = double.parse(val.toStringAsFixed(1))),
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