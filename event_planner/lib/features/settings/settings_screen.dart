import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        children: [
          _buildSectionHeader(context, 'Appearance'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Enable dark theme'),
            value: isDark,
            onChanged: (value) => themeProvider.setThemeMode(
              value ? ThemeMode.dark : ThemeMode.light,
            ),
          ),
          ListTile(
            title: const Text('Text Size'),
            subtitle: Text('${(themeProvider.textScaleFactor * 100).round()}%'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showTextSizeDialog(context, themeProvider),
          ),
          SwitchListTile(
            title: const Text('High Contrast'),
            subtitle: const Text('Increase text contrast'),
            value: themeProvider.highContrast,
            onChanged: (value) => themeProvider.setHighContrast(value),
          ),
          const Divider(),
          _buildSectionHeader(context, 'Notifications'),
          ListTile(
            title: const Text('Default Reminder'),
            subtitle: const Text('1 hour before'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showReminderDialog(context),
          ),
          const Divider(),
          _buildSectionHeader(context, 'Accessibility'),
          ListTile(
            title: const Text('Screen Reader Support'),
            subtitle: const Text('Optimized for TalkBack/VoiceOver'),
            trailing: Switch(
              value: context.watch<ThemeProvider>().textScaleFactor != 1.0,
              onChanged: (value) {
                themeProvider.setTextScaleFactor(value ? 1.2 : 1.0);
              },
            ),
          ),
          ListTile(
            title: const Text('Reduce Motion'),
            subtitle: const Text('Minimize animations'),
            trailing: Switch(
              value: false,
              onChanged: (value) {},
            ),
          ),
          const Divider(),
          _buildSectionHeader(context, 'About'),
          ListTile(
            title: const Text('Version'),
            subtitle: const Text('1.0.0'),
          ),
          ListTile(
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => _launchUrl('https://example.com/privacy'),
          ),
          ListTile(
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => _launchUrl('https://example.com/terms'),
          ),
          ListTile(
            title: const Text('Open Source Licenses'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showLicensePage(context: context),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  void _showTextSizeDialog(BuildContext context, ThemeProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Text Size'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Adjust text size for better readability'),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    Slider(
                      value: provider.textScaleFactor,
                      min: 0.8,
                      max: 2.0,
                      divisions: 6,
                      label: '${(provider.textScaleFactor * 100).round()}%',
                      onChanged: (value) {
                        provider.setTextScaleFactor(value);
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('A', style: TextStyle(fontSize: 12)),
                        Text('A', style: TextStyle(fontSize: 24)),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              provider.setTextScaleFactor(1.0);
              Navigator.pop(context);
            },
            child: const Text('Reset'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showReminderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Default Reminder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('30 minutes before'),
              value: '30min',
              groupValue: '1hour',
              onChanged: (value) {},
            ),
            RadioListTile<String>(
              title: const Text('1 hour before'),
              value: '1hour',
              groupValue: '1hour',
              onChanged: (value) {},
            ),
            RadioListTile<String>(
              title: const Text('1 day before'),
              value: '1day',
              groupValue: '1hour',
              onChanged: (value) {},
            ),
            RadioListTile<String>(
              title: const Text('No reminder'),
              value: 'none',
              groupValue: '1hour',
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
