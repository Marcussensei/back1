import { useState } from "react";
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
import { Store, MapPin } from "lucide-react";

interface ClientFormModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  client?: {
    id: string;
    name: string;
    owner: string;
    phone: string;
    email: string;
    address: string;
    type: string;
    gpsLat: string;
    gpsLng: string;
  };
  mode: "create" | "edit";
}

const clientTypes = [
  { id: "retailer", label: "Détaillant" },
  { id: "wholesaler", label: "Grossiste" },
  { id: "institution", label: "Institution" },
];

const ClientFormModal = ({ open, onOpenChange, client, mode }: ClientFormModalProps) => {
  const [formData, setFormData] = useState({
    name: client?.name || "",
    owner: client?.owner || "",
    phone: client?.phone || "",
    email: client?.email || "",
    address: client?.address || "",
    type: client?.type || "",
    gpsLat: client?.gpsLat || "",
    gpsLng: client?.gpsLng || "",
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    console.log("Form submitted:", formData);
    onOpenChange(false);
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[550px]">
        <DialogHeader>
          <DialogTitle>
            {mode === "create" ? "Nouveau client" : "Modifier le client"}
          </DialogTitle>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-6">
          {/* Icon */}
          <div className="flex justify-center">
            <div className="w-20 h-20 rounded-2xl bg-primary/10 flex items-center justify-center">
              <Store className="w-10 h-10 text-primary" />
            </div>
          </div>

          {/* Business name */}
          <div className="space-y-2">
            <Label htmlFor="name">Nom de l'entreprise *</Label>
            <Input
              id="name"
              placeholder="Ex: Point de Vente Akwa"
              value={formData.name}
              onChange={(e) =>
                setFormData({ ...formData, name: e.target.value })
              }
              required
            />
          </div>

          {/* Owner and Type */}
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="owner">Propriétaire *</Label>
              <Input
                id="owner"
                placeholder="Nom du propriétaire"
                value={formData.owner}
                onChange={(e) =>
                  setFormData({ ...formData, owner: e.target.value })
                }
                required
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="type">Type de client *</Label>
              <Select
                value={formData.type}
                onValueChange={(value) =>
                  setFormData({ ...formData, type: value })
                }
              >
                <SelectTrigger>
                  <SelectValue placeholder="Sélectionner" />
                </SelectTrigger>
                <SelectContent>
                  {clientTypes.map((t) => (
                    <SelectItem key={t.id} value={t.id}>
                      {t.label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>

          {/* Contact fields */}
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="phone">Téléphone *</Label>
              <Input
                id="phone"
                placeholder="+228 90 00 00 00"
                value={formData.phone}
                onChange={(e) =>
                  setFormData({ ...formData, phone: e.target.value })
                }
                required
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="email">Email</Label>
              <Input
                id="email"
                type="email"
                placeholder="email@exemple.tg"
                value={formData.email}
                onChange={(e) =>
                  setFormData({ ...formData, email: e.target.value })
                }
              />
            </div>
          </div>

          {/* Address */}
          <div className="space-y-2">
            <Label htmlFor="address">Adresse *</Label>
            <Input
              id="address"
              placeholder="Quartier, Rue, Repères..."
              value={formData.address}
              onChange={(e) =>
                setFormData({ ...formData, address: e.target.value })
              }
              required
            />
          </div>

          {/* GPS Coordinates */}
          <div className="space-y-2">
            <Label className="flex items-center gap-2">
              <MapPin className="w-4 h-4" />
              Coordonnées GPS
            </Label>
            <div className="grid grid-cols-2 gap-4">
              <Input
                id="gpsLat"
                placeholder="Latitude (ex: 6.1319)"
                value={formData.gpsLat}
                onChange={(e) =>
                  setFormData({ ...formData, gpsLat: e.target.value })
                }
              />
              <Input
                id="gpsLng"
                placeholder="Longitude (ex: 1.2228)"
                value={formData.gpsLng}
                onChange={(e) =>
                  setFormData({ ...formData, gpsLng: e.target.value })
                }
              />
            </div>
            <p className="text-xs text-muted-foreground">
              Optionnel - Utilisé pour localiser le client sur la carte
            </p>
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
              {mode === "create" ? "Créer le client" : "Enregistrer"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
};

export default ClientFormModal;
