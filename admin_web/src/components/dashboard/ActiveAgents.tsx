import { MapPin, Phone, Truck } from "lucide-react";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";

interface Agent {
  id: string;
  nom: string;
  telephone: string;
  numero_tricycle: string;
  nombre_livraisons_completees: number;
  statut?: string;
  derniere_position?: string;
}

const defaultAgents: Agent[] = [
  {
    id: "AG-001",
    nom: "Kofi Mensah",
    telephone: "+228 90 12 34 56",
    numero_tricycle: "TO-1234-AA",
    nombre_livraisons_completees: 12,
    statut: "active",
    derniere_position: "Lomé, Bè Kpota",
  },
];

const statusConfig = {
  active: {
    label: "En tournée",
    className: "bg-success/10 text-success border-success/20",
    dot: "bg-success",
  },
  break: {
    label: "Pause",
    className: "bg-warning/10 text-warning border-warning/20",
    dot: "bg-warning",
  },
  inactive: {
    label: "Actif",
    className: "bg-success/20 text-success border-border/20",
    dot: "bg-muted-foreground",
  },
 
};

interface ActiveAgentsProps {
  agents?: Agent[];
}

export function ActiveAgents({ agents = defaultAgents }: ActiveAgentsProps) {
  return (
    <div className="bg-card rounded-xl shadow-md overflow-hidden">
      <div className="p-6 border-b border-border">
        <div className="flex items-center justify-between">
          <div>
            <h3 className="text-lg font-heading font-semibold">
              Agents actifs
            </h3>
            <p className="text-sm text-muted-foreground mt-1">
              Statut en temps réel
            </p>
          </div>
          <Badge className="gradient-primary border-0">
            {agents.filter((a) => a.statut === "active").length} en tournée
          </Badge>
        </div>
      </div>
      <div className="divide-y divide-border">
        {agents.map((agent, index) => {
          const initials = agent.nom
            .split(" ")
            .map((n) => n[0])
            .join("")
            .toUpperCase();
          const agentStatus = agent.statut || "inactive";
          return (
            <div
              key={agent.id}
              className="p-4 hover:bg-muted/30 transition-colors animate-fade-in"
              style={{ animationDelay: `${index * 100}ms` }}
            >
              <div className="flex items-center gap-4">
                <div className="relative">
                  <Avatar className="w-12 h-12 border-2 border-primary/20">
                    <AvatarImage src="" />
                    <AvatarFallback className="bg-primary text-primary-foreground font-medium">
                      {initials}
                    </AvatarFallback>
                  </Avatar>
                  <div
                    className={`absolute -bottom-0.5 -right-0.5 w-3 h-3 rounded-full border-2 border-card ${
                      statusConfig[agentStatus as keyof typeof statusConfig]
                        ?.dot || "bg-muted-foreground"
                    }`}
                  />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <p className="font-medium">{agent.nom}</p>
                    <Badge
                      variant="outline"
                      className={
                        statusConfig[agentStatus as keyof typeof statusConfig]
                          ?.className || "bg-muted/10"
                      }
                    >
                      {
                        statusConfig[agentStatus as keyof typeof statusConfig]
                          ?.label || "En tournée"
                      }
                    </Badge>
                  </div>
                  <div className="flex items-center gap-4 mt-1 text-sm text-muted-foreground">
                    <span className="flex items-center gap-1">
                      <Truck className="w-3 h-3" />
                      {agent.numero_tricycle || "N/A"}
                    </span>
                    <span className="flex items-center gap-1">
                      <MapPin className="w-3 h-3" />
                      {agent.derniere_position || "Position inconnue"}
                    </span>
                  </div>
                </div>
                <div className="text-right">
                  <p className="text-2xl font-heading font-bold text-primary">
                    {agent.nombre_livraisons_completees}
                  </p>
                  <p className="text-xs text-muted-foreground">livraisons</p>
                </div>
              </div>
            </div>
          );
        })}
      </div>
      <div className="p-4 border-t border-border bg-muted/30">
        <button className="text-sm text-primary font-medium hover:underline">
          Gérer les agents →
        </button>
      </div>
    </div>
  );
}
