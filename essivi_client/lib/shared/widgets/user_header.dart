import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';

class UserHeader extends StatefulWidget {
  const UserHeader({super.key});

  @override
  State<UserHeader> createState() => _UserHeaderState();
}

class _UserHeaderState extends State<UserHeader> {
  String? _userName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final authService = AuthService();
      final userName = await authService.getUserName();
      if (mounted) {
        setState(() {
          _userName = userName;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userName = 'Utilisateur';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // User Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),

            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Bienvenue',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  _isLoading
                      ? Container(
                          width: 120,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        )
                      : Text(
                          _userName ?? 'Utilisateur',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                ],
              ),
            ),

            // Notification Icon (optional)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: () {
                  // TODO: Navigate to notifications
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notifications - Fonctionnalité à venir'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
