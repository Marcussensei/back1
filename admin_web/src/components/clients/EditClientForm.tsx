import { useState, useEffect } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";

interface EditClientFormProps {
  client: any;
  onSubmit: (data: any) => void;
  isLoading?: boolean;
}

export function EditClientForm({ client, onSubmit, isLoading }: EditClientFormProps) {
  const [formData, setFormData] = useState({
    nom: "",
    telephone: "",
    email: "",
    adresse: "",
    type_client: "particulier",
  });

  useEffect(() => {
    if (client) {
      setFormData({
        nom: client.name || client.nom || "",
        telephone: client.phone || client.telephone || "",
        email: client.email || "",
        adresse: client.address || client.adresse || "",
        type_client: client.type_client || "particulier",
      });
    }
  }, [client]);

  const handleChange = (field: string, value: string) => {
    setFormData((prev) => ({
      ...prev,
      [field]: value,
    }));
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSubmit({
      nom: formData.nom,
      telephone: formData.telephone,
      email: formData.email,
      adresse: formData.adresse,
      type_client: formData.type_client,
    });
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div>
        <Label htmlFor="name">Nom *</Label>
        <Input
          id="name"
          placeholder="Jean Dupont"
          value={formData.nom}
          onChange={(e) => handleChange("nom", e.target.value)}
          required
        />
      </div>

      <div>
        <Label htmlFor="phone">Téléphone *</Label>
        <Input
          id="phone"
          placeholder="+221 77 123 45 67"
          value={formData.telephone}
          onChange={(e) => handleChange("telephone", e.target.value)}
          required
        />
      </div>

      <div>
        <Label htmlFor="email">Email</Label>
        <Input
          id="email"
          type="email"
          placeholder="jean@example.com"
          value={formData.email}
          onChange={(e) => handleChange("email", e.target.value)}
        />
      </div>

      <div>
        <Label htmlFor="address">Adresse</Label>
        <Input
          id="address"
          placeholder="123 Rue de la Paix, Dakar"
          value={formData.adresse}
          onChange={(e) => handleChange("adresse", e.target.value)}
        />
      </div>

      <div>
        <Label htmlFor="type">Type de client</Label>
        <Select value={formData.type_client} onValueChange={(value) => handleChange("type_client", value)}>
          <SelectTrigger>
            <SelectValue placeholder="Sélectionner le type" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="particulier">Particulier</SelectItem>
            <SelectItem value="entreprise">Entreprise</SelectItem>
          </SelectContent>
        </Select>
      </div>

      <Button type="submit" disabled={isLoading} className="w-full">
        {isLoading ? "Mise à jour..." : "Mettre à jour le client"}
      </Button>
    </form>
  );
}
