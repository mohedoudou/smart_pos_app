import 'package:flutter/material.dart';
import 'pos_screen.dart';
import 'product_list_screen.dart';
import 'scan_invoice_screen.dart';

class POSHomeScreen extends StatefulWidget {
  const POSHomeScreen({super.key});

  @override
  State<POSHomeScreen> createState() => _POSHomeScreenState();
}

class _POSHomeScreenState extends State<POSHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    POSScreen(),
    ProductListScreen(),
    ScanInvoiceScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.point_of_sale),
            label: 'البيع',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory),
            label: 'المخزون',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long),
            label: 'استرجاع الفواتير',
          ),
        ],
      ),
    );
  }
}
