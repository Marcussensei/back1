import { Search, User, Volume2, VolumeX, LogOut } from "lucide-react";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { useOrderNotifications } from "@/hooks/useOrderNotifications";
import { useNotificationSound } from "@/hooks/useNotificationSound";
import { useAuth } from "@/hooks/useAuth";
import { useNavigate } from "react-router-dom";
import { cn } from "@/lib/utils";
import { NotificationCenter } from "@/components/notifications/NotificationCenter";

interface HeaderProps {
  title: string;
  subtitle?: string;
}

export function Header({ title, subtitle }: HeaderProps) {
  const { 
    notifications,
    unreadCount, 
    markAsRead,
    deleteNotification,
    clearNotifications,
    playNotificationSound 
  } = useOrderNotifications();
  const { soundEnabled, toggleSound } = useNotificationSound();
  const { user, logout, error } = useAuth();
  const navigate = useNavigate();

  console.log('Header: Render - user:', !!user, 'error:', error);

  const handleLogout = () => {
    console.log('Header: Logout clicked');
    logout();
    navigate('/auth', { replace: true });
  };

  return (
    <header className="sticky top-0 z-40 bg-background/80 backdrop-blur-lg border-b border-border">
      <div className="flex items-center justify-between px-8 py-4">
        {/* Title */}
        <div>
          <h1 className="text-2xl font-heading font-bold text-foreground">
            {title}
          </h1>
          {subtitle && (
            <p className="text-sm text-muted-foreground mt-0.5">{subtitle}</p>
          )}
        </div>

        {/* Actions */}
        <div className="flex items-center gap-4">
          {/* Search */}
          <div className="relative hidden md:block">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
            <Input
              placeholder="Rechercher..."
              className="pl-10 w-64 bg-muted/50 border-0 focus-visible:ring-primary/30"
            />
          </div>

          {/* Sound Toggle */}
          <Button 
            variant="ghost" 
            size="icon" 
            onClick={toggleSound}
            className="text-muted-foreground hover:text-foreground"
            title={soundEnabled ? "Désactiver le son" : "Activer le son"}
          >
            {soundEnabled ? <Volume2 className="w-5 h-5" /> : <VolumeX className="w-5 h-5" />}
          </Button>

          {/* Notification Center */}
          <NotificationCenter
            notifications={notifications}
            unreadCount={unreadCount}
            onMarkAsRead={markAsRead}
            onDelete={deleteNotification}
            onClear={clearNotifications}
          />

          {/* Profile */}
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="ghost" className="gap-3 px-2">
                <Avatar className="w-9 h-9 border-2 border-primary/20">
                  <AvatarImage src="" />
                  <AvatarFallback className="bg-primary text-primary-foreground font-medium">
                    {user?.nom ? user.nom.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2) : 'U'}
                  </AvatarFallback>
                </Avatar>
                <div className="hidden md:block text-left">
                  <p className="text-sm font-medium">{user?.nom || 'Utilisateur'}</p>
                  <p className="text-xs text-muted-foreground capitalize">{user?.role || 'Chargement...'}</p>
                </div>
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end" className="w-56">
              <DropdownMenuLabel>Mon compte</DropdownMenuLabel>
              <DropdownMenuSeparator />
              <DropdownMenuItem>
                <User className="mr-2 h-4 w-4" />
                Profil
              </DropdownMenuItem>
              <DropdownMenuItem>Paramètres</DropdownMenuItem>
              <DropdownMenuSeparator />
              <DropdownMenuItem className="text-destructive" onClick={handleLogout}>
                <LogOut className="mr-2 h-4 w-4" />
                Déconnexion
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
        </div>
      </div>
    </header>
  );
}
