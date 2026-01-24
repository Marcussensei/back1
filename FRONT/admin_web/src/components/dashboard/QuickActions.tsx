import { Plus, FileText, Map, Download } from "lucide-react";
import { Button } from "@/components/ui/button";

const actions = [
  {
    icon: Plus,
    label: "Nouvel agent",
    description: "Ajouter un livreur",
    variant: "primary" as const,
  },
  {
    icon: FileText,
    label: "Rapport",
    description: "Générer un rapport",
    variant: "secondary" as const,
  },
  {
    icon: Map,
    label: "Carte",
    description: "Voir les positions",
    variant: "accent" as const,
  },
  {
    icon: Download,
    label: "Exporter",
    description: "Télécharger les données",
    variant: "outline" as const,
  },
];

export function QuickActions() {
  return (
    <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
      {actions.map((action, index) => (
        <Button
          key={action.label}
          variant={action.variant === "outline" ? "outline" : "default"}
          className={`h-auto py-4 flex flex-col items-center gap-2 animate-fade-in ${
            action.variant === "primary"
              ? "gradient-primary hover:shadow-glow"
              : action.variant === "secondary"
              ? "gradient-warm"
              : action.variant === "accent"
              ? "gradient-accent hover:shadow-glow"
              : "bg-card hover:bg-muted"
          }`}
          style={{ animationDelay: `${index * 100}ms` }}
        >
          <action.icon className="w-5 h-5" />
          <div className="text-center">
            <p className="font-medium text-sm">{action.label}</p>
            <p className="text-xs opacity-80">{action.description}</p>
          </div>
        </Button>
      ))}
    </div>
  );
}
