import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { ScrollArea } from "@/components/ui/scroll-area";
import { Bell, Phone, MessageSquare, Mail, Check, Clock } from "lucide-react";
import { cn } from "@/lib/utils";

export interface NotificationRecord {
  id: string;
  type: "sms" | "whatsapp" | "email";
  message: string;
  sentAt: Date;
  status: "sent" | "delivered" | "failed";
}

interface NotificationHistoryProps {
  notifications: NotificationRecord[];
}

const typeConfig = {
  sms: {
    icon: Phone,
    label: "SMS",
    className: "bg-blue-500/10 text-blue-600 border-blue-500/20",
  },
  whatsapp: {
    icon: MessageSquare,
    label: "WhatsApp",
    className: "bg-green-500/10 text-green-600 border-green-500/20",
  },
  email: {
    icon: Mail,
    label: "Email",
    className: "bg-purple-500/10 text-purple-600 border-purple-500/20",
  },
};

const statusConfig = {
  sent: {
    icon: Clock,
    label: "Envoyé",
    className: "text-warning",
  },
  delivered: {
    icon: Check,
    label: "Remis",
    className: "text-success",
  },
  failed: {
    icon: Clock,
    label: "Échec",
    className: "text-destructive",
  },
};

export const NotificationHistory = ({ notifications }: NotificationHistoryProps) => {
  const formatTime = (date: Date) => {
    return new Intl.DateTimeFormat("fr-FR", {
      hour: "2-digit",
      minute: "2-digit",
      day: "2-digit",
      month: "2-digit",
    }).format(date);
  };

  if (notifications.length === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="text-base flex items-center gap-2">
            <Bell className="w-4 h-4 text-primary" />
            Historique des notifications
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="text-center py-6 text-muted-foreground">
            <Bell className="w-10 h-10 mx-auto mb-2 opacity-50" />
            <p className="text-sm">Aucune notification envoyée</p>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base flex items-center gap-2">
          <Bell className="w-4 h-4 text-primary" />
          Historique des notifications
          <Badge variant="secondary" className="ml-auto">
            {notifications.length}
          </Badge>
        </CardTitle>
      </CardHeader>
      <CardContent className="p-0">
        <ScrollArea className="h-[300px]">
          <div className="divide-y">
            {notifications.map((notification) => {
              const typeInfo = typeConfig[notification.type];
              const statusInfo = statusConfig[notification.status];
              const TypeIcon = typeInfo.icon;
              const StatusIcon = statusInfo.icon;

              return (
                <div
                  key={notification.id}
                  className="p-4 hover:bg-muted/50 transition-colors"
                >
                  <div className="flex items-start gap-3">
                    <div
                      className={cn(
                        "w-8 h-8 rounded-full flex items-center justify-center flex-shrink-0",
                        typeInfo.className
                      )}
                    >
                      <TypeIcon className="w-4 h-4" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-1">
                        <Badge variant="outline" className={typeInfo.className}>
                          {typeInfo.label}
                        </Badge>
                        <span className={cn("flex items-center gap-1 text-xs", statusInfo.className)}>
                          <StatusIcon className="w-3 h-3" />
                          {statusInfo.label}
                        </span>
                        <span className="text-xs text-muted-foreground ml-auto">
                          {formatTime(notification.sentAt)}
                        </span>
                      </div>
                      <p className="text-sm text-muted-foreground line-clamp-2">
                        {notification.message}
                      </p>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </ScrollArea>
      </CardContent>
    </Card>
  );
};
