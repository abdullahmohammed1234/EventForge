import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'events_provider.dart';
import 'widgets/dynamic_theme_controller.dart';
import 'widgets/category_pill.dart';
import 'widgets/overlapping_avatars.dart';
import 'widgets/location_preview_card.dart';
import 'widgets/bottom_floating_nav.dart';

/// Category-based image provider helper
class CategoryImageHelper {
  static final Map<String, List<Color>> categoryGradients = {
    'music': [const Color(0xFF667eea), const Color(0xFF764ba2)],
    'sports': [const Color(0xFF11998e), const Color(0xFF38ef7d)],
    'arts': [const Color(0xFFf093fb), const Color(0xFFf5576c)],
    'food': [const Color(0xFFff9966), const Color(0xFFff5e62)],
    'technology': [const Color(0xFF00c6ff), const Color(0xFF0072ff)],
    'business': [const Color(0xFF434343), const Color(0xFF000000)],
    'social': [const Color(0xFFff758c), const Color(0xFFff7eb3)],
    'outdoor': [const Color(0xFF56ab2f), const Color(0xFFa8e063)],
    'other': [const Color(0xFF6366f1), const Color(0xFF8b5cf6)],
  };

  static List<Color> getCategoryGradient(String category) {
    return categoryGradients[category.toLowerCase()] ?? 
        categoryGradients['other']!;
  }

  static Color getCategoryAccent(String category) {
    final gradient = getCategoryGradient(category);
    return gradient[0];
  }
}

/// Production-ready Event Detail Page with dynamic image-based theming
/// Uses Stack-based layout with no Slivers or AppBar
class EventDetailPage extends StatefulWidget {
  final String eventId;

  const EventDetailPage({super.key, required this.eventId});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final DynamicThemeController _themeController = DynamicThemeController();
  bool _isDescriptionExpanded = false;
  int _currentNavIndex = 0;

