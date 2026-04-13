import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../core/api/maps_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/config/app_config.dart';
import 'events_provider.dart';
import 'widgets/dynamic_theme_controller.dart';
import 'widgets/category_pill.dart';
import 'widgets/overlapping_avatars.dart';

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
  bool _isFavorite = false;

  Future<void> _openGoogleMaps(Event event) async {
    final String address = event.address ?? event.location?.name ?? '';
    final String city = event.city ?? '';
    
    if (address.isEmpty && city.isEmpty) {
      return;
    }
    
    final String searchQuery = address.isNotEmpty 
        ? (city.isNotEmpty ? '$address, $city' : address)
        : city;
    
    final result = await MapsService.getOrsSearchUrl(address: address, city: city);
    if (result != null && result['url'] != null) {
      final url = Uri.parse(result['url'] as String);
      try {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } catch (e) {
        debugPrint('Error opening maps: $e');
      }
    }
  }

  Future<void> _openEmail(String email) async {
    final url = Uri.parse('mailto:$email');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _openPhone(String phone) async {
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
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
      // Check if event has an image - use image for theme if available
      if (event.coverImageUrl != null && event.coverImageUrl!.isNotEmpty) {
        // Build the full URL if needed
        String coverImageUrl = event.coverImageUrl!;
        // Extract colors from the event image
        await _themeController.extractColorsFromImage(NetworkImage(coverImageUrl));
      } else {
        // Fallback to category-based colors if no image
        final categoryColor = CategoryImageHelper.getCategoryAccent(event.category);
        _themeController.extractColorsFromGradient(categoryColor);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _themeController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEEE, MMMM d, yyyy').format(date);
  }

  String _formatTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }

  String _formatTimeRange(DateTime start, DateTime? end) {
    final startTime = _formatTime(start);
    if (end != null) {
      return '$startTime - ${_formatTime(end)}';
    }
    return startTime;
  }

  void _shareEvent(Event event) {
    final eventDetails = '''
Check out this event!

${event.title}
📍 ${event.location?.name ?? event.city}
📅 ${_formatDate(event.startTime)}
🕕 ${_formatTimeRange(event.startTime, event.endTime)}

${event.description ?? ''}

Join me at this event!
''';
    Share.share(eventDetails, subject: event.title);
  }


  @override
  Widget build(BuildContext context) {
    final eventsProvider = context.watch<EventsProvider>();
    final event = eventsProvider.currentEvent;
    final screenHeight = MediaQuery.of(context).size.height;
    // Use 55% for sheet height
    final sheetHeight = screenHeight * 0.55;

    return ChangeNotifierProvider.value(
      value: _themeController,
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            // 1. Background Image or Category Gradient
            Positioned.fill(
              child: event != null
                  ? _buildHeroImage(event)
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

          ],
        ),
      ),
    );
  }

  /// Build hero image section
  Widget _buildHeroImage(Event event) {
    if (event.coverImageUrl != null && event.coverImageUrl!.isNotEmpty) {
      // Convert relative URL to absolute URL
      String coverImageUrl = event.coverImageUrl!;
      return CachedNetworkImage(
        imageUrl: coverImageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: CategoryImageHelper.getCategoryGradient(event.category),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: CategoryImageHelper.getCategoryGradient(event.category),
            ),
          ),
        ),
      );
    }
    // Fallback to gradient
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: CategoryImageHelper.getCategoryGradient(event.category),
        ),
      ),
    );
  }

  /// Build top controls row with back button, category pill, and action buttons
  Widget _buildTopControls(Event? event) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left: Back button
        _buildCircularButton(
          icon: Icons.arrow_back,
          onTap: () => Navigator.of(context).pop(),
        ),

        // Center: Category Pill (floating over hero)
        if (event != null)
          Consumer<DynamicThemeController>(
            builder: (context, theme, _) {
              return CategoryPill(
                category: event.category,
                backgroundColor: theme.isLoading
                    ? DynamicThemeController.defaultAccent
                    : theme.lightVibrantColor,
              );
            },
          )
        else
          const SizedBox.shrink(),

        // Right: Favorite + Share buttons
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCircularButton(
              icon: Icons.share,
              onTap: () {
                if (event != null) {
                  _shareEvent(event);
                }
              },
            ),
          ],
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

                  // Event Title Section
                  _buildTitleSection(event, theme),
                  const SizedBox(height: 16),

                  // Date & Time Section
                  _buildDateTimeSection(event, theme),
                  const SizedBox(height: 16),

                  // Location Section
                  _buildLocationSection(event, theme),
                  const SizedBox(height: 20),

                  // Hosted By Section
                  _buildHostedBySection(event, theme),
                  const SizedBox(height: 16),

                  // Contact Section
                  if (event.contact != null && 
                      (event.contact!.phone != null || event.contact!.email != null))
                    _buildContactSection(event, theme),

                  // Attendees Preview
                  _buildAttendeesSection(event, theme),
                  const SizedBox(height: 20),

                  // About Event Section
                  if (event.description != null && event.description!.isNotEmpty)
                    _buildAboutSection(event, theme),
                  
                  // What to Expect Section
                  if (event.highlights.isNotEmpty)
                    _buildWhatToExpectSection(event, theme),
                  
                  // Tickets & Pricing Section
                  _buildTicketsSection(event, theme),
                  
                  const SizedBox(height: 24),

                  // Primary CTA Button
                  _buildCTAButton(event, theme),
                  
                  // Secondary Action (Cancel/Unregister)
                  if (event.isUserRegistered || event.isUserOrganizer == true)
                    _buildSecondaryButton(event, theme),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build title section with tags
  Widget _buildTitleSection(Event event, DynamicThemeController theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Event Title
        Text(
          event.title,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        
        // Tags
        if (event.tags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: event.tags.map((tag) => _buildTag(tag, theme)).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildTag(String tag, DynamicThemeController theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.dominantColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '#$tag',
        style: TextStyle(
          fontSize: 12,
          color: theme.dominantColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Build date and time section
  Widget _buildDateTimeSection(Event event, DynamicThemeController theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.mutedColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.accentColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.calendar_today,
              color: theme.accentColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date & Time',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(event.startTime),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTimeRange(event.startTime, event.endTime),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build location section with preview card
  Widget _buildLocationSection(Event event, DynamicThemeController theme) {
    final String locationName = event.location?.name ?? event.city;
    final String address = event.location?.address ?? event.address ?? 'Address not specified';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.mutedColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.location_on,
                  color: theme.accentColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locationName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      address,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _openGoogleMaps(event),
            icon: const Icon(Icons.map),
            label: const Text('View on Map'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  /// Build hosted by section
  Widget _buildHostedBySection(Event event, DynamicThemeController theme) {
    final organizerName = event.organizer?.name ?? event.creatorName ?? 'Event Organizer';
    final organizerType = event.organizer?.type;
    final organizerAvatar = event.organizer?.avatarUrl;
    
    // Convert relative URL to absolute URL
    String organizerAvatarUrl = organizerAvatar ?? '';
    if (organizerAvatar != null && !organizerAvatar.startsWith('data:image') && !organizerAvatar.startsWith('http')) {
      organizerAvatarUrl = '${AppConfig.apiBaseUrl.replaceAll('/api', '')}$organizerAvatar';
    }
    
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: theme.dominantColor,
            borderRadius: BorderRadius.circular(24),
            image: organizerAvatar != null && organizerAvatar.isNotEmpty
                ? DecorationImage(
                    image: CachedNetworkImageProvider(organizerAvatarUrl),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: organizerAvatar == null || organizerAvatar.isEmpty
              ? Center(
                  child: Text(
                    organizerName.isNotEmpty ? organizerName[0].toUpperCase() : 'O',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
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
              if (organizerType != null)
                Text(
                  organizerType,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build contact section
  Widget _buildContactSection(Event event, DynamicThemeController theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contact',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.mutedColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              if (event.contact?.phone != null)
                _buildContactRow(
                  icon: Icons.phone,
                  label: event.contact!.phone!,
                  onTap: () => _openPhone(event.contact!.phone!),
                  theme: theme,
                ),
              if (event.contact?.email != null) ...[
                if (event.contact?.phone != null)
                  const SizedBox(height: 12),
                _buildContactRow(
                  icon: Icons.email,
                  label: event.contact!.email!,
                  onTap: () => _openEmail(event.contact!.email!),
                  theme: theme,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildContactRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required DynamicThemeController theme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.accentColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: theme.accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: theme.accentColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey[400]),
        ],
      ),
    );
  }

  /// Build attendees section
  Widget _buildAttendeesSection(Event event, DynamicThemeController theme) {
    // Get attendee avatars from event.attendees
    final attendeeAvatars = <String>[];
    if (event.attendees.isNotEmpty) {
      for (var i = 0; i < event.attendees.length && i < 5; i++) {
        if (event.attendees[i].avatarUrl != null && event.attendees[i].avatarUrl!.isNotEmpty) {
          attendeeAvatars.add(event.attendees[i].avatarUrl!);
        }
      }
    }
    
    final totalCount = event.attendeeCount;
    final displayCount = totalCount > 0 ? totalCount : event.currentAttendees;
    final moreCount = displayCount > 5 ? displayCount - 5 : 0;

    // Don't show section if no attendees
    if (displayCount == 0) {
      return const SizedBox.shrink();
    }

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
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            OverlappingAvatars(
              avatarUrls: attendeeAvatars,
              totalCount: displayCount,
              maxVisible: 5,
              borderColor: theme.dominantColor,
            ),
            if (moreCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '+$moreCount more',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ),
          ],
        ),
        if (event.maxAttendees != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${event.maxAttendees! - event.currentAttendees} spots left',
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
        const Divider(),
        const SizedBox(height: 8),
        const Text(
          'About Event',
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

  /// Build "What to Expect" section
  Widget _buildWhatToExpectSection(Event event, DynamicThemeController theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 8),
        const Text(
          'What to Expect',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...event.highlights.map((highlight) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: theme.accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  highlight,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        )),
        const SizedBox(height: 20),
      ],
    );
  }

  /// Build tickets & pricing section
  Widget _buildTicketsSection(Event event, DynamicThemeController theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 8),
        const Text(
          'Tickets & Pricing',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.mutedColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: event.isFree 
                      ? Colors.green.withOpacity(0.2)
                      : theme.accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  event.isFree ? Icons.check_circle : Icons.confirmation_number,
                  color: event.isFree ? Colors.green : theme.accentColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.isFree ? 'Free Event' : '\$${event.price?.toStringAsFixed(2) ?? '0.00'}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: event.isFree ? Colors.green : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.isFree 
                          ? 'No registration fee required'
                          : 'Registration required',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build CTA button with scale animation and glow
  Widget _buildCTAButton(Event event, DynamicThemeController theme) {
    final eventsProvider = context.read<EventsProvider>();
    final isFull = event.maxAttendees != null && 
                   event.currentAttendees >= event.maxAttendees!;
    
    // If user is registered, show both View Ticket and Plan Event buttons
    if (event.isUserRegistered) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _AnimatedCTAButton(
                  label: 'View Ticket',
                  accentColor: theme.accentColor,
                  onTap: () => context.push('/events/${event.id}/ticket'),
                  isLoading: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AnimatedCTAButton(
                  label: 'Plan Event',
                  accentColor: Colors.orange,
                  onTap: () => context.push('/events/${event.id}/plan'),
                  isLoading: false,
                ),
              ),
            ],
          ),
        ],
      );
    }
    
    String buttonText;
    VoidCallback? onTap;
    
    if (isFull) {
      buttonText = 'Event Full';
      onTap = null;
    } else {
      buttonText = 'Register for the Event';
      onTap = () async {
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
      };
    }

    return _AnimatedCTAButton(
      label: buttonText,
      accentColor: isFull ? Colors.grey : theme.accentColor,
      onTap: onTap,
      isLoading: eventsProvider.isRegistering,
    );
  }

  /// Build secondary button (Cancel Event / Unregister)
  Widget _buildSecondaryButton(Event event, DynamicThemeController theme) {
    if (event.isUserOrganizer == true) {
      // Show Cancel Event button for organizer
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _showCancelEventDialog(event, theme),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Colors.red),
              foregroundColor: Colors.red,
            ),
            child: const Text('Cancel Event'),
          ),
        ),
      );
    } else if (event.isUserRegistered) {
      // Show Unregister button for attendees
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _showUnregisterDialog(event, theme),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: Colors.grey[400]!),
              foregroundColor: Colors.grey[700],
            ),
            child: const Text('Unregister'),
          ),
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  void _showUnregisterDialog(Event event, DynamicThemeController theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unregister from Event'),
        content: const Text('Are you sure you want to unregister from this event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final eventsProvider = context.read<EventsProvider>();
              final success = await eventsProvider.unregisterFromEvent(event.id);
              
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Successfully unregistered from event')),
                );
                await eventsProvider.getEventById(event.id);
              }
            },
            child: const Text('Unregister', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showCancelEventDialog(Event event, DynamicThemeController theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Event'),
        content: const Text('Are you sure you want to cancel this event? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No, Keep Event'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement cancel event API call
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Event cancelled')),
              );
            },
            child: const Text('Yes, Cancel Event', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

/// Animated CTA button with scale effect and glow
class _AnimatedCTAButton extends StatefulWidget {
  final String label;
  final Color accentColor;
  final VoidCallback? onTap;
  final bool isLoading;

  const _AnimatedCTAButton({
    required this.label,
    required this.accentColor,
    this.onTap,
    this.isLoading = false,
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
    if (widget.onTap != null) {
      _controller.forward();
    }
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
            color: widget.onTap == null 
                ? widget.accentColor.withOpacity(0.5)
                : widget.accentColor,
            borderRadius: BorderRadius.circular(30),
            boxShadow: widget.onTap != null
                ? [
                    BoxShadow(
                      color: widget.accentColor.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
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
