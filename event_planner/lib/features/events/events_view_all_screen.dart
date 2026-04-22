import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'events_provider.dart';
import 'package:intl/intl.dart';
import '../../core/config/app_config.dart';

class GridEventCard extends StatelessWidget {
  final Event event;

  const GridEventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () => context.push('/events/${event.id}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  blurRadius: 8,
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// IMAGE
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.network(
                            AppConfig.getFullUrl(event.coverImageUrl),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(color: Colors.grey[300]),
                          ),
                        ),

                        /// DATE BADGE
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFE76B8),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.black),
                            ),
                            child: Text(
                              DateFormat('MMM d').format(event.startTime),
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),

                        /// SAVE BUTTON
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () async {
                              final provider = context.read<EventsProvider>();

                              if (event.isUserSaved) {
                                await provider.unsaveEvent(event.id);
                              } else {
                                await provider.saveEvent(event.id);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                event.isUserSaved
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                size: 18,
                                color: const Color(0xFFFE76B8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          "${event.locationName ?? event.city} • ${event.organizerName ?? 'Unknown'}",
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          DateFormat('h:mm a').format(event.startTime),
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}

class EventsViewAllScreen extends StatelessWidget {
  final String? city;
  final String? category;

  const EventsViewAllScreen({
    super.key,
    this.city,
    this.category,
  });

  @override
  Widget build(BuildContext context) {
    final eventsProvider = context.watch<EventsProvider>();
    final allEvents = eventsProvider.events;

    final events = allEvents.where((event) {
      if (city != null && city!.isNotEmpty) {
        return event.city.toLowerCase() == city!.toLowerCase();
      } else if (category != null && category!.isNotEmpty) {
        return event.category.toLowerCase() == category!.toLowerCase();
      }
      return true;
    }).toList();
    String headerTitle;

    if (city != null && city!.isNotEmpty) {
      headerTitle = "Events in $city";
    } else if (category != null && category!.isNotEmpty) {
      headerTitle =
          "Popular ${category![0].toUpperCase()}${category!.substring(1)} Events";
    } else {
      headerTitle = "Popular Events";
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Text(
          headerTitle,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: events.isEmpty
          ? const Center(
              child: Text(
                "No events found",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              itemCount: events.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemBuilder: (context, index) {
                final event = events[index];
                return GridEventCard(event: event);
              },
            ),
    );
  }
}
