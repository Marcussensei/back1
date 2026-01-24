import { useState } from "react";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
  DialogDescription,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group";
import { Label } from "@/components/ui/label";
import { User, Truck, MapPin, Phone, CheckCircle2, Loader2 } from "lucide-react";
import { useAgents } from "@/hooks/useApi";

interface AssignAgentModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  delivery: {
    id: string;
    client: string;
    address: string;
    quantity: number;
    amount: number;
  } | null;
  onAssign: (deliveryId: string, agentId: string) => Promise<void>;
}

const availableAgents = [
  {
    id: "AG-001",
    name: "Kofi Mensah",
    initials: "KM",
    phone: "+228 90 12 34 56",
    tricycle: "LM 2345 TG",
    status: "available",
    currentDeliveries: 2,
    location: "Tokoin, Lomé",
  },
  {
    id: "AG-002",
    name: "Ama Diallo",
    initials: "AD",
    phone: "+228 91 23 45 67",
    tricycle: "LM 6789 TG",
    status: "busy",
    currentDeliveries: 4,
    location: "Bè, Lomé",
  },
  {
    id: "AG-003",
    name: "Emmanuel Kodjo",
    initials: "EK",
    phone: "+228 92 34 56 78",
    tricycle: "LM 9012 TG",
    status: "available",
    currentDeliveries: 1,
    location: "Grand Marché",
  },
  {
    id: "AG-004",
    name: "Fatou Bamba",
    initials: "FB",
    phone: "+228 93 45 67 89",
    tricycle: "LM 3456 TG",
    status: "available",
    currentDeliveries: 0,
    location: "Hédzranawoé",
  },
  {
    id: "AG-005",
    name: "Yao Adama",
    initials: "YA",
    phone: "+228 94 56 78 90",
    tricycle: "LM 7890 TG",
    status: "offline",
    currentDeliveries: 0,
    location: "Hors service",
  },
];

const statusConfig = {
  available: { label: "Disponible", className: "bg-success/10 text-success border-success/20" },
  busy: { label: "Occupé", className: "bg-warning/10 text-warning border-warning/20" },
  offline: { label: "Hors service", className: "bg-muted text-muted-foreground border-border" },
};

