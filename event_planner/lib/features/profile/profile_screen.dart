import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Uint8List? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  int _registeredEventsCount = 0;
  int _savedEventsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    if (user == null) return;

    try {
      final registeredCount = await _getRegisteredEventsCount(user.id);
      final savedCount = await _getSavedEventsCount(user.id);

      if (!mounted) return;

      setState(() {
        _registeredEventsCount = registeredCount;
        _savedEventsCount = savedCount;
      });
    } catch (e) {
      debugPrint('Failed to load profile counts: $e');
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImage = bytes;
      });
    }
  }

  Future<int> _getRegisteredEventsCount(String userId) async {
    // TODO: Replace this with your real registered events query.
    // Example:
    // return await context.read<EventProvider>().getRegisteredEventsCount(userId);
    return 0;
  }

  Future<int> _getSavedEventsCount(String userId) async {
    // TODO: Replace this with your real saved events query.
    // Example:
    // return await context.read<EventProvider>().getSavedEventsCount(userId);
    return 0;
  }

  void _openPersonalInformationPage() {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (context, animation, secondaryAnimation) =>
            PersonalInformationScreen(user: user),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final tween = Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutCubic));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    final displayName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!
        : user?.email ?? 'User';

    final city =
        user?.city?.trim().isNotEmpty == true ? user!.city! : 'Surrey, BC';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F7),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _CircleIconButton(
                            icon: Icons.arrow_back,
                            onTap: () => Navigator.of(context).maybePop(),
                          ),
                          const Expanded(
                            child: Center(
                              child: Text(
                                'Eventforge Account',
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
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFF56EB3),
                                width: 2.5,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 52,
                              backgroundColor: const Color(0xFFB7C6E5),
                              backgroundImage: _selectedImage != null
                                  ? MemoryImage(_selectedImage!)
                                  : null,
                              child: _selectedImage == null
                                  ? const Icon(
                                      Icons.person,
                                      size: 56,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        Positioned(
                          right: -2,
                          bottom: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF56EB3),
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.black, width: 1),
                              ),
                              child: const Icon(
                                Icons.edit,
                                size: 18,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          city,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(
                            value: _registeredEventsCount.toString(),
                            label: 'Events',
                          ),
                          _StatItem(
                            value: _savedEventsCount.toString(),
                            label: 'Saved',
                          ),
                          const _StatItem(
                            // TODO: Replace with real friends count when friends feature is implemented.
                            value: '0',
                            label: 'Friends',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFD0D0D0),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              children: [
                                _ProfileActionRow(
                                  icon: Icons.badge_outlined,
                                  iconBackground: const Color(0xFFC9D9F7),
                                  title: 'Personal information',
                                  subtitle: 'Name, email, phone, address',
                                  onTap: _openPersonalInformationPage,
                                ),
                                const Divider(
                                  height: 1,
                                  indent: 16,
                                  endIndent: 16,
                                ),
                                const _ProfileActionRow(
                                  icon: Icons.auto_awesome_outlined,
                                  iconBackground: Color(0xFFC9D9F7),
                                  title: 'Interests',
                                  subtitle: 'Personalize recommended events',
                                  onTap: null, // TODO: implement Interests page
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              children: [
                                const _ProfileActionRow(
                                  icon: Icons.notifications_active_outlined,
                                  iconBackground: Color(0xFFF5D58E),
                                  title: 'Safety Contact',
                                  subtitle: 'Manage safety features',
                                  onTap:
                                      null, // TODO: implement Safety Contact page
                                ),
                                const Divider(
                                  height: 1,
                                  indent: 16,
                                  endIndent: 16,
                                ),
                                const _ProfileActionRow(
                                  icon: Icons.notifications_none,
                                  iconBackground: Color(0xFFF5D58E),
                                  title: 'Notifications',
                                  subtitle: 'Push, event reminders',
                                  onTap:
                                      null, // TODO: implement Notifications page
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              child: SizedBox(
                width: 140,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF56EB3),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: const BorderSide(color: Colors.black, width: 1),
                    ),
                  ),
                  onPressed: () async {
                    await authProvider.logout();
                    if (mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/login',
                        (route) => false,
                      );
                    }
                  },
                  child: const Text(
                    'Log out',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
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

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFFF56EB3),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}

class _ProfileActionRow extends StatelessWidget {
  final IconData icon;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ProfileActionRow({
    required this.icon,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.black38,
              ),
            ],
          ),
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

class PersonalInformationScreen extends StatelessWidget {
  final dynamic user;

  const PersonalInformationScreen({super.key, required this.user});

  void _openEditFieldSheet(
    BuildContext context, {
    required String title,
    required String label,
    required String initialValue,
    required Future<void> Function(String value) onSave,
  }) {
    final controller = TextEditingController(text: initialValue);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF3F3F7),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _EditFieldSheet(
          title: title,
          label: label,
          controller: controller,
          onSave: () async {
            final value = controller.text.trim();
            if (value.isEmpty) return;

            await onSave(value);

            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.user ?? user;

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
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Personal Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 42),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    _InfoRow(
                      label: 'Name',
                      value: currentUser?.displayName ?? 'Not set',
                      isEditable: true,
                      onTap: () => _openEditFieldSheet(
                        context,
                        title: 'Enter Name',
                        label: 'Name',
                        initialValue: currentUser?.displayName ?? '',
                        onSave: (value) async {
                          await context.read<AuthProvider>().updateProfile(
                                displayName: value,
                              );
                        },
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFD7D7DD)),
                    _InfoRow(
                      label: 'Email',
                      value: currentUser?.email ?? 'Not set',
                      isEditable: false, // display only
                      onTap: null,
                    ),
                    const Divider(height: 1, color: Color(0xFFD7D7DD)),
                    _InfoRow(
                      label: 'City',
                      value: currentUser?.city ?? 'Not set',
                      isEditable: true,
                      onTap: () => _openEditFieldSheet(
                        context,
                        title: 'Enter City',
                        label: 'City',
                        initialValue: currentUser?.city ?? '',
                        onSave: (value) async {
                          await context.read<AuthProvider>().updateProfile(
                                city: value,
                              );
                        },
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFD7D7DD)),
                    _InfoRow(
                      label: 'User ID',
                      value: currentUser?.id ?? 'Not set',
                      isEditable: false, // display only
                      onTap: null,
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              child: SizedBox(
                width: 140,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF56EB3),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: const BorderSide(color: Colors.black, width: 1),
                    ),
                  ),
                  onPressed: () async {
                    await authProvider.logout();
                    if (context.mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/login',
                        (route) => false,
                      );
                    }
                  },
                  child: const Text(
                    'Log out',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isEditable;
  final VoidCallback? onTap;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.isEditable,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rowChild = Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          if (isEditable)
            const Padding(
              padding: EdgeInsets.only(left: 12, top: 2),
              child: Text(
                'edit >',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFFF56EB3),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );

    if (!isEditable) return rowChild;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: rowChild,
    );
  }
}

class _EditFieldSheet extends StatefulWidget {
  final String title;
  final String label;
  final TextEditingController controller;
  final Future<void> Function() onSave;

  const _EditFieldSheet({
    required this.title,
    required this.label,
    required this.controller,
    required this.onSave,
  });

  @override
  State<_EditFieldSheet> createState() => _EditFieldSheetState();
}

class _EditFieldSheetState extends State<_EditFieldSheet> {
  final FocusNode _focusNode = FocusNode();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.onSave();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save changes: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: 410,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _CircleIconButton(
                    icon: Icons.close,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _isSaving ? null : _handleSave,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF56EB3),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 1),
                      ),
                      child: _isSaving
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.black,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.check,
                              color: Colors.black,
                              size: 22,
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 80),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _handleSave(),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    labelText: widget.label,
                    labelStyle: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
