import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../core/constants/app_constants.dart';
import '../core/providers/app_providers.dart';
import '../core/utils/emergency_formatters.dart';
import 'sos_preview_screen.dart';

class CreateSosScreen extends ConsumerStatefulWidget {
  const CreateSosScreen({super.key});

  static const routeName = '/create-sos';

  @override
  ConsumerState<CreateSosScreen> createState() => _CreateSosScreenState();
}

class _CreateSosScreenState extends ConsumerState<CreateSosScreen> {
  final _formKey = GlobalKey<FormState>();
  final _victimsController = TextEditingController(text: '1');
  final _descriptionController = TextEditingController();
  String _type = AppConstants.emergencyTypes.first;
  bool _medicalEmergency = false;
  double _latitude = 0;
  double _longitude = 0;
  String? _photoPath;
  bool _loadingGps = false;
  bool _buildingPreview = false;

  @override
  void dispose() {
    _victimsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _captureGps() async {
    setState(() => _loadingGps = true);
    final location = await ref.read(appControllerProvider).getCurrentLocation();
    if (!mounted) {
      return;
    }
    setState(() {
      _loadingGps = false;
      if (location != null) {
        _latitude = location.latitude;
        _longitude = location.longitude;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(location == null ? 'GPS unavailable. You can still send SOS.' : 'GPS captured.')),
    );
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 72,
      maxWidth: 1600,
    );
    if (!mounted || picked == null) {
      return;
    }
    setState(() => _photoPath = picked.path);
  }

  Future<void> _preview() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _buildingPreview = true);
    final message = await ref.read(appControllerProvider).draftEmergency(
          type: _type,
          victims: int.parse(_victimsController.text.trim()),
          description: _descriptionController.text.trim(),
          medicalEmergency: _medicalEmergency,
          latitude: _latitude,
          longitude: _longitude,
          photoPath: _photoPath,
        );
    if (!mounted) {
      return;
    }
    setState(() => _buildingPreview = false);
    Navigator.of(context).pushNamed(SosPreviewScreen.routeName, arguments: message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create SOS')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Emergency type', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _type,
                items: AppConstants.emergencyTypes
                    .map((type) => DropdownMenuItem(value: type, child: Text(readableEmergencyType(type))))
                    .toList(),
                onChanged: (value) => setState(() => _type = value ?? _type),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _victimsController,
                decoration: const InputDecoration(labelText: 'Victim count'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  final victims = int.tryParse(value ?? '');
                  if (victims == null || victims < 0) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descriptionController,
                minLines: 4,
                maxLines: 7,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Example: Multiple people trapped, need ambulance',
                ),
                validator: (value) {
                  if ((value ?? '').trim().length < 3) {
                    return 'Describe the emergency';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _medicalEmergency,
                onChanged: (value) => setState(() => _medicalEmergency = value),
                title: const Text('Medical emergency'),
                subtitle: const Text('Prioritizes ambulance or urgent care signals.'),
              ),
              const SizedBox(height: 10),
              _InfoRow(
                icon: Icons.my_location_outlined,
                title: 'Current GPS',
                value: '$_latitude, $_longitude',
                action: TextButton.icon(
                  onPressed: _loadingGps ? null : _captureGps,
                  icon: _loadingGps
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.gps_fixed_outlined),
                  label: const Text('CAPTURE'),
                ),
              ),
              const SizedBox(height: 10),
              _InfoRow(
                icon: Icons.photo_camera_outlined,
                title: 'Optional photo',
                value: _photoPath == null ? 'No photo attached' : 'Photo attached',
                action: TextButton.icon(
                  onPressed: _pickPhoto,
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: const Text('ADD'),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _buildingPreview ? null : _preview,
                icon: _buildingPreview
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.preview_outlined),
                label: const Text('PREVIEW SOS'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.action,
  });

  final IconData icon;
  final String title;
  final String value;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  Text(value, maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            action,
          ],
        ),
      ),
    );
  }
}
