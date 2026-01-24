import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Form,
  FormControl,
  FormDescription,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form";
import { useForm } from "react-hook-form";

interface CreateProductFormProps {
  onSubmit: (data: any) => Promise<void>;
  isLoading?: boolean;
}

export const CreateProductForm = ({ onSubmit, isLoading }: CreateProductFormProps) => {
  const form = useForm({
    defaultValues: {
      nom: "",
      description: "",
      prix_unitaire: 0,
      unite: "bouteille",
      quantite_par_unite: 1,
      stock_disponible: 0,
      seuil_alerte: 10,
    },
  });

  return (
    <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
      {/* Nom du produit */}
      <div className="space-y-2">
        <Label htmlFor="nom">Nom du produit *</Label>
        <Input
          id="nom"
          placeholder="Ex: Eau 50CL"
          {...form.register("nom", { required: "Le nom est obligatoire" })}
        />
        {form.formState.errors.nom && (
          <p className="text-sm text-red-500">{form.formState.errors.nom.message}</p>
        )}
      </div>

      {/* Description */}
      <div className="space-y-2">
        <Label htmlFor="description">Description</Label>
        <Input
          id="description"
          placeholder="Ex: Bouteille d'eau 50 centilitres"
          {...form.register("description")}
        />
      </div>

      {/* Prix unitaire */}
      <div className="space-y-2">
        <Label htmlFor="prix_unitaire">Prix unitaire (FCFA) *</Label>
        <Input
          id="prix_unitaire"
          type="number"
          placeholder="300"
          {...form.register("prix_unitaire", {
            required: "Le prix est obligatoire",
            min: { value: 0, message: "Le prix doit être positif" },
          })}
        />
        {form.formState.errors.prix_unitaire && (
          <p className="text-sm text-red-500">{form.formState.errors.prix_unitaire.message}</p>
        )}
      </div>

      {/* Unité */}
      <div className="space-y-2">
        <Label htmlFor="unite">Unité</Label>
        <Input
          id="unite"
          placeholder="bouteille"
          {...form.register("unite")}
        />
      </div>

      {/* Quantité par unité */}
      <div className="space-y-2">
        <Label htmlFor="quantite_par_unite">Quantité par unité</Label>
        <Input
          id="quantite_par_unite"
          type="number"
          placeholder="1"
          {...form.register("quantite_par_unite", {
            min: { value: 1, message: "La quantité doit être au moins 1" },
          })}
        />
      </div>

      {/* Stock disponible */}
      <div className="space-y-2">
        <Label htmlFor="stock_disponible">Stock disponible (unités)</Label>
        <Input
          id="stock_disponible"
          type="number"
          placeholder="20"
          {...form.register("stock_disponible", {
            min: { value: 0, message: "Le stock ne peut pas être négatif" },
          })}
        />
      </div>

      {/* Seuil d'alerte */}
      <div className="space-y-2">
        <Label htmlFor="seuil_alerte">Seuil d'alerte stock</Label>
        <Input
          id="seuil_alerte"
          type="number"
          placeholder="10"
          {...form.register("seuil_alerte", {
            min: { value: 0, message: "Le seuil ne peut pas être négatif" },
          })}
        />
        <p className="text-xs text-gray-500">
          Vous serez alerté quand le stock passe sous ce seuil
        </p>
      </div>

      {/* Submit Button */}
      <Button type="submit" className="w-full" disabled={isLoading}>
        {isLoading ? "Création..." : "Créer le produit"}
      </Button>
    </form>
  );
};
