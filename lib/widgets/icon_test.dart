import 'package:flutter/material.dart';

class IconTest extends StatelessWidget {
  const IconTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Icon Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.dashboard, size: 50, color: Colors.blue),
            SizedBox(height: 20),
            Icon(Icons.home, size: 50, color: Colors.red),
            SizedBox(height: 20),
            Icon(Icons.shopping_cart, size: 50, color: Colors.green),
            SizedBox(height: 20),
            Icon(Icons.settings, size: 50, color: Colors.purple),
          ],
        ),
      ),
    );
  }
}
