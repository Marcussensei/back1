import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/models/notification.dart' as notification_model;

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late Future<List<dynamic>> _notificationsFuture;
  bool _showUnreadOnly = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    setState(() {
      _notificationsFuture = ApiService.getUserNotifications(
        unreadOnly: _showUnreadOnly,
        limit: 100,
      );
    });
  }

  Future<void> _markAsRead(int notificationId) async {
    try {
      final success = await ApiService.markNotificationAsRead(notificationId);
      if (success && mounted) {
        _loadNotifications(); // Reload notifications
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification marquée comme lue')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _deleteNotification(int notificationId) async {
    try {
      final success = await ApiService.deleteNotification(notificationId);
      if (success && mounted) {
        _loadNotifications(); // Reload notifications
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification supprimée')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final success = await ApiService.markAllNotificationsAsRead();
      if (success && mounted) {
        _loadNotifications(); // Reload notifications
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Toutes les notifications marquées comme lues')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Color _getNotificationColor(String type) {
    switch (type.toLowerCase()) {
      case 'success':
      case 'info':
        return Colors.blue;
      case 'warning':
        return Colors.orange;
      case 'error':
      case 'danger':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'success':
        return Icons.check_circle;
      case 'warning':
        return Icons.warning;
      case 'error':
      case 'danger':
        return Icons.error;
      default:
        return Icons.notifications;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Aujourd\'hui ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Hier ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _showUnreadOnly = value == 'unread';
                _loadNotifications();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('Toutes les notifications'),
              ),
              const PopupMenuItem(
                value: 'unread',
                child: Text('Non lues seulement'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: _markAllAsRead,
            tooltip: 'Marquer tout comme lu',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadNotifications();
        },
        child: FutureBuilder<List<dynamic>>(
          future: _notificationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 80, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text('Erreur lors du chargement'),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      style: const TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadNotifications,
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              );
            }

            final notifications = snapshot.data ?? [];
            final notificationObjects = notifications
                .map((n) => notification_model.Notification.fromJson(n))
                .toList();

            if (notificationObjects.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _showUnreadOnly
                          ? 'Aucune notification non lue'
                          : 'Aucune notification',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _showUnreadOnly
                          ? 'Vous avez lu toutes vos notifications'
                          : 'Les nouvelles notifications apparaîtront ici',
                      style: TextStyle(color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notificationObjects.length,
              itemBuilder: (context, index) {
                final notification = notificationObjects[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: notification.lue ? 1 : 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor:
                          _getNotificationColor(notification.typeNotification)
                              .withOpacity(0.1),
                      child: Icon(
                        _getNotificationIcon(notification.typeNotification),
                        color: _getNotificationColor(
                            notification.typeNotification),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.titre,
                            style: TextStyle(
                              fontWeight: notification.lue
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (!notification.lue)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          notification.message,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatDate(notification.createdAt),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'read':
                            if (!notification.lue) {
                              _markAsRead(notification.id);
                            }
                            break;
                          case 'delete':
                            _deleteNotification(notification.id);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        if (!notification.lue)
                          const PopupMenuItem(
                            value: 'read',
                            child: Row(
                              children: [
                                Icon(Icons.check, size: 18),
                                SizedBox(width: 8),
                                Text('Marquer comme lu'),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Supprimer'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      if (!notification.lue) {
                        _markAsRead(notification.id);
                      }
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
