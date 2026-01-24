import { useState, useEffect, useCallback, useRef } from 'react';
import { useNotificationSound } from './useNotificationSound';

interface Notification {
  id: number;
  type: string;
  title: string;
  message: string;
  data?: {
    commande_id?: number;
    client_id?: number;
    montant_total?: number;
    livraison_id?: number;
  };
  read: boolean;  // Changed from is_read to read (new API)
  created_at?: string;
  timestamp?: string;  // ISO timestamp from new API
  sound?: boolean;
}

interface Order {
  id: string;
  client: string;
  quantity: number;
  time: string;
}

const API_BASE_URL = import.meta.env.VITE_API_URL || 'https://essivivi-project.onrender.com';

export function useOrderNotifications() {
  const { soundEnabled, toggleSound: toggleSoundHook, playSound } = useNotificationSound();
  const [pendingOrders, setPendingOrders] = useState<Order[]>([]);
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [unreadCount, setUnreadCount] = useState(0);
  const [loading, setLoading] = useState(false);
  const pollIntervalRef = useRef<NodeJS.Timeout | null>(null);
  const previousNotificationIdsRef = useRef<Set<number>>(new Set());
  const playSoundRef = useRef(playSound);

  // Keep playSoundRef in sync
  useEffect(() => {
    playSoundRef.current = playSound;
  }, [playSound]);

  // Fetch notifications from backend
  const fetchNotifications = useCallback(async () => {
    try {
      console.log('Fetching notifications from', `${API_BASE_URL}/notification/`);

      // Use new REST API endpoint
      // Note: credentials 'include' sends HTTP-only cookies automatically
      const response = await fetch(`${API_BASE_URL}/notification/?unread_only=false&limit=50`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json'
        },
        credentials: 'include' // Send HTTP-only cookies
      });

      if (response.ok) {
        const data = await response.json();
        const newNotifications = data.notifications || [];
        
        console.log('Notifications fetched:', newNotifications.length, 'unread:', data.unread_count);
        
        setNotifications(newNotifications);
        setUnreadCount(data.unread_count || 0);
      } else {
        console.error('Failed to fetch notifications:', response.status, response.statusText);
      }
    } catch (error) {
      console.error('Error fetching notifications:', error);
    }
  }, []);

  // Mark notification as read
  const markAsRead = useCallback(async (notificationId?: number) => {
    try {
      if (notificationId) {
        // Use new REST API endpoint - GET request marks as read
        await fetch(`${API_BASE_URL}/notification/${notificationId}`, {
          method: 'GET',
          headers: {
            'Content-Type': 'application/json'
          },
          credentials: 'include' // Send HTTP-only cookies
        });
      }
      
      await fetchNotifications();
    } catch (error) {
      console.error('Error marking as read:', error);
    }
  }, [fetchNotifications]);

  // Clear all notifications
  const clearNotifications = useCallback(async () => {
    try {
      // Use new REST API endpoint
      await fetch(`${API_BASE_URL}/notification/clear`, {
        method: 'DELETE',
        headers: {
          'Content-Type': 'application/json'
        },
        credentials: 'include' // Send HTTP-only cookies
      });
      
      await fetchNotifications();
    } catch (error) {
      console.error('Error clearing notifications:', error);
    }
  }, [fetchNotifications]);

  // Delete a single notification by ID
  const deleteNotification = useCallback(async (notificationId: number) => {
    try {
      await fetch(`${API_BASE_URL}/notification/${notificationId}`, {
        method: 'DELETE',
        headers: {
          'Content-Type': 'application/json'
        },
        credentials: 'include' // Send HTTP-only cookies
      });
      
      await fetchNotifications();
    } catch (error) {
      console.error('Error deleting notification:', error);
    }
  }, [fetchNotifications]);

  const toggleSound = useCallback(() => {
    // Delegate to the useNotificationSound hook's toggleSound
    toggleSoundHook();
  }, [toggleSoundHook]);

  // Setup polling for notifications
  useEffect(() => {
    console.log('Setting up notification polling');
    // Initial fetch
    fetchNotifications();

    // Poll every 3 seconds for real-time notifications
    pollIntervalRef.current = setInterval(() => {
      console.log('Polling for notifications...');
      fetchNotifications();
    }, 3000);

    return () => {
      console.log('Cleaning up notification polling');
      if (pollIntervalRef.current) {
        clearInterval(pollIntervalRef.current);
      }
    };
  }, []);

  // Separate effect for playing sound on new unread notifications
  useEffect(() => {
    if (!soundEnabled) return;

    const newUnreadIds: Set<number> = new Set(
      notifications.filter((n: Notification) => !n.read).map((n: Notification) => n.id)
    );
    
    // Find newly added unread notifications
    const newUnreadNotifications = notifications.filter(
      (n: Notification) => !n.read && !previousNotificationIdsRef.current.has(n.id)
    );
    
    if (newUnreadNotifications.length > 0) {
      console.log('Playing sound for', newUnreadNotifications.length, 'new notifications');
      // Use setTimeout to ensure sound plays asynchronously
      // This helps with AudioContext state management
      const timerId = setTimeout(() => {
        playSoundRef.current();
      }, 0);
      
      return () => clearTimeout(timerId);
    }
    
    previousNotificationIdsRef.current = newUnreadIds;
  }, [notifications, soundEnabled]);

  return {
    notifications,
    pendingOrders,
    unreadCount,
    soundEnabled,
    loading,
    markAsRead,
    deleteNotification,
    clearNotifications,
    toggleSound,
    playNotificationSound: playSound,
    fetchNotifications
  };
}