  Future<void> _openGoogleMaps(Event event) async {
    String query;
    if (event.latitude != null && event.longitude != null &&
        event.latitude != 0 && event.longitude != 0) {
      query = '${event.latitude},${event.longitude}';
    } else {
      final locationString = event.address ?? event.city;
      if (locationString.isNotEmpty) {
        query = Uri.encodeComponent(locationString);
      } else {
        return;
      }
    }
    
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _getPublicTransit(Event event) async {
    String query;
    if (event.latitude != null && event.longitude != null &&
        event.latitude != 0 && event.longitude != 0) {
      query = '${event.latitude},${event.longitude}';
    } else {
      final locationString = event.address ?? event.city;
      if (locationString.isNotEmpty) {
        query = Uri.encodeComponent(locationString);
      } else {
        return;
      }
    }
    
    final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$query&travelmode=transit');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    // Load event and extract colors
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEvent();
      _animationController.forward();
    });
  }

  Future<void> _loadEvent() async {
    final eventsProvider = context.read<EventsProvider>();
    await eventsProvider.getEventById(widget.eventId);
    
    final event = eventsProvider.currentEvent;
    if (event != null) {
      // Extract colors based on category
      final categoryColor = CategoryImageHelper.getCategoryAccent(event.category);
      _themeController.extractColorsFromGradient(categoryColor);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _themeController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }

  void _shareEvent(Event event) {
    final eventDetails = '''
Check out this event!

${event.title}
📍 ${event.city}
📅 ${DateFormat('MMM d, yyyy').format(event.startTime)}
🕕 ${DateFormat('h:mm a').format(event.startTime)}

${event.description ?? ''}

Join me at this event!
''';
    Share.share(eventDetails, subject: event.title);
  }

  void _handleNavTap(int index) {
    switch (index) {
      case 0: // Home
        context.pushReplacement('/home');
        break;
      case 1: // Search
        context.push('/search');
        break;
      case 2: // Create
        context.push('/events/create');
        break;
      case 3: // Saved/My Events
        context.push('/my-events');
        break;
      case 4: // Profile
        context.push('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventsProvider = context.watch<EventsProvider>();
    final event = eventsProvider.currentEvent;
    final screenHeight = MediaQuery.of(context).size.height;
    // Use 55% for sheet to ensure bottom nav is visible and button is reachable
    final sheetHeight = screenHeight * 0.55;

    return ChangeNotifierProvider.value(
      value: _themeController,
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            // 1. Background Image (Fullscreen) - using category-based gradient
            Positioned.fill(
              child: event != null
                  ? Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: CategoryImageHelper.getCategoryGradient(event.category),
                        ),
                      ),
                    )
                  : Container(color: Colors.grey[900]),
            ),

            // 2. Gradient Overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.85),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),

            // 3. Top Controls - Positioned at top with proper safe area
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: _buildTopControls(event),
                ),
              ),
            ),

            // 4. Positioned Bottom Sheet
            if (event != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildBottomSheet(event, sheetHeight),
                  ),
                ),
              ),

            // Loading state
            if (eventsProvider.isLoading)
              const Positioned.fill(
                child: ColoredBox(
                  color: Colors.black54,
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              ),

            // 5. Bottom Floating Nav Bar - Positioned above sheet
            Positioned(
              left: 16,
              right: 16,
              bottom: 24, // Raised up from 16 to give more clearance
              child: BottomFloatingNav(
                currentIndex: _currentNavIndex,
                onTap: (index) {
                  setState(() => _currentNavIndex = index);
                  _handleNavTap(index);
                },
                accentColor: _themeController.accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build top controls row with back button, category pill, and share button
  Widget _buildTopControls(Event? event) {
    return Stack(
      children: [
        // Left: Back button
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: Center(
            child: _buildCircularButton(
              icon: Icons.arrow_back,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
        ),

        // Center: Category Pill
        Center(
          child: event != null
              ? Consumer<DynamicThemeController>(
                  builder: (context, theme, _) {
                    return CategoryPill(
                      category: event.category,
                      backgroundColor: theme.isLoading
                          ? DynamicThemeController.defaultAccent
                          : theme.lightVibrantColor,
                    );
                  },
                )
              : const SizedBox.shrink(),
        ),

        // Right: Share button
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: Center(
            child: _buildCircularButton(
              icon: Icons.share,
              onTap: () {
                // Share event
                if (event != null) {
                  _shareEvent(event);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Build circular translucent button
  Widget _buildCircularButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }

  /// Build the floating bottom sheet with event details
  Widget _buildBottomSheet(Event event, double sheetHeight) {
    return Consumer<DynamicThemeController>(
      builder: (context, theme, _) {
        final tintedSurface = theme.getTintedSurfaceColor();
        final shadowColor = theme.getShadowColor();
        
        return Container(
          height: sheetHeight,
          decoration: BoxDecoration(
            color: tintedSurface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 30,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 100), // Extra bottom padding for button accessibility
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Event Title
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle (Venue)
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.city,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Info Row (Date / Time / Going)
                  _buildInfoRow(event, theme),
                  const SizedBox(height: 20),

                  // Location Section with Image Preview
                  _buildLocationSection(event, theme),
                  const SizedBox(height: 20),

                  // Hosted By
                  _buildHostedBySection(event, theme),
                  const SizedBox(height: 16),

                  // People Going with overlapping avatars
                  _buildPeopleGoingSection(event, theme),
                  const SizedBox(height: 20),

                  // About Event (Expandable)
                  if (event.description != null && event.description!.isNotEmpty)
                    _buildAboutSection(event, theme),
                  
                  const SizedBox(height: 24),

                  // Primary CTA Button
                  _buildCTAButton(event, theme),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build info row with Date, Time, and Going count
  Widget _buildInfoRow(Event event, DynamicThemeController theme) {
    return Row(
      children: [
        _buildInfoChip(
          icon: Icons.calendar_today,
          label: DateFormat('MMM d').format(event.startTime),
          theme: theme,
        ),
        const SizedBox(width: 12),
        _buildInfoChip(
          icon: Icons.access_time,
          label: _formatTime(event.startTime),
          theme: theme,
        ),
        const SizedBox(width: 12),
        _buildInfoChip(
          icon: Icons.people_outline,
          label: '${event.currentAttendees} going',
          theme: theme,
        ),
      ],
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required DynamicThemeController theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.mutedColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.dominantColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: theme.dominantColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Build location section with preview card
  Widget _buildLocationSection(Event event, DynamicThemeController theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        LocationPreviewCard(
          locationName: event.city,
          address: event.address ?? 'Address not specified',
          imageUrl: null,
          accentColor: theme.dominantColor,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _openGoogleMaps(event),
                icon: const Icon(Icons.map),
                label: const Text('Open Maps'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _getPublicTransit(event),
                icon: const Icon(Icons.directions_transit),
                label: const Text('Public Transit'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build hosted by section
  Widget _buildHostedBySection(Event event, DynamicThemeController theme) {
    final organizerName = event.creatorName ?? 'Event Organizer';
    
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.dominantColor,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Center(
            child: Text(
              organizerName.isNotEmpty ? organizerName[0].toUpperCase() : 'O',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hosted by',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
            Text(
              organizerName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build people going section with overlapping avatars
  Widget _buildPeopleGoingSection(Event event, DynamicThemeController theme) {
    final spotsLeft = event.maxAttendees != null
        ? event.maxAttendees! - event.currentAttendees
        : null;
    
    // Generate mock avatar URLs for demo
    final mockAvatars = List.generate(
      4,
      (i) => 'https://i.pravatar.cc/150?img=${i + 10}',
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'People Going',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            OverlappingAvatars(
              avatarUrls: mockAvatars,
              totalCount: event.currentAttendees,
              maxVisible: 4,
              borderColor: theme.dominantColor,
            ),
          ],
        ),
        if (spotsLeft != null && spotsLeft > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$spotsLeft spots left',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.green,
              ),
            ),
          ),
      ],
    );
  }

  /// Build expandable about section
  Widget _buildAboutSection(Event event, DynamicThemeController theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'About',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.description!,
                maxLines: _isDescriptionExpanded ? null : 4,
                overflow: _isDescriptionExpanded ? null : TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.grey[700],
                ),
              ),
              if (event.description!.length > 100)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isDescriptionExpanded = !_isDescriptionExpanded;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _isDescriptionExpanded ? 'Show less' : 'Read more',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.dominantColor,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  /// Build CTA button with scale animation and glow
  Widget _buildCTAButton(Event event, DynamicThemeController theme) {
    return _AnimatedCTAButton(
      label: event.isUserRegistered ? 'View Ticket' : 'Get Tickets',
      accentColor: theme.accentColor,
      onTap: () async {
        if (event.isUserRegistered) {
          // Navigate to ticket screen - goes to event planning with QR code
          context.push('/events/${event.id}/ticket');
        } else {
          // Register for event
          final eventsProvider = context.read<EventsProvider>();
          final success = await eventsProvider.registerForEvent(event.id);
          
          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Successfully registered for event!'),
                backgroundColor: theme.accentColor,
              ),
            );
            // Refresh event to get updated registration status
            await eventsProvider.getEventById(event.id);
          } else if (mounted && eventsProvider.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(eventsProvider.error ?? 'Failed to register'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
    );
  }
}

/// Animated CTA button with scale effect and glow
class _AnimatedCTAButton extends StatefulWidget {
  final String label;
  final Color accentColor;
  final VoidCallback? onTap;

  const _AnimatedCTAButton({
    required this.label,
    required this.accentColor,
    this.onTap,
  });

  @override
  State<_AnimatedCTAButton> createState() => _AnimatedCTAButtonState();
}

class _AnimatedCTAButtonState extends State<_AnimatedCTAButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: widget.accentColor,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: widget.accentColor.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
