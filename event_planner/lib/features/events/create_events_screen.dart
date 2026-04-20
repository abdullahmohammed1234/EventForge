import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'events_provider.dart';
import '../../core/config/app_config.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _maxAttendeesController = TextEditingController();
  final _tagsController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  File? _coverImage;
  Uint8List? _coverImageBytes;
  String? _coverImageUrl;
  bool _isUploadingImage = false;

  String _selectedCategory = 'other';
  DateTime? _startDateTime;
  DateTime? _endDateTime;

  final List<String> _categories = [
    'music',
    'sports',
    'arts',
    'food',
    'technology',
    'business',
    'social',
    'outdoor',
    'other',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _maxAttendeesController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickCoverImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        if (kIsWeb) {
          // On web, read the image as bytes
          final bytes = await image.readAsBytes();
          setState(() {
            _coverImageBytes = bytes;
            _isUploadingImage = true;
          });

          // Upload the image first
          final eventsProvider = context.read<EventsProvider>();
          final uploadedUrl =
              await eventsProvider.uploadEventCoverWeb(bytes, image.name);

          setState(() {
            _isUploadingImage = false;
            if (uploadedUrl != null) {
              _coverImageUrl = uploadedUrl;
            }
          });

          if (mounted && uploadedUrl != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cover image uploaded!')),
            );
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text(eventsProvider.error ?? 'Failed to upload image')),
            );
          }
        } else {
          // On native platforms
          setState(() {
            _coverImage = File(image.path);
            _isUploadingImage = true;
          });

          // Upload the image first
          final eventsProvider = context.read<EventsProvider>();
          final uploadedUrl =
              await eventsProvider.uploadEventCover(_coverImage!);

          setState(() {
            _isUploadingImage = false;
            if (uploadedUrl != null) {
              _coverImageUrl = uploadedUrl;
            }
          });

          if (mounted && uploadedUrl != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cover image uploaded!')),
            );
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text(eventsProvider.error ?? 'Failed to upload image')),
            );
          }
        }
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _selectStartDateTime() async {
    final now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked != null) {
      final TimeOfDay? timePicked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (timePicked != null) {
        setState(() {
          _startDateTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            timePicked.hour,
            timePicked.minute,
          );
        });
      }
    }
  }

  Future<void> _selectEndDateTime() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _startDateTime ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: _startDateTime ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      final TimeOfDay? timePicked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (timePicked != null) {
        setState(() {
          _endDateTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            timePicked.hour,
            timePicked.minute,
          );
        });
      }
    }
  }

  Future<void> _handleCreateEvent() async {
    if (_formKey.currentState!.validate()) {
      if (_startDateTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a start date and time')),
        );
        return;
      }

      final eventsProvider = context.read<EventsProvider>();

      final success = await eventsProvider.createEvent(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        category: _selectedCategory,
        city: _cityController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        startTime: _startDateTime!,
        endTime: _endDateTime,
        maxAttendees: _maxAttendeesController.text.isEmpty
            ? null
            : int.parse(_maxAttendeesController.text),
        tags: _tagsController.text.isEmpty
            ? []
            : _tagsController.text
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList(),
        coverImageUrl: _coverImageUrl != null && _coverImageUrl!.isNotEmpty
            ? (_coverImageUrl!.startsWith('http://') ||
                    _coverImageUrl!.startsWith('https://')
                ? _coverImageUrl! // Keep full Cloudinary URL
                : _coverImageUrl!
                    .replaceAll(AppConfig.baseUrl, '')) // Strip local URL
            : null,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event created successfully!')),
        );
        context.pushReplacement('/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(eventsProvider.error ?? 'Failed to create event')),
        );
      }
    }
  }

  String _getFullImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return '';
    }
    if (imageUrl.startsWith('http')) {
      return imageUrl;
    }
    return '${AppConfig.apiBaseUrl.replaceAll('/api', '')}$imageUrl';
  }

  @override
  Widget build(BuildContext context) {
    final eventsProvider = context.watch<EventsProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F7),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _CircleIconButton(
                    icon: Icons.arrow_back,
                    onTap: () => context.go('/events'),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Create Event',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GestureDetector(
                        onTap: _isUploadingImage ? null : _pickCoverImage,
                        child: Container(
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.black, width: 1),
                          ),
                          child: (kIsWeb
                                  ? _coverImageBytes != null
                                  : _coverImage != null)
                              ? Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: kIsWeb
                                          ? Image.memory(
                                              _coverImageBytes!,
                                              fit: BoxFit.cover,
                                            )
                                          : Image.file(
                                              _coverImage!,
                                              fit: BoxFit.cover,
                                            ),
                                    ),
                                    if (_isUploadingImage)
                                      Container(
                                        color: Colors.black.withOpacity(0.3),
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                  ],
                                )
                              : _isUploadingImage
                                  ? const Center(
                                      child: CircularProgressIndicator())
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate,
                                          size: 48,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Add Cover Image',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _StyledTextField(
                        controller: _titleController,
                        labelText: 'Event Title *',
                        prefixIcon: Icons.text_fields,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an event title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _StyledDropdown(
                        value: _selectedCategory,
                        labelText: 'Category *',
                        prefixIcon: Icons.category,
                        items: _categories,
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      _StyledTextField(
                        controller: _cityController,
                        labelText: 'City *',
                        prefixIcon: Icons.location_city,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a city';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _StyledTextField(
                        controller: _addressController,
                        labelText: 'Address (optional)',
                        prefixIcon: Icons.location_on,
                      ),
                      const SizedBox(height: 14),
                      _StyledDateField(
                        value: _startDateTime,
                        labelText: 'Start Date & Time *',
                        prefixIcon: Icons.calendar_today,
                        onTap: _selectStartDateTime,
                        hintText: 'Select date and time',
                      ),
                      const SizedBox(height: 14),
                      _StyledDateField(
                        value: _endDateTime,
                        labelText: 'End Date & Time (optional)',
                        prefixIcon: Icons.calendar_today,
                        onTap: _selectEndDateTime,
                        hintText: 'Select date and time',
                      ),
                      const SizedBox(height: 14),
                      _StyledTextField(
                        controller: _descriptionController,
                        labelText: 'Description (optional)',
                        prefixIcon: Icons.description,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 14),
                      _StyledTextField(
                        controller: _maxAttendeesController,
                        labelText: 'Max Attendees (optional)',
                        prefixIcon: Icons.people,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 14),
                      _StyledTextField(
                        controller: _tagsController,
                        labelText: 'Tags (optional)',
                        prefixIcon: Icons.tag,
                        hintText: 'Enter tags separated by commas',
                      ),
                      if (eventsProvider.error != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            eventsProvider.error!,
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF56EB3),
                            foregroundColor: Colors.black,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                              side: const BorderSide(
                                  color: Colors.black, width: 1),
                            ),
                          ),
                          onPressed: eventsProvider.isLoading
                              ? null
                              : _handleCreateEvent,
                          child: eventsProvider.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.black,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Create Event',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(
          color: Color(0xFFF7A4CD),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final IconData prefixIcon;
  final String? hintText;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _StyledTextField({
    required this.controller,
    required this.labelText,
    required this.prefixIcon,
    this.hintText,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          prefixIcon: Icon(prefixIcon, color: Colors.black54),
          labelStyle: const TextStyle(color: Colors.black54),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }
}

class _StyledDropdown extends StatelessWidget {
  final String value;
  final String labelText;
  final IconData prefixIcon;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _StyledDropdown({
    required this.value,
    required this.labelText,
    required this.prefixIcon,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: labelText,
          prefixIcon: Icon(prefixIcon, color: Colors.black54),
          labelStyle: const TextStyle(color: Colors.black54),
          border: InputBorder.none,
        ),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item.toUpperCase()),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _StyledDateField extends StatelessWidget {
  final DateTime? value;
  final String labelText;
  final IconData prefixIcon;
  final VoidCallback onTap;
  final String hintText;

  const _StyledDateField({
    required this.value,
    required this.labelText,
    required this.prefixIcon,
    required this.onTap,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Icon(prefixIcon, color: Colors.black54),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value != null
                    ? DateFormat('EEE, MMM d, yyyy • h:mm a').format(value!)
                    : hintText,
                style: TextStyle(
                  color: value != null ? Colors.black : Colors.black54,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
