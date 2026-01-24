import { useState } from "react";
import { Bell, X, Check, Trash2 } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogClose,
} from "@/components/ui/dialog";
import { cn } from "@/lib/utils";

interface Notification {
  id: number;
  type: string;
  title: string;
  message: string;
  read: boolean;
  created_at?: string;
  timestamp?: string;
  data?: any;
}

interface NotificationCenterProps {
  notifications: Notification[];
  unreadCount: number;
  onMarkAsRead: (id: number) => void;
  onDelete: (id: number) => void;
  onClear: () => void;
}

export function NotificationCenter({
  notifications,
  unreadCount,
  onMarkAsRead,
  onDelete,
  onClear,
}: NotificationCenterProps) {
  const [open, setOpen] = useState(false);
  const [selectedNotification, setSelectedNotification] = useState<Notification | null>(null);
  const [modalOpen, setModalOpen] = useState(false);

  const getNotificationIcon = (type: string) => {
    switch (type) {
      case "new_order":
        return "📦";
      case "status_change":
        return "📍";
      case "agent_assignment":
        return "👤";
      default:
        return "🔔";
    }
  };

  const formatTime = (dateString: string | undefined) => {
    if (!dateString) return "À l'instant";
    const date = new Date(dateString);
    const now = new Date();
    const diff = now.getTime() - date.getTime();
    const minutes = Math.floor(diff / 60000);
    const hours = Math.floor(diff / 3600000);

    if (minutes < 1) return "À l'instant";
    if (minutes < 60) return `${minutes}m`;
    if (hours < 24) return `${hours}h`;
    return date.toLocaleDateString("fr-FR");
  };

  const handleNotificationClick = (notification: Notification) => {
    setSelectedNotification(notification);
    setModalOpen(true);
  };

  const handleModalClose = async () => {
    if (selectedNotification) {
      // Supprimer la notification à la fermeture du modal
      await onDelete(selectedNotification.id);
    }
    setModalOpen(false);
    setSelectedNotification(null);
  };

  return (
    <DropdownMenu open={open} onOpenChange={setOpen}>
      <DropdownMenuTrigger asChild>
        <Button
          variant="ghost"
          size="icon"
          className="relative"
          aria-label="Notifications"
        >
          <Bell className="w-5 h-5" />
          {unreadCount > 0 && (
            <Badge
              className="absolute -top-2 -right-2 w-5 h-5 p-0 flex items-center justify-center text-xs bg-red-500 text-white"
              variant="destructive"
            >
              {unreadCount > 9 ? "9+" : unreadCount}
            </Badge>
          )}
        </Button>
      </DropdownMenuTrigger>

      <DropdownMenuContent align="end" className="w-96 max-h-96 overflow-y-auto">
        <DropdownMenuLabel className="flex items-center justify-between">
          <span>Notifications</span>
          {unreadCount > 0 && (
            <Badge variant="secondary" className="ml-auto">
              {unreadCount} nouveau
            </Badge>
          )}
        </DropdownMenuLabel>
        <DropdownMenuSeparator />

        {notifications.length === 0 ? (
          <div className="p-4 text-center text-sm text-muted-foreground">
            Aucune notification
          </div>
        ) : (
          <div className="space-y-2 max-h-80 overflow-y-auto">
            {notifications.map((notification) => (
              <div
                key={notification.id}
                className={cn(
                  "p-3 rounded-lg border cursor-pointer transition-colors",
                  notification.read
                    ? "bg-muted/30 border-border"
                    : "bg-blue-50 border-blue-200 dark:bg-blue-900/10 dark:border-blue-800"
                )}
                onClick={() => handleNotificationClick(notification)}
              >
                <div className="flex gap-3">
                  <span className="text-lg mt-1">
                    {getNotificationIcon(notification.type)}
                  </span>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-start justify-between gap-2">
                      <p className="font-medium text-sm truncate">
                        {notification.title}
                      </p>
                      {!notification.read && (
                        <span className="w-2 h-2 bg-blue-500 rounded-full mt-1 flex-shrink-0"></span>
                      )}
                    </div>
                    <p className="text-xs text-muted-foreground mt-1 line-clamp-2">
                      {notification.message}
                    </p>
                    <p className="text-xs text-muted-foreground mt-2">
                      {formatTime(notification.timestamp || notification.created_at)}
                    </p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}

        {notifications.length > 0 && (
          <>
            <DropdownMenuSeparator />
            <div className="p-2 flex gap-2">
              <Button
                variant="outline"
                size="sm"
                className="flex-1 text-xs"
                onClick={() => {
                  notifications
                    .filter((n) => !n.read)
                    .forEach((n) => onMarkAsRead(n.id));
                }}
              >
                <Check className="w-3 h-3 mr-1" />
                Tout marquer
              </Button>
              <Button
                variant="ghost"
                size="sm"
                className="flex-1 text-xs"
                onClick={() => onClear()}
              >
                <Trash2 className="w-3 h-3 mr-1" />
                Effacer
              </Button>
            </div>
          </>
        )}
      </DropdownMenuContent>

      {/* Modal pour afficher les détails de la notification */}
      <Dialog open={modalOpen} onOpenChange={handleModalClose}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <div className="flex items-center gap-3">
              <span className="text-2xl">
                {selectedNotification && getNotificationIcon(selectedNotification.type)}
              </span>
              <div>
                <DialogTitle>{selectedNotification?.title}</DialogTitle>
              </div>
            </div>
          </DialogHeader>

          {selectedNotification && (
            <div className="space-y-4">
              <div>
                <p className="text-sm text-muted-foreground mb-1">Message</p>
                <p className="text-sm">{selectedNotification.message}</p>
              </div>

              {selectedNotification.data && (
                <div className="bg-muted p-3 rounded-lg space-y-2">
                  {selectedNotification.data.commande_id && (
                    <div className="text-sm">
                      <span className="text-muted-foreground">Commande ID:</span>
                      <span className="ml-2 font-medium">#{selectedNotification.data.commande_id}</span>
                    </div>
                  )}
                  {selectedNotification.data.client_id && (
                    <div className="text-sm">
                      <span className="text-muted-foreground">Client ID:</span>
                      <span className="ml-2 font-medium">{selectedNotification.data.client_id}</span>
                    </div>
                  )}
                  {selectedNotification.data.montant_total && (
                    <div className="text-sm">
                      <span className="text-muted-foreground">Montant:</span>
                      <span className="ml-2 font-medium">{selectedNotification.data.montant_total}€</span>
                    </div>
                  )}
                  {selectedNotification.data.livraison_id && (
                    <div className="text-sm">
                      <span className="text-muted-foreground">Livraison ID:</span>
                      <span className="ml-2 font-medium">{selectedNotification.data.livraison_id}</span>
                    </div>
                  )}
                </div>
              )}

              <div className="text-xs text-muted-foreground">
                {formatTime(selectedNotification.timestamp || selectedNotification.created_at)}
              </div>

              <div className="flex gap-2 pt-2">
                <Button
                  variant="outline"
                  className="flex-1"
                  onClick={handleModalClose}
                >
                  Fermer
                </Button>
              </div>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </DropdownMenu>
  );
}
