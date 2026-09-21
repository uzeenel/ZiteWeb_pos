import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/license_service.dart';

class LicenseExpiredScreen extends StatelessWidget {
  final LicenseStatus status;

  const LicenseExpiredScreen({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final expired =
        status.expiry != null && status.expiry!.isBefore(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  expired ? Icons.lock_clock : Icons.error_outline,
                  size: 72,
                  color: expired ? Colors.orange : Colors.red,
                ),
                const SizedBox(height: 24),
                Text(
                  expired ? 'License Expired' : 'License Error',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  status.errorMessage ?? 'Unknown license issue.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
                if (status.expiry != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Expired on: ${status.expiry!.toLocal().toString().split(' ')[0]}',
                    style: const TextStyle(fontSize: 14, color: Colors.white54),
                  ),
                ],
                const SizedBox(height: 32),
                const Text(
                  'Please contact your Zara Soft to renew:',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
                const SizedBox(height: 12),
                _contactButton(
                  context,
                  icon: Icons.phone,
                  label: '+234 7056611743',
                  url: 'tel:+2347056611743',
                ),
                const SizedBox(height: 8),
                _contactButton(
                  context,
                  icon: Icons.email,
                  label: 'zitemart@chowexpress.co',
                  url: 'mailto:zitemart@chowexpress.co?subject=POS License Renewal',
                ),
                const SizedBox(height: 32),
                TextButton(
                  onPressed: () => _retry(context),
                  child: const Text(
                    'Retry',
                    style: TextStyle(color: Colors.blueAccent),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _contactButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String url,
  }) {
    return OutlinedButton.icon(
      onPressed: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      },
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white38),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  void _retry(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Please restart the app after updating the license file.',
        ),
      ),
    );
  }
}
