import { useEffect, useRef, useState } from "react";
import { DashboardLayout } from "@/components/layout/DashboardLayout";
import { Badge } from "@/components/ui/badge";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import L from "leaflet";
import "leaflet/dist/leaflet.css";
import { MapPin, Package, Users, Truck, Navigation, RefreshCw } from "lucide-react";
import { useToast } from "@/hooks/use-toast";
import { useAgents } from "@/hooks/useApi";

// Fix for default markers
delete (L.Icon.Default.prototype as any)._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon-2x.png",
  iconUrl: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon.png",
  shadowUrl: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-shadow.png",
});

const statusColors = {
  delivered: "#22c55e",
  en_cours: "#3b82f6",
  livree: "#22c55e",
  probleme: "#ef4444",
  en_attente: "#f59e0b",
};

const statusLabels = {
  delivered: "Livrée",
  en_cours: "En cours",
  terminee: "Terminée",
  probleme: "Problème",
  en_attente: "En attente",
};

const Map = () => {
  const mapRef = useRef<HTMLDivElement>(null);
  const mapInstanceRef = useRef<L.Map | null>(null);
  const markersRef = useRef<L.Marker[]>([]);
  const [agents, setAgents] = useState<any[]>([]);
  const [deliveries, setDeliveries] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [lastUpdate, setLastUpdate] = useState<Date>(new Date());
  const [isRefreshing, setIsRefreshing] = useState(false);
  const { toast } = useToast();

  const fetchData = async () => {
    try {
      setIsRefreshing(true);
      
      // Fetch agents with real-time locations
      const agentsRes = await fetch('https://essivivi-project.onrender.com/agents/active-locations', {
        method: 'GET',
        headers: {
          'accept': 'application/json',
        },
        credentials: 'include',
      });

      if (agentsRes.ok) {
        const agentsData = await agentsRes.json();
        setAgents(agentsData || []);
      }

      // Fetch deliveries (livraisons)
      const deliveriesRes = await fetch('https://essivivi-project.onrender.com/livraisons/?per_page=100', {
        method: 'GET',
        headers: {
          'accept': 'application/json',
        },
        credentials: 'include',
      });

      if (deliveriesRes.ok) {
        const deliveriesData = await deliveriesRes.json();
        // Extract livraisons array from the response
        const livraisons = deliveriesData.livraisons || deliveriesData.data || [];
        setDeliveries(livraisons);
      }

      setLastUpdate(new Date());
      setIsRefreshing(false);
    } catch (error) {
      console.error("Error fetching data:", error);
      toast({
        title: "Erreur",
        description: "Impossible de récupérer les données.",
        variant: "destructive",
      });
      setIsRefreshing(false);
    }
  };

  // Initial data fetch
  useEffect(() => {
    setLoading(false); // Set to false immediately after mount
    fetchData();
  }, []);

  // Auto-refresh every 30 seconds
  useEffect(() => {
    const interval = setInterval(() => {
      fetchData();
    }, 30000);

    return () => clearInterval(interval);
  }, []);

  useEffect(() => {
    if (!mapRef.current) return;

    // Initialize map if not already initialized
    if (!mapInstanceRef.current) {
      const map = L.map(mapRef.current).setView([6.1319, 1.2228], 13);
      mapInstanceRef.current = map;

      // Add tile layer
      L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
        attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>',
      }).addTo(map);
    }

    const map = mapInstanceRef.current!;

    // Clear previous markers
    markersRef.current.forEach(marker => map.removeLayer(marker));
    markersRef.current = [];

    // Add markers for each delivery (livraisons)
    deliveries.forEach((delivery) => {
      // Use latitude and longitude from the delivery or from associated client
      const lat = delivery.latitude || delivery.client_latitude || 6.1319 + Math.random() * 0.05;
      const lng = delivery.longitude || delivery.client_longitude || 1.2228 + Math.random() * 0.05;
      
      if (lat && lng) {
        const color = statusColors[delivery.statut as keyof typeof statusColors] || "#9ca3af";
        
        const customIcon = L.divIcon({
          className: "custom-marker",
          html: `
            <div style="
              background-color: ${color};
              width: 32px;
              height: 32px;
              border-radius: 50%;
              border: 3px solid white;
              box-shadow: 0 2px 8px rgba(0,0,0,0.3);
              display: flex;
              align-items: center;
              justify-content: center;
            ">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="white" stroke="white" stroke-width="2">
                <path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z"/>
                <circle cx="12" cy="10" r="3"/>
              </svg>
            </div>
          `,
          iconSize: [32, 32],
          iconAnchor: [16, 32],
        });

        const marker = L.marker([lat, lng], { icon: customIcon }).addTo(map);
        markersRef.current.push(marker);
        
        marker.bindPopup(`
          <div style="min-width: 220px; padding: 8px;">
            <div style="font-weight: 600; font-size: 14px; margin-bottom: 8px;">Livraison #${delivery.id}</div>
            ${delivery.adresse_livraison ? `<div style="display: flex; align-items: center; gap: 8px; margin-bottom: 4px;">
              <span style="font-size: 12px; color: #666;">Adresse:</span>
              <span style="font-size: 12px;">${delivery.adresse_livraison}</span>
            </div>` : ''}
            ${delivery.montant_total ? `<div style="display: flex; align-items: center; gap: 8px; margin-bottom: 4px;">
              <span style="font-size: 12px; color: #666;">Montant:</span>
              <span style="font-size: 12px; font-weight: 500;">${delivery.montant_total}€</span>
            </div>` : ''}
            <div style="display: flex; align-items: center; gap: 8px;">
              <span style="font-size: 12px; color: #666;">Statut:</span>
              <span style="
                font-size: 11px;
                padding: 2px 8px;
                border-radius: 9999px;
                background-color: ${color}20;
                color: ${color};
                font-weight: 500;
              ">${statusLabels[delivery.statut as keyof typeof statusLabels] || delivery.statut}</span>
            </div>
          </div>
        `);
      }
    });

    // Add markers for agents (real-time locations)
    agents.forEach((agent) => {
      if (agent.latitude && agent.longitude) {
        const isActive = agent.statut === "actif" || agent.actif === true;
        const agentColor = isActive ? '#10b981' : '#6b7280';

        const agentIcon = L.divIcon({
          className: "custom-marker",
          html: `
            <div style="
              background-color: ${agentColor};
              width: 40px;
              height: 40px;
              border-radius: 50%;
              border: 3px solid white;
              box-shadow: 0 2px 8px rgba(0,0,0,0.3), 0 0 12px ${agentColor}40;
              display: flex;
              align-items: center;
              justify-content: center;
              position: relative;
            ">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="white" stroke="white" stroke-width="2">
                <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
                <circle cx="12" cy="7" r="4"/>
              </svg>
              ${isActive ? '<div style="position: absolute; top: -4px; right: -4px; width: 14px; height: 14px; background: #10b981; border: 2px solid white; border-radius: 50%; box-shadow: 0 0 8px #10b98160;"></div>' : ''}
            </div>
          `,
          iconSize: [40, 40],
          iconAnchor: [20, 40],
        });

        const marker = L.marker([agent.latitude, agent.longitude], { icon: agentIcon }).addTo(map);
        markersRef.current.push(marker);

        const minutesSince = agent.minutes_since_update ? Math.round(agent.minutes_since_update) : 0;

        marker.bindPopup(`
          <div style="min-width: 240px; padding: 10px;">
            <div style="font-weight: 600; font-size: 14px; margin-bottom: 8px;">${agent.name || agent.nom}</div>
            <div style="display: flex; align-items: center; gap: 8px; margin-bottom: 4px;">
              <span style="font-size: 12px; color: #666;">Téléphone:</span>
              <span style="font-size: 12px; font-family: monospace;">${agent.phone || agent.telephone}</span>
            </div>
            ${agent.tricycle ? `<div style="display: flex; align-items: center; gap: 8px; margin-bottom: 4px;">
              <span style="font-size: 12px; color: #666;">Tricycle:</span>
              <span style="font-size: 12px;">${agent.tricycle}</span>
            </div>` : ''}
            <div style="display: flex; align-items: center; gap: 8px; margin-bottom: 4px;">
              <span style="font-size: 12px; color: #666;">Coordonnées:</span>
              <span style="font-size: 11px; font-family: monospace;">${agent.latitude?.toFixed(4)}, ${agent.longitude?.toFixed(4)}</span>
            </div>
            <div style="display: flex; align-items: center; gap: 8px;">
              <span style="font-size: 12px; color: #666;">Statut:</span>
              <span style="
                font-size: 11px;
                padding: 3px 10px;
                border-radius: 9999px;
                background-color: ${isActive ? '#10b98120' : '#6b728020'};
                color: ${isActive ? '#10b981' : '#6b7280'};
                font-weight: 500;
              ">${isActive ? '● En ligne' : '○ Hors ligne'}</span>
            </div>
            <div style="border-top: 1px solid #e5e7eb; margin-top: 8px; padding-top: 8px; font-size: 11px; color: #999;">
              Dernière mise à jour: il y a ${minutesSince} min
            </div>
          </div>
        `);
      }
    });

    return () => {
      if (mapInstanceRef.current) {
        mapInstanceRef.current.remove();
        mapInstanceRef.current = null;
      }
    };
  }, [agents, deliveries, loading]);

  const stats = {
    totalDeliveries: deliveries.length,
    delivered: deliveries.filter((d) => d.statut === "livree" || d.statut === "delivered").length,
    inTransit: deliveries.filter((d) => d.statut === "en_cours").length,
    pending: deliveries.filter((d) => d.statut === "en_attente").length,
    problems: deliveries.filter((d) => d.statut === "probleme").length,
    totalAgents: agents.length,
    activeAgents: agents.filter((a) => a.statut === "actif" || a.actif === true).length,
    agentsWithLocation: agents.filter((a) => a.latitude && a.longitude).length,
  };

  return (
    <DashboardLayout
      title="Carte interactive"
      subtitle="Visualisez les positions des agents et livraisons en temps réel"
    >
      {/* Stats */}
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4 mb-6">
        <Card className="p-4 flex items-center gap-3">
          <div className="w-10 h-10 rounded-lg bg-primary/10 flex items-center justify-center">
            <Package className="w-5 h-5 text-primary" />
          </div>
          <div>
            <p className="text-2xl font-heading font-bold">{stats.totalDeliveries}</p>
            <p className="text-xs text-muted-foreground">Total livraisons</p>
          </div>
        </Card>
        <Card className="p-4 flex items-center gap-3">
          <div className="w-10 h-10 rounded-lg bg-success/10 flex items-center justify-center">
            <MapPin className="w-5 h-5 text-success" />
          </div>
          <div>
            <p className="text-2xl font-heading font-bold text-success">{stats.delivered}</p>
            <p className="text-xs text-muted-foreground">Livrées</p>
          </div>
        </Card>
        <Card className="p-4 flex items-center gap-3">
          <div className="w-10 h-10 rounded-lg bg-info/10 flex items-center justify-center">
            <Truck className="w-5 h-5 text-info" />
          </div>
          <div>
            <p className="text-2xl font-heading font-bold text-info">{stats.inTransit}</p>
            <p className="text-xs text-muted-foreground">En cours</p>
          </div>
        </Card>
        <Card className="p-4 flex items-center gap-3">
          <div className="w-10 h-10 rounded-lg bg-warning/10 flex items-center justify-center">
            <Navigation className="w-5 h-5 text-warning" />
          </div>
          <div>
            <p className="text-2xl font-heading font-bold text-warning">{stats.pending}</p>
            <p className="text-xs text-muted-foreground">En attente</p>
          </div>
        </Card>
        <Card className="p-4 flex items-center gap-3">
          <div className="w-10 h-10 rounded-lg bg-secondary/10 flex items-center justify-center">
            <Users className="w-5 h-5 text-secondary" />
          </div>
          <div>
            <p className="text-2xl font-heading font-bold text-secondary">{stats.totalAgents}</p>
            <p className="text-xs text-muted-foreground">Total agents</p>
          </div>
        </Card>
        <Card className="p-4 flex items-center gap-3">
          <div className="w-10 h-10 rounded-lg bg-accent/10 flex items-center justify-center">
            <MapPin className="w-5 h-5 text-accent" />
          </div>
          <div>
            <p className="text-2xl font-heading font-bold text-accent">{stats.agentsWithLocation}</p>
            <p className="text-xs text-muted-foreground">Agents localisés</p>
          </div>
        </Card>
      </div>

      {/* Legend */}
      <div className="flex flex-wrap gap-4 mb-4">
        <div className="flex items-center gap-2">
          <div className="w-4 h-4 rounded-full bg-success" />
          <span className="text-sm text-muted-foreground">Livrée</span>
        </div>
        <div className="flex items-center gap-2">
          <div className="w-4 h-4 rounded-full bg-info" />
          <span className="text-sm text-muted-foreground">En cours</span>
        </div>
        <div className="flex items-center gap-2">
          <div className="w-4 h-4 rounded-full bg-warning" />
          <span className="text-sm text-muted-foreground">En attente</span>
        </div>
      </div>

      {/* Map */}
      <div className="bg-card rounded-xl shadow-md overflow-hidden">
        <div ref={mapRef} className="h-[500px] w-full" />
      </div>

      {/* Deliveries List */}
      <div className="mt-6">
        <h3 className="text-lg font-semibold mb-4">Livraisons sur la carte</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          {deliveries.length > 0 ? (
            deliveries.map((delivery) => {
              // Map backend status values to color classes
              let statusColor = "bg-warning/10 text-warning border-warning/20"; // default en_attente
              if (delivery.statut === "livree") {
                statusColor = "bg-success/10 text-success border-success/20";
              } else if (delivery.statut === "en_cours") {
                statusColor = "bg-info/10 text-info border-info/20";
              } else if (delivery.statut === "probleme") {
                statusColor = "bg-destructive/10 text-destructive border-destructive/20";
              }

              const statusLabel = {
                terminee: "Livrée",
                en_cours: "En cours",
                en_attente: "En attente",
                probleme: "Problème",
              }[delivery.statut] || delivery.statut;

              return (
                <Card key={delivery.id} className="p-4">
                  <div className="flex items-start justify-between mb-2">
                    <span className="font-mono text-xs text-muted-foreground">#{delivery.id}</span>
                    <Badge variant="outline" className={statusColor}>
                      {statusLabel}
                    </Badge>
                  </div>
                  <p className="font-medium text-sm mb-1 truncate">{delivery.adresse_livraison}</p>
                  <p className="text-xs text-muted-foreground mb-2">
                    {delivery.montant_total && `${delivery.montant_total.toFixed(2)} DA`}
                  </p>
                  {delivery.agent_name && (
                    <p className="text-xs text-muted-foreground">Agent: {delivery.agent_name}</p>
                  )}
                </Card>
              );
            })
          ) : (
            <div className="col-span-full text-center py-8 text-muted-foreground">
              Aucune livraison disponible
            </div>
          )}
        </div>
      </div>
    </DashboardLayout>
  );
};

export default Map;
