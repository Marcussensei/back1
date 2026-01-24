import { MapPin, Clock, Package } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";

interface Delivery {
  id: string;
  nom_client: string;
  agent_nom: string;
  quantite: number;
  montant: number;
  heure_livraison: string;
  statut: string;
  adresse_client?: string;
}

const defaultDeliveries: Delivery[] = [
  {
    id: "LIV-001",
    nom_client: "Point de Vente Akwa",
    agent_nom: "Kofi Mensah",
    quantite: 50,
    montant: 25000,
    heure_livraison: "10:30",
    statut: "completed",
    adresse_client: "Lomé, Quartier Bè",
  },
];

const statusConfig = {
  completed: {
    label: "Livré",
    className: "bg-success/10 text-success border-success/20",
  },
  in_progress: {
    label: "En cours",
    className: "bg-warning/10 text-warning border-warning/20",
  },
  pending: {
    label: "En attente",
    className: "bg-muted text-muted-foreground border-border",
  },
};

interface RecentDeliveriesProps {
  deliveries?: Delivery[];
}

export function RecentDeliveries({
  deliveries = defaultDeliveries,
}: RecentDeliveriesProps) {
  return (
    <div className="bg-card rounded-xl shadow-md overflow-hidden">
      <div className="p-6 border-b border-border">
        <h3 className="text-lg font-heading font-semibold">
          Livraisons récentes
        </h3>
        <p className="text-sm text-muted-foreground mt-1">
          Dernières activités de livraison
        </p>
      </div>
      <div className="divide-y divide-border">
        {deliveries.map((delivery, index) => {
          const agentInitials = delivery.agent_nom
            .split(" ")
            .map((n) => n[0])
            .join("")
            .toUpperCase();
          const statusMap: Record<string, keyof typeof statusConfig> = {
            completed: "completed",
            in_progress: "in_progress",
            pending: "pending",
            enCours: "in_progress",
          };
          const deliveryStatus = statusMap[delivery.statut] || "pending";
          return (
            <div
              key={delivery.id}
              className="p-4 hover:bg-muted/30 transition-colors animate-fade-in"
              style={{ animationDelay: `${index * 100}ms` }}
            >
              <div className="flex items-start gap-4">
                <Avatar className="w-10 h-10 border-2 border-primary/20">
                  <AvatarImage src="" />
                  <AvatarFallback className="bg-primary/10 text-primary text-sm font-medium">
                    {agentInitials}
                  </AvatarFallback>
                </Avatar>
                <div className="flex-1 min-w-0">
                  <div className="flex items-start justify-between gap-4">
                    <div>
                      <p className="font-medium text-sm">{delivery.agent_nom}</p>
                      <p className="text-sm text-muted-foreground">
                        {delivery.nom_client}
                      </p>
                    </div>
                    <Badge
                      variant="outline"
                      className={
                        statusConfig[deliveryStatus]?.className ||
                        "bg-muted/10"
                      }
                    >
                      {statusConfig[deliveryStatus]?.label || "Inconnue"}
                    </Badge>
                  </div>
                  <div className="flex items-center gap-4 mt-2 text-xs text-muted-foreground">
                    <span className="flex items-center gap-1">
                      <Package className="w-3 h-3" />
                      {delivery.quantite} sachets
                    </span>
                    <span className="flex items-center gap-1">
                      <Clock className="w-3 h-3" />
                      {delivery.heure_livraison}
                    </span>
                    {delivery.adresse_client && (
                      <span className="flex items-center gap-1 truncate">
                        <MapPin className="w-3 h-3" />
                        {delivery.adresse_client}
                      </span>
                    )}
                  </div>
                </div>
                <div className="text-right">
                  <p className="font-semibold text-sm">
                    {delivery.montant.toLocaleString()} FCFA
                  </p>
                </div>
              </div>
            </div>
          );
        })}
      </div>
      <div className="p-4 border-t border-border bg-muted/30">
        <button className="text-sm text-primary font-medium hover:underline">
          Voir toutes les livraisons →
        </button>
      </div>
    </div>
  );
}
