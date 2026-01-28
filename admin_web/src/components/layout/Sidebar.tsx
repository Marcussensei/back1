import { Link, useLocation } from "react-router-dom";
import {
  LayoutDashboard,
  Users,
  Store,
  Truck,
  BarChart3,
  Settings,
  LogOut,
  Droplets,
  ChevronLeft,
  Menu,
  Bike,
  MapIcon,
  ShoppingCart,
  Package,
} from "lucide-react";
import { cn } from "@/lib/utils";
import { useState } from "react";

const navItems = [
  { icon: LayoutDashboard, label: "Tableau de bord", href: "/" },
  { icon: Users, label: "Agents", href: "/agents" },
  { icon: Store, label: "Clients", href: "/clients" },
  { icon: ShoppingCart, label: "Commandes", href: "/orders" },
  { icon: Package, label: "Produits", href: "/products" },
  { icon: Truck, label: "Livraisons", href: "/deliveries" },
  // { icon: Bike, label: "Tricycles", href: "/tricycles" },
  { icon: MapIcon, label: "Carte", href: "/map" },
  { icon: BarChart3, label: "Rapports", href: "/reports" },
  { icon: Settings, label: "Paramètres", href: "/settings" },
];

export function Sidebar() {
  const location = useLocation();
  const [collapsed, setCollapsed] = useState(false);

  return (
    <aside
      className={cn(
        "fixed left-0 top-0 h-screen bg-sidebar flex flex-col transition-all duration-300 z-50",
        collapsed ? "w-20" : "w-64"
      )}
    >
      {/* Logo */}
      <div className="p-6 border-b border-sidebar-border">
        <Link to="/" className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl gradient-primary flex items-center justify-center shadow-glow">
            <Droplets className="w-6 h-6 text-primary-foreground" />
          </div>
          {!collapsed && (
            <div className="animate-fade-in">
              <h1 className="text-xl font-heading font-bold text-sidebar-foreground">
                ESSIVIVI
              </h1>
              <p className="text-xs text-sidebar-foreground/60">
                Gestion des livraisons
              </p>
            </div>
          )}
        </Link>
      </div>

      {/* Toggle Button */}
      <button
        onClick={() => setCollapsed(!collapsed)}
        className="absolute -right-3 top-20 w-6 h-6 bg-primary rounded-full flex items-center justify-center text-primary-foreground shadow-lg hover:shadow-glow transition-shadow"
      >
        {collapsed ? (
          <Menu className="w-3 h-3" />
        ) : (
          <ChevronLeft className="w-3 h-3" />
        )}
      </button>

      {/* Navigation */}
      <nav className="flex-1 p-4 space-y-2 overflow-y-auto">
        {navItems.map((item, index) => {
          const isActive = location.pathname === item.href;
          return (
            <Link
              key={item.href}
              to={item.href}
              className={cn(
                "sidebar-nav-item",
                isActive && "active",
                "animate-slide-in-left"
              )}
              style={{ animationDelay: `${index * 50}ms` }}
            >
              <item.icon className="w-5 h-5 flex-shrink-0" />
              {!collapsed && <span>{item.label}</span>}
            </Link>
          );
        })}
      </nav>

      {/* Footer */}
      <div className="p-4 border-t border-sidebar-border">
        <Link
          to="/auth"
          className={cn(
            "sidebar-nav-item w-full text-destructive/80 hover:text-destructive hover:bg-destructive/10",
            collapsed && "justify-center"
          )}
        >
          <LogOut className="w-5 h-5 flex-shrink-0" />
          {!collapsed && <span>Déconnexion</span>}
        </Link>
      </div>
    </aside>
  );
}
