import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

interface CreateClientFormProps {
  onSubmit: (data: any) => void;
  isLoading?: boolean;
}

export function CreateClientForm({ onSubmit, isLoading }: CreateClientFormProps) {
  const [formData, setFormData] = useState({
    nom: "",
    password: "",
    telephone: "",
    email: "",
    nom_point_vente: "",
    responsable: "",
    adresse: "",
    latitude: undefined as number | undefined,
    longitude: undefined as number | undefined,
    type_client: "particulier",
  });

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
      password: formData.password,
      telephone: formData.telephone,
      email: formData.email,
      nom_point_vente: formData.nom_point_vente,
      responsable: formData.responsable,
      adresse: formData.adresse,
      latitude: formData.latitude,
      longitude: formData.longitude,
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
        <Label htmlFor="password">Mot de passe *</Label>
        <Input
          id="password"
          type="password"
          placeholder="Mot de passe sécurisé"
          value={formData.password}
          onChange={(e) => handleChange("password", e.target.value)}
          required
        />
      </div>

      <div>
        <Label htmlFor="email">Email *</Label>
        <Input
          id="email"
          type="email"
          placeholder="jean@example.com"
          value={formData.email}
          onChange={(e) => handleChange("email", e.target.value)}
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
        <Label htmlFor="nom_point_vente">Nom du point de vente *</Label>
        <Input
          id="nom_point_vente"
          placeholder="Boutique du Coin"
          value={formData.nom_point_vente}
          onChange={(e) => handleChange("nom_point_vente", e.target.value)}
          required
        />
      </div>

      <div>
        <Label htmlFor="responsable">Responsable</Label>
        <Input
          id="responsable"
          placeholder="Responsable"
          value={formData.responsable}
          onChange={(e) => handleChange("responsable", e.target.value)}
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

      <Button type="submit" disabled={isLoading} className="w-full">
        {isLoading ? "Création..." : "Créer le client"}
      </Button>
    </form>
  );
}
