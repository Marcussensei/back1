import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../pages/home/client_home_page.dart';
import '../orders/orders_page.dart';
import '../orders/order_creation_page.dart';
import '../profile/profile_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final List<Widget> _pages = [
    const ClientHomePage(),
    const OrdersPage(),
    const OrderCreationPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = context.watch<DashboardProvider>();

    return Scaffold(
      body: _pages[dashboardProvider.selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Commandes'),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: 'Commander',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
        currentIndex: dashboardProvider.selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          context.read<DashboardProvider>().selectTab(index);
        },
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
