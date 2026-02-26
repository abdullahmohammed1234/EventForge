import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../events/events_provider.dart';
import '../events/events_feed_screen.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final eventsProvider = context.watch<EventsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Events'),
      ),
      body: eventsProvider.savedEvents.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_outline,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No saved events',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Save events to view them here',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: eventsProvider.savedEvents.length,
              itemBuilder: (context, index) {
                final event = eventsProvider.savedEvents[index];
                return EventCard(event: event);
              },
            ),
    );
  }
}
