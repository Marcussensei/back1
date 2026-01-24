import { useState } from "react";
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
import { useClients } from "@/hooks/useApi";

interface CreateOrderFormProps {
  onSubmit: (data: any) => void;
  isLoading?: boolean;
}

export function CreateOrderForm({ onSubmit, isLoading }: CreateOrderFormProps) {
  const [formData, setFormData] = useState({
    client_id: "",
    montant_total: "",
    statut: "en_attente",
    description: "",
  });

  const { data: clientsData } = useClients();
  const clients = Array.isArray(clientsData) ? clientsData : clientsData?.clients || [];

  const handleChange = (field: string, value: string) => {
    setFormData((prev) => ({
      ...prev,
      [field]: value,
    }));
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSubmit({
      client_id: parseInt(formData.client_id),
      montant_total: parseFloat(formData.montant_total),
      statut: formData.statut,
      description: formData.description,
    });
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div>
        <Label htmlFor="client">Client *</Label>
        <Select value={formData.client_id} onValueChange={(value) => handleChange("client_id", value)}>
          <SelectTrigger>
            <SelectValue placeholder="Sélectionnez un client" />
          </SelectTrigger>
          <SelectContent>
            {clients.map((client: any) => (
              <SelectItem key={client.id} value={client.id.toString()}>
                {client.nom} ({client.telephone})
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      <div>
        <Label htmlFor="amount">Montant (XOF) *</Label>
        <Input
          id="amount"
          type="number"
          placeholder="0.00"
          value={formData.montant_total}
          onChange={(e) => handleChange("montant_total", e.target.value)}
          step="0.01"
          min="0"
          required
        />
      </div>

      <div>
        <Label htmlFor="status">Statut</Label>
        <Select value={formData.statut} onValueChange={(value) => handleChange("statut", value)}>
          <SelectTrigger>
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="en_attente">En attente</SelectItem>
            <SelectItem value="confirmee">Confirmée</SelectItem>
            <SelectItem value="en_cours">En cours</SelectItem>
            <SelectItem value="livree">Livrée</SelectItem>
            <SelectItem value="annulee">Annulée</SelectItem>
          </SelectContent>
        </Select>
      </div>

      <div>
        <Label htmlFor="description">Description</Label>
        <Input
          id="description"
          placeholder="Notes additionnelles..."
          value={formData.description}
          onChange={(e) => handleChange("description", e.target.value)}
        />
      </div>

      <Button type="submit" disabled={isLoading} className="w-full">
        {isLoading ? "Création..." : "Créer la commande"}
      </Button>
    </form>
  );
}
