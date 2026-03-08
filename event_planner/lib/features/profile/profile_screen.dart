import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Uint8List? _selectedImage;
  final ImagePicker _picker = ImagePicker();

Future<void> _pickImage() async {
  final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
  if (image != null) {
    final bytes = await image.readAsBytes();
    setState(() {
      _selectedImage = bytes;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              GestureDetector(
  onTap: _pickImage,
  child: CircleAvatar(
    radius: 50,
    backgroundColor: Colors.blue,
    backgroundImage: _selectedImage != null ? MemoryImage(_selectedImage!) : null,
    child: _selectedImage == null
        ? const Icon(Icons.person, size: 60, color: Colors.white)
        : null,
  ),
),
              const SizedBox(height: 16),
              Text(
                user?.displayName ?? user?.email ?? 'User',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (user?.displayName != null) ...[
                const SizedBox(height: 8),
                Text(
                  user!.email,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
              if (user?.city != null && user!.city!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.location_city,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      user.city!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 32),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.email),
                        title: const Text('Email'),
                        subtitle: Text(user?.email ?? ''),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.badge),
                        title: const Text('User ID'),
                        subtitle: Text(
                          user?.id ?? '',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      if (user?.createdAt != null) ...[
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.calendar_today),
                          title: const Text('Member Since'),
                          subtitle: Text(
                            _formatDate(user!.createdAt!),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _showEditProfileDialog(context, user),
                icon: const Icon(Icons.edit),
                label: const Text('Edit Profile'),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => context.push('/my-events'),
                icon: const Icon(Icons.event),
                label: const Text('My Events'),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    await authProvider.logout();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout),
                      SizedBox(width: 8),
                      Text('Logout'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Event Planner v1.0.0',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  void _showEditProfileDialog(BuildContext context, user) {
  final nameController = TextEditingController(text: user?.displayName ?? '');
  final cityController = TextEditingController(text: user?.city ?? '');

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Edit Profile'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: cityController,
            decoration: const InputDecoration(
              labelText: 'City',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
  onPressed: () async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.updateProfile(
      displayName: nameController.text,
      city: cityController.text,
    );
    if (context.mounted) {
      Navigator.pop(context);
    }
  },
  child: const Text('Save'),
),
      ],
    ),
  );
}
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.month}/${date.day}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}