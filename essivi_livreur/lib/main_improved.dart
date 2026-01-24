import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/services/auth_service.dart';
import 'core/services/api_service.dart';
import 'core/models/delivery.dart';
import 'features/dashboard/improved_dashboard.dart';
import 'features/dashboard/tours_improved_page.dart';
import 'features/dashboard/settings_page.dart';
import 'features/dashboard/deliveries_page_new.dart';
import 'features/auth/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Restaurer la session si elle existe
  final isLoggedIn = await AuthService.restoreSession();

  runApp(MyApp(initiallyLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool initiallyLoggedIn;

  const MyApp({super.key, required this.initiallyLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESSIVIVI Livreur',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: MainApp(initiallyLoggedIn: initiallyLoggedIn),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainApp extends StatefulWidget {
  final bool initiallyLoggedIn;

  const MainApp({super.key, required this.initiallyLoggedIn});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late bool _isLoggedIn;

  @override
  void initState() {
    super.initState();
    _isLoggedIn = widget.initiallyLoggedIn;

    // Enregistrer le callback pour le token expiré
    ApiService.setOnTokenExpired(() {
      print('[MainApp] Token expiré détecté, redirection vers login...');
      _handleLogout();
    });
  }

  void _handleLoginSuccess() {
    print('[MainApp] Login successful');
    setState(() => _isLoggedIn = true);
  }

  void _handleLogout() async {
    print('[MainApp] Logout...');
    await AuthService.logout();
    if (mounted) {
      setState(() => _isLoggedIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      return LivreurLoginPage(onLoginSuccess: _handleLoginSuccess);
    }

    return MainNavigationWrapper(onLogout: _handleLogout);
  }
}

class MainNavigationWrapper extends StatefulWidget {
  final VoidCallback onLogout;

  const MainNavigationWrapper({super.key, required this.onLogout});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _selectedIndex = 0;
  Agent? _currentAgent;
  bool _isLoadingAgent = true;

  @override
  void initState() {
    super.initState();
    _loadAgent();
  }

  Future<void> _loadAgent() async {
    try {
      final agentData = await ApiService.getMe();
      if (mounted) {
        // Use agent_info if available (new API response format), fallback to top level
        final agentInfo = agentData['agent_info'] ?? agentData;

        setState(() {
          _currentAgent = Agent(
            id: agentData['agent_id'] ?? agentData['id'] ?? 0,
            name: agentInfo['nom'] ?? agentInfo['name'] ?? 'Agent',
            email: agentInfo['email'] ?? '',
            phone: agentInfo['telephone'] ?? agentInfo['phone'] ?? '',
            tricycle: agentInfo['tricycle'] ?? 'Non assigné',
            status: agentInfo['actif'] ?? agentInfo['status'] ?? 'actif',
          );
          _isLoadingAgent = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentAgent = Agent(
            id: 0,
            name: 'Agent de Livraison',
            email: 'agent@essivi.com',
            phone: '',
            tricycle: 'Non assigné',
            status: 'actif',
          );
          _isLoadingAgent = false;
        });
      }
    }
  }

  late List<NavigationItem> _navigationItems;

  Widget _buildProfilePage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Stack(
        children: [
          const SettingsPage(),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Déconnexion'),
                      content: const Text(
                          'Êtes-vous sûr de vouloir vous déconnecter?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Annuler'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onLogout();
                          },
                          child: const Text('Déconnecter',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text('Se déconnecter'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingAgent) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    _navigationItems = [
      NavigationItem(
        label: 'Accueil',
        icon: Icons.home,
        page: ImprovedDeliveryDashboard(
          agent: _currentAgent,
          onLogout: widget.onLogout,
        ),
      ),
      NavigationItem(
        label: 'Tours',
        icon: Icons.directions_run,
        page: ToursPage(agent: _currentAgent!),
      ),
      NavigationItem(
        label: 'Historique',
        icon: Icons.history,
        page: const DeliveriesPageNew(),
      ),
      NavigationItem(
        label: 'Profil',
        icon: Icons.person,
        page: _buildProfilePage(),
      ),
    ];

    return Scaffold(
      body: _navigationItems[_selectedIndex].page,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        items: _navigationItems
            .map(
              (item) => BottomNavigationBarItem(
                icon: Icon(item.icon),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class NavigationItem {
  final String label;
  final IconData icon;
  final Widget page;

  NavigationItem({
    required this.label,
    required this.icon,
    required this.page,
  });
}

/// Wrapper pour la page profil avec logout
class ProfilePageWithLogout extends StatelessWidget {
  final VoidCallback onLogout;

  const ProfilePageWithLogout({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return ProfilePageWithLogoutLogic(onLogout: onLogout);
  }
}

class ProfilePageWithLogoutLogic extends StatelessWidget {
  final VoidCallback onLogout;

  const ProfilePageWithLogoutLogic({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Stack(
        children: [
          const SettingsPage(),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Déconnexion'),
                      content: const Text(
                          'Êtes-vous sûr de vouloir vous déconnecter?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Annuler'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            onLogout();
                          },
                          child: const Text('Déconnecter',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text('Se déconnecter'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
