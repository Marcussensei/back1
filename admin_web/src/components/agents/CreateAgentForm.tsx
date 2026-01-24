import { useState, useEffect } from "react";
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

interface CreateAgentFormProps {
  onSubmit: (data: any) => void;
  isLoading?: boolean;
  initialData?: any;
  isEdit?: boolean;
}

export function CreateAgentForm({ onSubmit, isLoading, initialData, isEdit }: CreateAgentFormProps) {
  const [formData, setFormData] = useState({
    nom: initialData?.name || initialData?.nom || "",
    email: initialData?.email || "",
    password: initialData?.password || "",
    telephone: initialData?.phone || initialData?.telephone || "",
    tricycle: initialData?.tricycle || "",
    actif: initialData?.actif !== undefined ? initialData?.actif : true,
    latitude: initialData?.latitude || undefined,
    longitude: initialData?.longitude || undefined,
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
      email: formData.email,
      password: formData.password,
      telephone: formData.telephone,
      tricycle: formData.tricycle,
      actif: formData.actif,
      latitude: formData.latitude,
      longitude: formData.longitude,
    });
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div>
        <Label htmlFor="name">Nom *</Label>
        <Input
          id="name"
          placeholder="John Doe"
          value={formData.nom}
          onChange={(e) => handleChange("nom", e.target.value)}
          required
        />
      </div>

      <div>
        <Label htmlFor="email">Email *</Label>
        <Input
          id="email"
          type="email"
          placeholder="john@example.com"
          value={formData.email}
          onChange={(e) => handleChange("email", e.target.value)}
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
        <Label htmlFor="tricycle">Numéro du tricycle</Label>
        <Input
          id="tricycle"
          placeholder="TO-1234-AA"
          value={formData.tricycle}
          onChange={(e) => handleChange("tricycle", e.target.value)}
        />
      </div>

      <div>
        <Label htmlFor="actif">Statut</Label>
        <Select value={formData.actif ? "actif" : "inactif"} onValueChange={(value) => handleChange("actif", value === "actif" ? "true" : "false")}>
          <SelectTrigger>
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="actif">Actif</SelectItem>
            <SelectItem value="inactif">Inactif</SelectItem>
          </SelectContent>
        </Select>
      </div>

      <Button type="submit" disabled={isLoading} className="w-full">
        {isLoading ? (isEdit ? "Modification..." : "Création...") : (isEdit ? "Modifier l'agent" : "Créer l'agent")}
      </Button>
    </form>
  );
}
