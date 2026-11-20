import 'package:flutter/material.dart';
import 'package:zite_web_pos/services/api_service.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  bool _isLoading = false;

  Future<void> _subscribe() async {
    setState(() => _isLoading = true);

    // In a real app, you'd fetch the available plans from the backend.
    // For now, we'll hardcode a placeholder plan code.
    // YOU MUST REPLACE THIS WITH A REAL PLAN CODE FROM YOUR PAYSTACK DASHBOARD.
    const planCode = 'PLN_your_actual_plan_code_here';

    final url = await ApiService.initializeBilling(planCode);

    setState(() => _isLoading = false);

    if (url != null) {
      // In a web app, you would normally use url_launcher to open this.
      // Since we are on Flutter Web, we can use the window object or url_launcher.
      // I'll assume you have url_launcher in pubspec.yaml. If not, we'll add it.
      print('Redirecting to: $url');
      // Example using url_launcher:
      // await launchUrl(Uri.parse(url));

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Checkout URL generated: $url')));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to start checkout'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Billing & Subscription')),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 64, color: Colors.orange),
                const SizedBox(height: 16),
                const Text(
                  'Subscription Required',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your business account does not have an active subscription. Please subscribe to continue using ZiteMart.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _subscribe,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Subscribe Now'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
