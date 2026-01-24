import { useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { DashboardLayout } from "@/components/layout/DashboardLayout";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import { EditProductForm } from "@/components/products/EditProductForm";
import { useToast } from "@/hooks/use-toast";
import {
  useProduct,
  useUpdateProduct,
  useDeleteProduct,
  useUpdateStock,
} from "@/hooks/useApi";
import { ArrowLeft, Trash2, Package, Loader2, Edit } from "lucide-react";

const ProductDetail = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { toast } = useToast();
  const [isStockDialogOpen, setIsStockDialogOpen] = useState(false);
  const [isEditMode, setIsEditMode] = useState(false);
  const [stockQuantity, setStockQuantity] = useState<string>("");
  const [editData, setEditData] = useState<any>(null);

  const productId = id ? parseInt(id) : 0;
  const { data: product, isLoading, isError, error } = useProduct(productId);
  const updateProductMutation = useUpdateProduct(productId);
  const updateStockMutation = useUpdateStock(productId);
  const deleteProductMutation = useDeleteProduct(productId);

  const handleUpdateProduct = async (data: any) => {
    try {
      await updateProductMutation.mutateAsync(data);
      toast({
        title: "Succès",
        description: "Produit mis à jour",
      });
      setIsEditMode(false);
    } catch (error) {
      toast({
        title: "Erreur",
        description: "Impossible de mettre à jour le produit",
        variant: "destructive",
      });
    }
  };

  const handleUpdateStock = async () => {
    if (!stockQuantity) return;
    try {
      await updateStockMutation.mutateAsync({
        quantite_disponible: parseInt(stockQuantity),
      });
      toast({
        title: "Succès",
        description: "Stock mis à jour",
      });
      setIsStockDialogOpen(false);
      setStockQuantity("");
    } catch (error) {
      toast({
        title: "Erreur",
        description: "Impossible de mettre à jour le stock",
        variant: "destructive",
      });
    }
  };

  const handleDelete = async () => {
    if (confirm("Êtes-vous sûr de vouloir supprimer ce produit ?")) {
      try {
        await deleteProductMutation.mutateAsync();
        toast({
          title: "Succès",
          description: "Produit supprimé",
        });
        navigate("/products");
      } catch (error) {
        toast({
          title: "Erreur",
          description: "Impossible de supprimer le produit",
          variant: "destructive",
        });
      }
    }
  };

  if (isLoading) {
    return (
      <DashboardLayout title="Détails du produit">
        <div className="flex justify-center items-center py-12">
          <Loader2 className="w-8 h-8 animate-spin text-primary" />
        </div>
      </DashboardLayout>
    );
  }

  if (isError) {
    return (
      <DashboardLayout title="Détails du produit">
        <div className="bg-red-50 rounded-lg border border-red-200 p-6">
          <p className="text-red-800 font-semibold mb-2">Erreur de chargement</p>
          <p className="text-red-600 mb-4">{error?.message || "Impossible de récupérer le produit"}</p>
          <Button onClick={() => navigate("/products")} variant="outline">
            Retour aux produits
          </Button>
        </div>
      </DashboardLayout>
    );
  }

  if (!product) {
    return (
      <DashboardLayout title="Détails du produit">
        <div className="text-center py-12">
          <p className="text-gray-500 mb-4">Produit non trouvé</p>
          <Button onClick={() => navigate("/products")} variant="outline">
            Retour aux produits
          </Button>
        </div>
      </DashboardLayout>
    );
  }

  return (
    <DashboardLayout title={`Produit: ${product.nom}`}>
      {/* Header */}
      <div className="flex justify-between items-start mb-6">
        <div className="flex items-center gap-4">
          <Button
            variant="ghost"
            size="sm"
            onClick={() => navigate("/products")}
            className="text-gray-600"
          >
            <ArrowLeft className="w-4 h-4 mr-2" />
            Retour
          </Button>
          <div>
            <h2 className="text-2xl font-bold">{product.nom}</h2>
            <p className="text-gray-600">Code: {product.code || "-"}</p>
          </div>
        </div>
        <div className="flex gap-2">
          {!isEditMode && (
            <Button 
              variant="outline"
              onClick={() => setIsEditMode(true)}
            >
              <Edit className="w-4 h-4 mr-2" />
              Modifier
            </Button>
          )}
          
          <Dialog open={isStockDialogOpen} onOpenChange={setIsStockDialogOpen}>
            <DialogTrigger asChild>
              <Button variant="outline">
                <Package className="w-4 h-4 mr-2" />
                Gérer stock
              </Button>
            </DialogTrigger>
            <DialogContent>
              <DialogHeader>
                <DialogTitle>Gérer le stock</DialogTitle>
                <DialogDescription>
                  Mettez à jour la quantité disponible
                </DialogDescription>
              </DialogHeader>
              <div className="space-y-4">
                <div>
                  <Label htmlFor="stock">Stock disponible</Label>
                  <Input
                    id="stock"
                    type="number"
                    value={stockQuantity}
                    onChange={(e) => setStockQuantity(e.target.value)}
                    placeholder={product.quantite_disponible?.toString()}
                  />
                </div>
                <div className="flex gap-2 justify-end">
                  <Button variant="outline" onClick={() => setIsStockDialogOpen(false)}>
                    Annuler
                  </Button>
                  <Button onClick={handleUpdateStock} disabled={updateStockMutation.isPending}>
                    {updateStockMutation.isPending && <Loader2 className="w-4 h-4 mr-2 animate-spin" />}
                    Confirmer
                  </Button>
                </div>
              </div>
            </DialogContent>
          </Dialog>

          <Button
            variant="destructive"
            onClick={handleDelete}
            disabled={deleteProductMutation.isPending}
          >
            {deleteProductMutation.isPending && <Loader2 className="w-4 h-4 mr-2 animate-spin" />}
            <Trash2 className="w-4 h-4 mr-2" />
            Supprimer
          </Button>
        </div>
      </div>

      {/* Main Content */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left Column - Product Info */}
        <div className="lg:col-span-2 space-y-6">
          {/* General Info */}
          <div className="bg-white rounded-lg border border-gray-200 p-6">
            <div className="flex justify-between items-center mb-4">
              <h3 className="font-semibold">Informations générales</h3>
              {isEditMode && (
                <Button 
                  variant="ghost" 
                  size="sm"
                  onClick={() => setIsEditMode(false)}
                >
                  ✕
                </Button>
              )}
            </div>
            
            {isEditMode ? (
              <EditProductForm
                product={product}
                onSubmit={handleUpdateProduct}
                isLoading={updateProductMutation.isPending}
                onCancel={() => setIsEditMode(false)}
              />
            ) : (
              <div className="space-y-4">
                <div>
                  <Label>Nom du produit</Label>
                  <p className="text-lg font-medium">{product.nom}</p>
                </div>
                {product.description && (
                  <div>
                    <Label>Description</Label>
                    <p className="text-gray-700">{product.description}</p>
                  </div>
                )}
                <div>
                  <Label>Unité</Label>
                  <p className="text-gray-700">{product.unite || "N/A"}</p>
                </div>
                {product.quantite_par_unite && (
                  <div>
                    <Label>Quantité par unité</Label>
                    <p className="text-gray-700">{product.quantite_par_unite}</p>
                  </div>
                )}
              </div>
            )}
          </div>
        </div>

        {/* Right Column - Summary */}
        <div className="space-y-6">
          {/* Pricing */}
          <div className="bg-white rounded-lg border border-gray-200 p-6">
            <h3 className="font-semibold mb-4">Tarification</h3>
            <div className="space-y-3">
              <div>
                <Label>Prix unitaire</Label>
                <p className="text-2xl font-bold">
                  {(product.prix_unitaire || 0).toLocaleString("fr-FR", {
                    style: "currency",
                    currency: "XOF",
                  })}
                </p>
              </div>
            </div>
          </div>

          {/* Stock */}
          <div className="bg-white rounded-lg border border-gray-200 p-6">
            <h3 className="font-semibold mb-4">Stock</h3>
            <div className="space-y-3">
              <div>
                <Label>Quantité disponible</Label>
                <p className="text-2xl font-bold">
                  {product.quantite_disponible || 0}
                  <span className="text-sm text-gray-600 ml-2">
                    {product.unite || "pcs"}
                  </span>
                </p>
              </div>
              <div>
                <span className={`inline-block px-3 py-1 rounded-full text-sm font-medium ${
                  product.quantite_disponible === 0
                    ? "bg-red-100 text-red-800"
                    : product.quantite_disponible <= (product.seuil_alerte || 10)
                    ? "bg-orange-100 text-orange-800"
                    : "bg-green-100 text-green-800"
                }`}>
                  {product.quantite_disponible === 0
                    ? "Rupture"
                    : product.quantite_disponible <= (product.seuil_alerte || 10)
                    ? "Faible stock"
                    : "En stock"}
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </DashboardLayout>
  );
};

export default ProductDetail;
