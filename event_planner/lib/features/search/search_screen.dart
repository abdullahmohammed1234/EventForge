import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../events/events_provider.dart';
import '../events/events_feed_screen.dart';

// Design System Colors
class AppColors {
  static const Color pink = Color(0xFFFF6BBA);
  static const Color blue = Color(0xFF1E60EB);
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color yellowGreen = Color(0xFFCBFF00);
  static const Color grey = Color(0xFF636363);
  static const Color beige = Color(0xFFFFE4C1);
  static const Color peach = Color(0xFFFFC1C2);
}

// Gradient background widget
class GradientBackground extends StatelessWidget {
  final Widget child;
  
  const GradientBackground({super.key, required this.child});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.beige,
            AppColors.peach,
            AppColors.pink,
          ],
        ),
      ),
      child: child,
    );
  }
}

enum FilterType { category, price, date, location }

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _locationFocusNode = FocusNode();

  // Filter states
  Set<FilterType> _activeFilters = {};
  
  // Price filter state
  RangeValues _priceRange = const RangeValues(0, 200);
  double _minPrice = 0;
  double _maxPrice = 200;
  
  // Date filter state
  String _selectedDateOption = 'any';
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  
  // Location filter state
  String _locationQuery = '';
  double _distance = 25;

  // Category filter state
  String _selectedCategory = 'all';
  final List<String> _categories = [
    'all', 'music', 'sports', 'arts', 'food', 'technology', 'business', 'social', 'outdoor', 'other'
  ];

  // Local filtered events for client-side filtering
  List<Event> _filteredEvents = [];
  bool _isFiltering = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventsProvider>().clearSearchState();
      context.read<EventsProvider>().fetchEvents(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _locationController.dispose();
    _searchFocusNode.dispose();
    _locationFocusNode.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    final eventsProvider = context.read<EventsProvider>();
    final category = _selectedCategory == 'all' ? null : _selectedCategory;
    
    if (query.isNotEmpty) {
      eventsProvider.searchEvents(query, category: category);
    } else {
      eventsProvider.fetchEvents(refresh: true);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _filteredEvents = [];
      _isFiltering = false;
    });
    context.read<EventsProvider>().fetchEvents(refresh: true);
  }

  void _onSearchChanged(String value) {
    _applyAllFilters();
  }

  void _applyAllFilters() {
    final eventsProvider = context.read<EventsProvider>();
    final query = _searchController.text.trim();
    final category = _selectedCategory == 'all' ? null : _selectedCategory;
    
    // If we have advanced filters (price, date, location), we need client-side filtering
    final hasAdvancedFilters = _activeFilters.contains(FilterType.price) ||
        _activeFilters.contains(FilterType.date) ||
        (_activeFilters.contains(FilterType.location) && _locationQuery.isNotEmpty);
    
    if (hasAdvancedFilters) {
      // Get current events and filter client-side
      final allEvents = eventsProvider.events;
      
      setState(() {
        _filteredEvents = _filterEventsLocally(
          allEvents,
          query: query,
          category: category,
          minPrice: _activeFilters.contains(FilterType.price) ? _minPrice : null,
          maxPrice: _activeFilters.contains(FilterType.price) ? _maxPrice : null,
          dateOption: _activeFilters.contains(FilterType.date) ? _selectedDateOption : null,
          customStartDate: _customStartDate,
          customEndDate: _customEndDate,
          locationQuery: _locationQuery.isNotEmpty ? _locationQuery : null,
          distance: _activeFilters.contains(FilterType.location) ? _distance : null,
        );
        _isFiltering = true;
      });
    } else {
      // Use backend search
      setState(() {
        _isFiltering = false;
      });
      
      if (query.isNotEmpty) {
        // Use backend search with location support
        eventsProvider.searchEvents(query, category: category);
      } else if (category != null) {
        eventsProvider.filterByCategory(category);
      } else {
        eventsProvider.fetchEvents(refresh: true);
      }
    }
  }

  List<Event> _filterEventsLocally(
    List<Event> events, {
    String? query,
    String? category,
    double? minPrice,
    double? maxPrice,
    String? dateOption,
    DateTime? customStartDate,
    DateTime? customEndDate,
    String? locationQuery,
    double? distance,
  }) {
    return events.where((event) {
      // Filter by search query
      if (query != null && query.isNotEmpty) {
        final lowerQuery = query.toLowerCase();
        if (!event.title.toLowerCase().contains(lowerQuery) &&
            !event.city.toLowerCase().contains(lowerQuery) &&
            !(event.description?.toLowerCase().contains(lowerQuery) ?? false)) {
          return false;
        }
      }
      
      // Filter by category
      if (category != null && event.category != category) {
        return false;
      }
      
      // Filter by price
      if (minPrice != null || maxPrice != null) {
        final eventPrice = event.price ?? 0;
        if (minPrice != null && eventPrice < minPrice) return false;
        if (maxPrice != null && eventPrice > maxPrice) return false;
      }
      
      // Filter by date
      if (dateOption != null && dateOption != 'any') {
        final now = DateTime.now();
        final eventDate = event.startTime;
        
        switch (dateOption) {
          case 'today':
            if (eventDate.year != now.year || 
                eventDate.month != now.month || 
                eventDate.day != now.day) return false;
            break;
          case 'tomorrow':
            final tomorrow = now.add(const Duration(days: 1));
            if (eventDate.year != tomorrow.year || 
                eventDate.month != tomorrow.month || 
                eventDate.day != tomorrow.day) return false;
            break;
          case 'thisWeek':
            final endOfWeek = now.add(Duration(days: 7 - now.weekday));
            if (eventDate.isBefore(now) || eventDate.isAfter(endOfWeek)) return false;
            break;
          case 'thisWeekend':
            final daysUntilSaturday = 6 - now.weekday;
            final saturday = DateTime(now.year, now.month, now.day + daysUntilSaturday);
            final sunday = saturday.add(const Duration(days: 1));
            if (eventDate.year != saturday.year || eventDate.month != saturday.month) {
              if (eventDate.year != sunday.year || eventDate.month != sunday.month) return false;
            }
            if (eventDate.day != saturday.day && eventDate.day != sunday.day) return false;
            break;
          case 'custom':
            // Filter by date range
            if (customStartDate != null && customEndDate != null) {
              final startOfStartDay = DateTime(customStartDate.year, customStartDate.month, customStartDate.day);
              final endOfEndDay = DateTime(customEndDate.year, customEndDate.month, customEndDate.day, 23, 59, 59);
              if (eventDate.isBefore(startOfStartDay) || eventDate.isAfter(endOfEndDay)) return false;
            } else if (customStartDate != null) {
              final startOfDay = DateTime(customStartDate.year, customStartDate.month, customStartDate.day);
              if (eventDate.isBefore(startOfDay)) return false;
            }
            break;
        }
      }
      
      // Filter by location
      if (locationQuery != null && locationQuery.isNotEmpty) {
        final lowerLocation = locationQuery.toLowerCase();
        final cityMatch = event.city.toLowerCase().contains(lowerLocation);
        final addressMatch = event.address?.toLowerCase().contains(lowerLocation) ?? false;
        if (!cityMatch && !addressMatch) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }

  void _toggleFilter(FilterType filter) {
    setState(() {
      if (_activeFilters.contains(filter)) {
        _activeFilters.remove(filter);
      } else {
        _activeFilters.add(filter);
      }
    });
    _applyAllFilters();
  }

  void _showPriceFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PriceFilterSheet(
        initialRange: _priceRange,
        onApply: (range, min, max) {
          setState(() {
            _priceRange = range;
            _minPrice = min;
            _maxPrice = max;
            _activeFilters.add(FilterType.price);
          });
          _applyAllFilters();
        },
      ),
    );
  }

  void _showDateFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DateFilterSheet(
        selectedOption: _selectedDateOption,
        customStartDate: _customStartDate,
        customEndDate: _customEndDate,
        onApply: (option, startDate, endDate) {
          setState(() {
            _selectedDateOption = option;
            _customStartDate = startDate;
            _customEndDate = endDate;
            _activeFilters.add(FilterType.date);
          });
          _applyAllFilters();
        },
      ),
    );
  }

  void _showLocationFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LocationFilterSheet(
        locationController: _locationController,
        distance: _distance,
        onApply: (location, dist) {
          setState(() {
            _locationQuery = location;
            _distance = dist;
            _activeFilters.add(FilterType.location);
          });
          _applyAllFilters();
        },
      ),
    );
  }

  void _showCategoryFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CategoryFilterSheet(
        selectedCategory: _selectedCategory,
        categories: _categories,
        onApply: (category) {
          setState(() {
            _selectedCategory = category;
            if (category != 'all') {
              _activeFilters.add(FilterType.category);
            } else {
              _activeFilters.remove(FilterType.category);
            }
          });
          _applyAllFilters();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventsProvider = context.watch<EventsProvider>();

    // Determine which events to display
    final displayEvents = _isFiltering ? _filteredEvents : eventsProvider.events;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // Top Section with Search Bar and Back Button
              _buildSearchHeader(),
              
              // Horizontal Filter Chips
              _buildFilterChips(),
              
              // Spacing below filter chips
              const SizedBox(height: 16),
              
              // Search Results
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.beige.withOpacity(0.4),
                        AppColors.peach.withOpacity(0.3),
                        AppColors.pink.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: eventsProvider.isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.pink))
                      : displayEvents.isEmpty
                          ? _buildEmptyState()
                          : _buildEventList(displayEvents),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () {
              // Try to pop, but handle case where there's no previous page
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                // If can't pop, go to home
                context.read<EventsProvider>().clearSearchState();
                context.read<EventsProvider>().fetchEvents(refresh: true);
              }
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.grey.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back,
                color: AppColors.black,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Search Bar
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.grey.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search events',
                  hintStyle: TextStyle(
                    color: AppColors.grey.withOpacity(0.7),
                    fontSize: 15,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.grey,
                    size: 22,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? GestureDetector(
                          onTap: _clearSearch,
                          child: const Icon(
                            Icons.close,
                            color: AppColors.grey,
                            size: 20,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                style: const TextStyle(
                  color: AppColors.black,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterChip(
            label: 'Category',
            icon: Icons.category_outlined,
            isActive: _activeFilters.contains(FilterType.category) || _selectedCategory != 'all',
            onTap: _showCategoryFilter,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Price',
            icon: Icons.attach_money,
            isActive: _activeFilters.contains(FilterType.price),
            onTap: _showPriceFilter,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Date',
            icon: Icons.calendar_today_outlined,
            isActive: _activeFilters.contains(FilterType.date),
            onTap: _showDateFilter,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Location',
            icon: Icons.location_on_outlined,
            isActive: _activeFilters.contains(FilterType.location),
            onTap: _showLocationFilter,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.pink : AppColors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive ? AppColors.pink : AppColors.grey.withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? AppColors.white : AppColors.black,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.white : AppColors.black,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: isActive ? AppColors.white : AppColors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.beige.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off,
              size: 50,
              color: AppColors.grey,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No events found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or search term',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.grey.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 24),
          if (_activeFilters.isNotEmpty || _searchController.text.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() {
                  _activeFilters.clear();
                  _selectedCategory = 'all';
                  _searchController.clear();
                  _priceRange = const RangeValues(0, 200);
                  _minPrice = 0;
                  _maxPrice = 200;
                  _selectedDateOption = 'any';
                  _customStartDate = null;
                  _customEndDate = null;
                  _locationQuery = '';
                  _distance = 25;
                  _filteredEvents = [];
                  _isFiltering = false;
                });
                context.read<EventsProvider>().fetchEvents(refresh: true);
              },
              child: const Text(
                'Clear all filters',
                style: TextStyle(
                  color: AppColors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEventList(List<Event> events) {
    return RefreshIndicator(
      onRefresh: () async {
        await context.read<EventsProvider>().fetchEvents(refresh: true);
      },
      color: AppColors.pink,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: EventCard(event: event),
          );
        },
      ),
    );
  }
}

// Price Filter Bottom Sheet
class _PriceFilterSheet extends StatefulWidget {
  final RangeValues initialRange;
  final Function(RangeValues, double, double) onApply;

  const _PriceFilterSheet({
    required this.initialRange,
    required this.onApply,
  });

  @override
  State<_PriceFilterSheet> createState() => _PriceFilterSheetState();
}

class _PriceFilterSheetState extends State<_PriceFilterSheet> {
  late RangeValues _currentRange;

  @override
  void initState() {
    super.initState();
    _currentRange = widget.initialRange;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Title
          const Text(
            'Price',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 24),
          
          // Price range display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPriceLabel('\$${_currentRange.start.toInt()}'),
              _buildPriceLabel('\$${_currentRange.end.toInt()}'),
            ],
          ),
          const SizedBox(height: 16),
          
          // Range Slider
          RangeSlider(
            values: _currentRange,
            min: 0,
            max: 200,
            divisions: 40,
            activeColor: AppColors.pink,
            inactiveColor: AppColors.grey.withOpacity(0.2),
            onChanged: (values) {
              setState(() {
                _currentRange = values;
              });
            },
          ),
          const SizedBox(height: 32),
          
          // Apply Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(
                  _currentRange,
                  _currentRange.start,
                  _currentRange.end,
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.black,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Apply Filters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildPriceLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.beige.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.black,
        ),
      ),
    );
  }
}

