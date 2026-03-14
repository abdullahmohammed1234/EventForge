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
          final uploadedUrl = await eventsProvider.uploadEventCoverWeb(bytes, image.name);

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
              SnackBar(content: Text(eventsProvider.error ?? 'Failed to upload image')),
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
          final uploadedUrl = await eventsProvider.uploadEventCover(_coverImage!);

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
              SnackBar(content: Text(eventsProvider.error ?? 'Failed to upload image')),
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
      initialDate: _startDateTime ?? DateTime.now().add(const Duration(days: 1)),
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
            : _tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        coverImageUrl: _coverImageUrl,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event created successfully!')),
        );
        context.pushReplacement('/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(eventsProvider.error ?? 'Failed to create event')),
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
      appBar: AppBar(
        title: const Text('Create Event'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/events'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cover Image Section
              GestureDetector(
                onTap: _isUploadingImage ? null : _pickCoverImage,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: (kIsWeb ? _coverImageBytes != null : _coverImage != null)
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
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
                          ? const Center(child: CircularProgressIndicator())
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
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
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Event Title *',
                  prefixIcon: Icon(Icons.text_fields),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an event title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'City *',
                  prefixIcon: Icon(Icons.location_city),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a city';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address (optional)',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _selectStartDateTime,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Start Date & Time *',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _startDateTime != null
                        ? DateFormat('EEE, MMM d, yyyy • h:mm a')
                            .format(_startDateTime!)
                        : 'Select date and time',
                    style: TextStyle(
                      color:
                          _startDateTime != null ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _selectEndDateTime,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'End Date & Time (optional)',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _endDateTime != null
                        ? DateFormat('EEE, MMM d, yyyy • h:mm a')
                            .format(_endDateTime!)
                        : 'Select date and time',
                    style: TextStyle(
                      color:
                          _endDateTime != null ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _maxAttendeesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Max Attendees (optional)',
                  prefixIcon: Icon(Icons.people),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (optional)',
                  hintText: 'Enter tags separated by commas',
                  prefixIcon: Icon(Icons.tag),
                  border: OutlineInputBorder(),
                ),
              ),
              if (eventsProvider.error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    eventsProvider.error!,
                    style: TextStyle(color: Colors.red[700]),
                  ),
                ),
              ],
              ElevatedButton(
                onPressed:
                    eventsProvider.isLoading ? null : _handleCreateEvent,
                child: eventsProvider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Event'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
