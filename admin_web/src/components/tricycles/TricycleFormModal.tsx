import { useState } from "react";
import { format } from "date-fns";
import { fr } from "date-fns/locale";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover";
import { Calendar } from "@/components/ui/calendar";
import { cn } from "@/lib/utils";
import { Bike, CalendarIcon } from "lucide-react";

interface TricycleFormModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  tricycle?: {
    id: string;
    plate: string;
    agent: string;
    status: string;
    fuel: number;
    mileage: number;
    lastMaintenance: string;
    nextMaintenance: string;
    location: string;
  };
  mode: "create" | "edit";
}

const agents = [
  { id: "none", label: "Non assigné" },
  { id: "AG-001", label: "Kofi Mensah" },
  { id: "AG-002", label: "Ama Kouassi" },
  { id: "AG-003", label: "Yao Agbeko" },
  { id: "AG-004", label: "Akouvi Dosseh" },
  { id: "AG-005", label: "Emmanuel Kodjo" },
];

const statusOptions = [
  { id: "active", label: "En service" },
  { id: "available", label: "Disponible" },
  { id: "maintenance", label: "En maintenance" },
  { id: "warning", label: "Attention requise" },
];

const TricycleFormModal = ({ open, onOpenChange, tricycle, mode }: TricycleFormModalProps) => {
  const [formData, setFormData] = useState({
    plate: tricycle?.plate || "",
    agent: tricycle?.agent || "none",
    status: tricycle?.status || "available",
    fuel: tricycle?.fuel?.toString() || "100",
    mileage: tricycle?.mileage?.toString() || "0",
    location: tricycle?.location || "",
  });

  const [lastMaintenance, setLastMaintenance] = useState<Date | undefined>(
    tricycle?.lastMaintenance ? new Date(tricycle.lastMaintenance) : undefined
  );
  const [nextMaintenance, setNextMaintenance] = useState<Date | undefined>(
    tricycle?.nextMaintenance && tricycle.nextMaintenance !== "En cours" 
      ? new Date(tricycle.nextMaintenance) 
      : undefined
  );

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    console.log("Form submitted:", {
      ...formData,
      fuel: parseInt(formData.fuel),
      mileage: parseInt(formData.mileage),
      lastMaintenance: lastMaintenance?.toISOString(),
      nextMaintenance: nextMaintenance?.toISOString(),
    });
    onOpenChange(false);
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[550px]">
        <DialogHeader>
          <DialogTitle>
            {mode === "create" ? "Nouveau tricycle" : "Modifier le tricycle"}
          </DialogTitle>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-6">
          {/* Icon */}
          <div className="flex justify-center">
            <div className="w-20 h-20 rounded-2xl bg-primary/10 flex items-center justify-center">
              <Bike className="w-10 h-10 text-primary" />
            </div>
          </div>

          {/* Plate and Status */}
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="plate">Plaque d'immatriculation *</Label>
              <Input
                id="plate"
                placeholder="Ex: LM 1234 TG"
                value={formData.plate}
                onChange={(e) =>
                  setFormData({ ...formData, plate: e.target.value })
                }
                required
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="status">Statut *</Label>
              <Select
                value={formData.status}
                onValueChange={(value) =>
                  setFormData({ ...formData, status: value })
                }
              >
                <SelectTrigger>
                  <SelectValue placeholder="Sélectionner" />
                </SelectTrigger>
                <SelectContent>
                  {statusOptions.map((s) => (
                    <SelectItem key={s.id} value={s.id}>
                      {s.label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>

          {/* Agent */}
          <div className="space-y-2">
            <Label htmlFor="agent">Agent assigné</Label>
            <Select
              value={formData.agent}
              onValueChange={(value) =>
                setFormData({ ...formData, agent: value })
              }
            >
              <SelectTrigger>
                <SelectValue placeholder="Sélectionner un agent" />
              </SelectTrigger>
              <SelectContent>
                {agents.map((a) => (
                  <SelectItem key={a.id} value={a.id}>
                    {a.label}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          {/* Fuel and Mileage */}
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="fuel">Niveau carburant (%)</Label>
              <Input
                id="fuel"
                type="number"
                min="0"
                max="100"
                placeholder="0-100"
                value={formData.fuel}
                onChange={(e) =>
                  setFormData({ ...formData, fuel: e.target.value })
                }
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="mileage">Kilométrage (km)</Label>
              <Input
                id="mileage"
                type="number"
                min="0"
                placeholder="Ex: 12500"
                value={formData.mileage}
                onChange={(e) =>
                  setFormData({ ...formData, mileage: e.target.value })
                }
              />
            </div>
          </div>

          {/* Location */}
          <div className="space-y-2">
            <Label htmlFor="location">Emplacement actuel</Label>
            <Input
              id="location"
              placeholder="Ex: Garage central, Tokoin..."
              value={formData.location}
              onChange={(e) =>
                setFormData({ ...formData, location: e.target.value })
              }
            />
          </div>

          {/* Maintenance dates */}
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label>Dernière maintenance</Label>
              <Popover>
                <PopoverTrigger asChild>
                  <Button
                    variant="outline"
                    className={cn(
                      "w-full justify-start text-left font-normal",
                      !lastMaintenance && "text-muted-foreground"
                    )}
                  >
                    <CalendarIcon className="mr-2 h-4 w-4" />
                    {lastMaintenance ? (
                      format(lastMaintenance, "dd/MM/yyyy", { locale: fr })
                    ) : (
                      <span>Sélectionner</span>
                    )}
                  </Button>
                </PopoverTrigger>
                <PopoverContent className="w-auto p-0" align="start">
                  <Calendar
                    mode="single"
                    selected={lastMaintenance}
                    onSelect={setLastMaintenance}
                    initialFocus
                    className={cn("p-3 pointer-events-auto")}
                  />
                </PopoverContent>
              </Popover>
            </div>
            <div className="space-y-2">
              <Label>Prochaine maintenance</Label>
              <Popover>
                <PopoverTrigger asChild>
                  <Button
                    variant="outline"
                    className={cn(
                      "w-full justify-start text-left font-normal",
                      !nextMaintenance && "text-muted-foreground"
                    )}
                  >
                    <CalendarIcon className="mr-2 h-4 w-4" />
                    {nextMaintenance ? (
                      format(nextMaintenance, "dd/MM/yyyy", { locale: fr })
                    ) : (
                      <span>Sélectionner</span>
                    )}
                  </Button>
                </PopoverTrigger>
                <PopoverContent className="w-auto p-0" align="start">
                  <Calendar
                    mode="single"
                    selected={nextMaintenance}
                    onSelect={setNextMaintenance}
                    initialFocus
                    className={cn("p-3 pointer-events-auto")}
                  />
                </PopoverContent>
              </Popover>
            </div>
          </div>

          <DialogFooter>
            <Button
              type="button"
              variant="outline"
              onClick={() => onOpenChange(false)}
            >
              Annuler
            </Button>
            <Button type="submit" className="gradient-primary">
              {mode === "create" ? "Créer le tricycle" : "Enregistrer"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
};

export default TricycleFormModal;