const AssignAgentModal = ({ open, onOpenChange, delivery, onAssign }: AssignAgentModalProps) => {
  const [selectedAgent, setSelectedAgent] = useState<string>("");
  const [isLoading, setIsLoading] = useState(false);
  const { data: agentsData, isLoading: agentsLoading } = useAgents();

  // Transform backend agents to frontend format
  // agentsData can be either an array or an object with agents property
  const agentsList = Array.isArray(agentsData) ? agentsData : (agentsData?.agents || []);
  const agents = agentsList.map((agent: any) => ({
    id: agent.id.toString(),
    name: agent.nom || agent.name || 'Agent inconnu',
    initials: (agent.nom || agent.name || '')
      .split(' ')
      .map((n: string) => n[0])
      .join('')
      .toUpperCase(),
    phone: agent.telephone || agent.phone || '',
    tricycle: agent.tricycle || 'N/A',
    status: agent.actif === false ? 'offline' : 'available',
    currentDeliveries: 0, // Could be calculated from deliveries API if needed
    location: agent.adresse || `${agent.latitude || 0}, ${agent.longitude || 0}`,
  })) || [];

  const handleAssign = async () => {
    if (delivery && selectedAgent) {
      try {
        setIsLoading(true);
        await onAssign(delivery.id, selectedAgent);
        setSelectedAgent("");
        onOpenChange(false);
      } catch (error) {
        console.error('Error assigning agent:', error);
      } finally {
        setIsLoading(false);
      }
    }
  };

  if (!delivery) return null;

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[600px] max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <User className="w-5 h-5 text-primary" />
            Assigner un livreur
          </DialogTitle>
          <DialogDescription>
            Sélectionnez un agent pour la livraison {delivery.id}
          </DialogDescription>
        </DialogHeader>

        {/* Delivery Info */}
        <div className="bg-muted/50 rounded-lg p-4 space-y-2">
          <div className="flex items-center justify-between">
            <span className="font-mono text-sm text-muted-foreground">{delivery.id}</span>
            <Badge variant="outline" className="bg-info/10 text-info border-info/20">
              En attente
            </Badge>
          </div>
          <p className="font-medium">{delivery.client}</p>
          <div className="flex items-center gap-2 text-sm text-muted-foreground">
            <MapPin className="w-4 h-4" />
            {delivery.address}
          </div>
          <div className="flex items-center gap-4 text-sm">
            <span><strong>{delivery.quantity}</strong> sachets</span>
            <span><strong>{delivery.amount.toLocaleString()}</strong> FCFA</span>
          </div>
        </div>

        {/* Agents List */}
        <div className="space-y-3">
          <h4 className="font-medium text-sm text-muted-foreground">Agents disponibles</h4>
          
          {agentsLoading ? (
            <div className="flex items-center justify-center py-8">
              <div className="flex flex-col items-center gap-2">
                <Loader2 className="w-6 h-6 animate-spin text-primary" />
                <p className="text-sm text-muted-foreground">Chargement des agents...</p>
              </div>
            </div>
          ) : agents.length === 0 ? (
            <div className="text-center py-8">
              <p className="text-sm text-muted-foreground">Aucun agent disponible</p>
            </div>
          ) : (
            <RadioGroup value={selectedAgent} onValueChange={setSelectedAgent} className="space-y-3">
              {agents.map((agent) => {
                const status = statusConfig[agent.status as keyof typeof statusConfig];
                const isDisabled = agent.status === "offline";
                
                return (
                  <div
                    key={agent.id}
                    className={`relative flex items-center gap-4 p-4 rounded-lg border transition-all ${
                      selectedAgent === agent.id
                        ? "border-primary bg-primary/5"
                        : "border-border hover:border-primary/50"
                    } ${isDisabled ? "opacity-50 cursor-not-allowed" : "cursor-pointer"}`}
                    onClick={() => !isDisabled && setSelectedAgent(agent.id)}
                  >
                    <RadioGroupItem
                      value={agent.id}
                      id={agent.id}
                      disabled={isDisabled}
                      className="sr-only"
                    />
                    
                    <Avatar className="w-12 h-12 border-2 border-primary/20">
                      <AvatarImage src="" />
                      <AvatarFallback className="bg-primary/10 text-primary font-medium">
                        {agent.initials}
                      </AvatarFallback>
                    </Avatar>

                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-1">
                        <Label htmlFor={agent.id} className="font-medium cursor-pointer">
                          {agent.name}
                        </Label>
                        <Badge variant="outline" className={status.className}>
                          {status.label}
                        </Badge>
                      </div>
                      
                      <div className="grid grid-cols-2 gap-2 text-sm text-muted-foreground">
                        <div className="flex items-center gap-1">
                          <Phone className="w-3 h-3" />
                          {agent.phone}
                        </div>
                        <div className="flex items-center gap-1">
                          <Truck className="w-3 h-3" />
                          {agent.tricycle}
                        </div>
                        <div className="flex items-center gap-1 col-span-2">
                          <MapPin className="w-3 h-3" />
                          {agent.location}
                        </div>
                      </div>
                    </div>

                    {selectedAgent === agent.id && (
                      <div className="absolute top-2 right-2">
                        <CheckCircle2 className="w-5 h-5 text-primary" />
                      </div>
                    )}
                  </div>
                );
              })}
            </RadioGroup>
          )}
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)} disabled={isLoading}>
            Annuler
          </Button>
          <Button
            className="gradient-primary"
            onClick={handleAssign}
            disabled={!selectedAgent || isLoading}
          >
            {isLoading ? (
              <>
                <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                Assignation en cours...
              </>
            ) : (
              "Assigner le livreur"
            )}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
};

export default AssignAgentModal;
