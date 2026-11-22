import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:zite_web_pos/services/api_service.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  List<dynamic> _plans = [];
  bool _isLoadingPlans = true;

  @override
  void initState() {
    super.initState();
    _fetchPlans();
  }

  Future<void> _fetchPlans() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/billing/plans'),
      );
      if (response.statusCode == 200) {
        setState(() {
          _plans = jsonDecode(response.body);
          _isLoadingPlans = false;
        });
      } else {
        setState(() => _isLoadingPlans = false);
      }
    } catch (e) {
      print('Error fetching plans: $e');
      setState(() => _isLoadingPlans = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'ZiteMart',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            child: const Text('Log In', style: TextStyle(color: Colors.white)),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0, left: 8.0),
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/signup'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1e3a8a),
                foregroundColor: Colors.white,
              ),
              child: const Text('Start Free Trial'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
              color: const Color(0xFF121212),
              child: Column(
                children: [
                  const Text(
                    'The Modern POS for Growing Businesses',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Manage sales, inventory, and customers from anywhere. No hardware required. Built for Nigerian businesses.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/signup'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1e3a8a),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 20,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text('Create Your Business Account'),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
              color: const Color(0xFF121212),
              child: Column(
                children: [
                  const Text(
                    'Simple, transparent pricing',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 40),
                  if (_isLoadingPlans)
                    const CircularProgressIndicator()
                  else if (_plans.isEmpty)
                    const Text(
                      'No plans available at the moment.',
                      style: TextStyle(color: Colors.white70),
                    )
                  else
                    Wrap(
                      spacing: 24,
                      runSpacing: 24,
                      alignment: WrapAlignment.center,
                      children: _plans.asMap().entries.map((entry) {
                        final index = entry.key;
                        final plan = entry.value;
                        return _buildPricingCard(
                          title: plan['name'],
                          price:
                              '₦${(plan['amount'] / 100).toStringAsFixed(0)}',
                          features: List<String>.from(plan['features'] ?? []),
                          onTap: () => Navigator.pushNamed(context, '/signup'),
                          isFeatured: index == 1,
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingCard({
    required String title,
    required String price,
    required List<String> features,
    required VoidCallback onTap,
    bool isFeatured = false,
  }) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isFeatured ? const Color(0xFF1e3a8a) : Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
        border: isFeatured ? Border.all(color: Colors.blue, width: 2) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isFeatured ? Colors.white : Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                price,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Text(' /month', style: TextStyle(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 32),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const Icon(Icons.check, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(f, style: const TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: isFeatured
                    ? Colors.white
                    : const Color(0xFF1e3a8a),
                foregroundColor: isFeatured ? Colors.black : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'Start Free Trial',
                style: TextStyle(
                  color: isFeatured ? Colors.black : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
