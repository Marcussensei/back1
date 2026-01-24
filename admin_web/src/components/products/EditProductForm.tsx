import { useState, useEffect } from "react";
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

interface EditProductFormProps {
  product: any;
  onSubmit: (data: any) => Promise<void>;
  isLoading?: boolean;
  onCancel?: () => void;
}

export const EditProductForm = ({ 
  product, 
  onSubmit, 
  isLoading, 
  onCancel 
}: EditProductFormProps) => {
  const form = useForm({
    defaultValues: {
      nom: product?.nom || "",
      description: product?.description || "",
      prix_unitaire: product?.prix_unitaire || 0,
      unite: product?.unite || "bouteille",
      quantite_par_unite: product?.quantite_par_unite || 1,
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
          placeholder="Description du produit"
          {...form.register("description")}
        />
      </div>

      {/* Prix unitaire */}
      <div className="space-y-2">
        <Label htmlFor="prix_unitaire">Prix unitaire (XOF) *</Label>
        <Input
          id="prix_unitaire"
          type="number"
          step="0.01"
          placeholder="1500"
          {...form.register("prix_unitaire", { 
            required: "Le prix est obligatoire",
            valueAsNumber: true 
          })}
        />
        {form.formState.errors.prix_unitaire && (
          <p className="text-sm text-red-500">{form.formState.errors.prix_unitaire.message}</p>
        )}
      </div>

      {/* Unité */}
      <div className="space-y-2">
        <Label htmlFor="unite">Unité de vente</Label>
        <Input
          id="unite"
          placeholder="Ex: bouteille, kg, litre"
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
          {...form.register("quantite_par_unite", { valueAsNumber: true })}
        />
      </div>

      {/* Buttons */}
      <div className="flex gap-2 justify-end pt-4">
        {onCancel && (
          <Button type="button" variant="outline" onClick={onCancel}>
            Annuler
          </Button>
        )}
        <Button type="submit" disabled={isLoading}>
          {isLoading ? "Enregistrement..." : "Enregistrer"}
        </Button>
      </div>
    </form>
  );
};
