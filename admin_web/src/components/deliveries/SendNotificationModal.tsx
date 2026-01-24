import { useState } from "react";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group";
import { MessageSquare, Phone, Mail, Send, Copy, Check } from "lucide-react";
import { toast } from "sonner";

export interface NotificationRecord {
  id: string;
  type: "sms" | "whatsapp" | "email";
  message: string;
  sentAt: Date;
  status: "sent" | "delivered" | "failed";
}

interface SendNotificationModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  delivery: {
    id: string;
    client: string;
    clientPhone: string;
    address: string;
    status: string;
  };
  onNotificationSent?: (notification: NotificationRecord) => void;
}

export const SendNotificationModal = ({
  open,
  onOpenChange,
  delivery,
  onNotificationSent,
}: SendNotificationModalProps) => {
  const [notificationType, setNotificationType] = useState<"sms" | "whatsapp" | "email">("sms");
  const [copied, setCopied] = useState(false);

  const trackingUrl = `${window.location.origin}/track/${delivery.id}`;
  
  const defaultMessage = `Bonjour,\n\nVotre commande ${delivery.id} est en cours de livraison vers ${delivery.address}.\n\nSuivez votre livraison en temps réel ici :\n${trackingUrl}\n\nMerci de votre confiance !`;

  const [message, setMessage] = useState(defaultMessage);

  const handleCopyLink = () => {
    navigator.clipboard.writeText(trackingUrl);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
    toast.success("Lien de suivi copié !");
  };

  const handleSend = () => {
    const notification: NotificationRecord = {
      id: `notif-${Date.now()}`,
      type: notificationType,
      message: message,
      sentAt: new Date(),
      status: "delivered",
    };
    
    onNotificationSent?.(notification);
    
    toast.success(
      notificationType === "sms"
        ? "SMS envoyé au client !"
        : notificationType === "whatsapp"
        ? "Message WhatsApp envoyé !"
        : "Email envoyé au client !"
    );
    onOpenChange(false);
  };

  const handleOpenWhatsApp = () => {
    const encodedMessage = encodeURIComponent(message);
    const phone = delivery.clientPhone.replace(/\s/g, "").replace("+", "");
    window.open(`https://wa.me/${phone}?text=${encodedMessage}`, "_blank");
    toast.success("WhatsApp ouvert avec le message pré-rempli");
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <MessageSquare className="w-5 h-5 text-primary" />
            Notifier le client
          </DialogTitle>
        </DialogHeader>

        <div className="space-y-4">
          {/* Client Info */}
          <div className="p-3 bg-muted/50 rounded-lg">
            <p className="font-medium">{delivery.client}</p>
            <p className="text-sm text-muted-foreground">{delivery.clientPhone}</p>
          </div>

          {/* Notification Type */}
          <div className="space-y-2">
            <Label>Type de notification</Label>
            <RadioGroup
              value={notificationType}
              onValueChange={(value) => setNotificationType(value as "sms" | "whatsapp" | "email")}
              className="flex gap-4"
            >
              <div className="flex items-center space-x-2">
                <RadioGroupItem value="sms" id="sms" />
                <Label htmlFor="sms" className="flex items-center gap-1 cursor-pointer">
                  <Phone className="w-4 h-4" />
                  SMS
                </Label>
              </div>
              <div className="flex items-center space-x-2">
                <RadioGroupItem value="whatsapp" id="whatsapp" />
                <Label htmlFor="whatsapp" className="flex items-center gap-1 cursor-pointer">
                  <MessageSquare className="w-4 h-4" />
                  WhatsApp
                </Label>
              </div>
              <div className="flex items-center space-x-2">
                <RadioGroupItem value="email" id="email" />
                <Label htmlFor="email" className="flex items-center gap-1 cursor-pointer">
                  <Mail className="w-4 h-4" />
                  Email
                </Label>
              </div>
            </RadioGroup>
          </div>

          {/* Tracking Link */}
          <div className="space-y-2">
            <Label>Lien de suivi</Label>
            <div className="flex gap-2">
              <div className="flex-1 p-2 bg-muted rounded-md text-sm truncate">
                {trackingUrl}
              </div>
              <Button variant="outline" size="icon" onClick={handleCopyLink}>
                {copied ? (
                  <Check className="w-4 h-4 text-success" />
                ) : (
                  <Copy className="w-4 h-4" />
                )}
              </Button>
            </div>
          </div>

          {/* Message */}
          <div className="space-y-2">
            <Label>Message</Label>
            <Textarea
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              rows={6}
              className="resize-none"
            />
          </div>
        </div>

        <DialogFooter className="flex-col sm:flex-row gap-2">
          {notificationType === "whatsapp" && (
            <Button
              variant="outline"
              onClick={handleOpenWhatsApp}
              className="gap-2 bg-green-500/10 border-green-500/20 text-green-600 hover:bg-green-500/20"
            >
              <MessageSquare className="w-4 h-4" />
              Ouvrir WhatsApp
            </Button>
          )}
          <Button onClick={handleSend} className="gap-2">
            <Send className="w-4 h-4" />
            Envoyer
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
};