// Date Filter Bottom Sheet with Date Range Picker
class _DateFilterSheet extends StatefulWidget {
  final String selectedOption;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final Function(String, DateTime?, DateTime?) onApply;

  const _DateFilterSheet({
    required this.selectedOption,
    this.customStartDate,
    this.customEndDate,
    required this.onApply,
  });

  @override
  State<_DateFilterSheet> createState() => _DateFilterSheetState();
}

class _DateFilterSheetState extends State<_DateFilterSheet> {
  late String _selectedOption;
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  final List<Map<String, dynamic>> _dateOptions = [
    {'label': 'Any', 'value': 'any', 'icon': Icons.all_inclusive},
    {'label': 'Today', 'value': 'today', 'icon': Icons.today},
    {'label': 'Tomorrow', 'value': 'tomorrow', 'icon': Icons.event},
    {'label': 'This Week', 'value': 'thisWeek', 'icon': Icons.date_range},
    {'label': 'This Weekend', 'value': 'thisWeekend', 'icon': Icons.weekend},
    {'label': 'Custom Range', 'value': 'custom', 'icon': Icons.calendar_month},
  ];

  @override
  void initState() {
    super.initState();
    _selectedOption = widget.selectedOption;
    _customStartDate = widget.customStartDate;
    _customEndDate = widget.customEndDate;
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.pink,
              onPrimary: AppColors.white,
              surface: AppColors.white,
              onSurface: AppColors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
        _selectedOption = 'custom';
      });
    }
  }

  String _formatDateRange() {
    if (_customStartDate != null && _customEndDate != null) {
      return '${DateFormat('MMM d').format(_customStartDate!)} - ${DateFormat('MMM d, yyyy').format(_customEndDate!)}';
    } else if (_customStartDate != null) {
      return 'From ${DateFormat('MMM d, yyyy').format(_customStartDate!)}';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Title
          const Text(
            'Date',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 24),
          
          // Date Options
          ..._dateOptions.map((option) => _buildDateOption(
            option['label'],
            option['value'],
            option['icon'],
          )),
          
          if (_selectedOption == 'custom' && _customStartDate != null)
            Padding(
              padding: const EdgeInsets.only(top: 12, left: 52),
              child: Text(
                'Selected: ${_formatDateRange()}',
                style: const TextStyle(
                  color: AppColors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          
          const SizedBox(height: 32),
          
          // Apply Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(_selectedOption, _customStartDate, _customEndDate);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.black,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Apply Filters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildDateOption(String label, String value, IconData icon) {
    final isSelected = _selectedOption == value;
    
    return GestureDetector(
      onTap: () {
        if (value == 'custom') {
          _selectDateRange();
        } else {
          setState(() {
            _selectedOption = value;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.pink.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.pink : AppColors.grey.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.pink : AppColors.grey,
              size: 22,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.pink : AppColors.black,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.pink,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

// Location Filter Bottom Sheet
class _LocationFilterSheet extends StatefulWidget {
  final TextEditingController locationController;
  final double distance;
  final Function(String, double) onApply;

  const _LocationFilterSheet({
    required this.locationController,
    required this.distance,
    required this.onApply,
  });

  @override
  State<_LocationFilterSheet> createState() => _LocationFilterSheetState();
}

class _LocationFilterSheetState extends State<_LocationFilterSheet> {
  late TextEditingController _locationController;
  late double _distance;

  @override
  void initState() {
    super.initState();
    _locationController = TextEditingController(text: widget.locationController.text);
    _distance = widget.distance;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Title
          const Text(
            'Location',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 24),
          
          // Location Search Field
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.grey.withOpacity(0.3)),
            ),
            child: TextField(
              controller: _locationController,
              autofocus: true,
              onSubmitted: (value) {
                // Trigger search when user submits
              },
              decoration: InputDecoration(
                hintText: 'Enter city or address...',
                hintStyle: TextStyle(
                  color: AppColors.grey.withOpacity(0.7),
                ),
                prefixIcon: const Icon(
                  Icons.location_on,
                  color: AppColors.pink,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              style: const TextStyle(
                color: AppColors.black,
                fontSize: 16,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Quick location suggestions
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'New York', 'Los Angeles', 'Chicago', 'San Francisco', 'Seattle'
            ].map((city) => GestureDetector(
              onTap: () {
                _locationController.text = city;
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.beige.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  city,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.black,
                  ),
                ),
              ),
            )).toList(),
          ),
          
          const SizedBox(height: 32),
          
          // Distance Label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Distance',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.black,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.pink.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Within ${_distance.toInt()} km',
                  style: TextStyle(
                    color: AppColors.pink.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Distance Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.pink,
              inactiveTrackColor: AppColors.grey.withOpacity(0.2),
              thumbColor: AppColors.pink,
              overlayColor: AppColors.pink.withOpacity(0.2),
              trackHeight: 6,
            ),
            child: Slider(
              value: _distance,
              min: 1,
              max: 50,
              divisions: 49,
              onChanged: (value) {
                setState(() {
                  _distance = value;
                });
              },
            ),
          ),
          
          // Distance markers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '1 km',
                  style: TextStyle(
                    color: AppColors.grey.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                Text(
                  '50 km',
                  style: TextStyle(
                    color: AppColors.grey.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Apply Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(_locationController.text, _distance);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.black,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Apply Filters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

// Category Filter Bottom Sheet
class _CategoryFilterSheet extends StatefulWidget {
  final String selectedCategory;
  final List<String> categories;
  final Function(String) onApply;

  const _CategoryFilterSheet({
    required this.selectedCategory,
    required this.categories,
    required this.onApply,
  });

  @override
  State<_CategoryFilterSheet> createState() => _CategoryFilterSheetState();
}

class _CategoryFilterSheetState extends State<_CategoryFilterSheet> {
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedCategory;
  }

  IconData _getCategoryIcon(String category) {
    final icons = {
      'all': Icons.apps,
      'music': Icons.music_note,
      'sports': Icons.sports_soccer,
      'arts': Icons.palette,
      'food': Icons.restaurant,
      'technology': Icons.computer,
      'business': Icons.business,
      'social': Icons.people,
      'outdoor': Icons.park,
      'other': Icons.more_horiz,
    };
    return icons[category] ?? Icons.event;
  }

  Color _getCategoryColor(String category) {
    final colors = {
      'all': AppColors.grey,
      'music': Colors.purple,
      'sports': Colors.green,
      'arts': Colors.orange,
      'food': Colors.red,
      'technology': Colors.blue,
      'business': Colors.teal,
      'social': AppColors.pink,
      'outdoor': Colors.lime,
      'other': Colors.grey,
    };
    return colors[category] ?? Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Title
          const Text(
            'Category',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 24),
          
          // Category Grid
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: widget.categories.map((category) {
              final isSelected = _selectedCategory == category;
              final color = _getCategoryColor(category);
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected ? color : AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? color : AppColors.grey.withOpacity(0.3),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getCategoryIcon(category),
                        size: 20,
                        color: isSelected ? AppColors.white : color,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        category == 'all' ? 'All' : category[0].toUpperCase() + category.substring(1),
                        style: TextStyle(
                          color: isSelected ? AppColors.white : AppColors.black,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 32),
          
          // Apply Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(_selectedCategory);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.black,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Apply Filters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
