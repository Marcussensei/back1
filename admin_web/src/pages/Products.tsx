import { useState } from "react";
import { DashboardLayout } from "@/components/layout/DashboardLayout";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { CreateProductForm } from "@/components/products/CreateProductForm";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import { useToast } from "@/hooks/use-toast";
import { useNavigate } from "react-router-dom";
import {
  Search,
  Plus,
  MoreVertical,
  Edit,
  Trash2,
  Package,
  RefreshCw,
  TrendingUp,
  AlertCircle,
} from "lucide-react";
import { useProducts, useCreateProduct, useDeleteProduct } from "@/hooks/useApi";

const Products = () => {
  const [searchTerm, setSearchTerm] = useState("");
  const [isCreateOpen, setIsCreateOpen] = useState(false);
  const { toast } = useToast();
  const navigate = useNavigate();

  const { data: productsData, isLoading, isError, error, refetch } = useProducts();
  const createProductMutation = useCreateProduct();

  // Use data from API
  const products = Array.isArray(productsData) 
    ? productsData 
    : productsData?.data || [];

  console.log('[PRODUCTS] productsData:', productsData);
  console.log('[PRODUCTS] products array:', products);
  console.log('[PRODUCTS] products length:', products.length);

  const filteredProducts = products.filter((product: any) =>
    product.nom?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    product.code?.includes(searchTerm)
  );

  const handleCreateProduct = async (data: any) => {
    try {
      await createProductMutation.mutateAsync(data);
      toast({
        title: "Succès",
        description: "Produit créé avec succès",
      });
      setIsCreateOpen(false);
      refetch();
    } catch (error) {
      toast({
        title: "Erreur",
        description: "Impossible de créer le produit",
        variant: "destructive",
      });
    }
  };

  const handleDeleteProduct = async (id: number) => {
    if (confirm("Êtes-vous sûr de vouloir supprimer ce produit ?")) {
      try {
        const deleteProductMutation = useDeleteProduct(id);
        await deleteProductMutation.mutateAsync();
        toast({
          title: "Succès",
          description: "Produit supprimé",
        });
        refetch();
      } catch (error) {
        toast({
          title: "Erreur",
          description: "Impossible de supprimer le produit",
          variant: "destructive",
        });
      }
    }
  };

  return (
    <DashboardLayout
      title="Produits"
      subtitle="Gérez votre catalogue de produits"
    >
      {/* Header avec actions */}
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 mb-6">
        <div className="flex-1 w-full">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
            <Input
              placeholder="Rechercher par nom ou code..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="pl-10"
            />
          </div>
        </div>

        <div className="flex gap-2">
          <Button
            variant="outline"
            size="icon"
            onClick={() => refetch()}
            disabled={isLoading}
          >
            <RefreshCw className={`w-4 h-4 ${isLoading ? "animate-spin" : ""}`} />
          </Button>

          <Dialog open={isCreateOpen} onOpenChange={setIsCreateOpen}>
            <DialogTrigger asChild>
              <Button className="w-full md:w-auto">
                <Plus className="w-4 h-4 mr-2" />
                Nouveau produit
              </Button>
            </DialogTrigger>
            <DialogContent className="max-w-md">
              <DialogHeader>
                <DialogTitle>Ajouter un nouveau produit</DialogTitle>
                <DialogDescription>
                  Enregistrez un nouveau produit dans votre catalogue avec son stock initial
                </DialogDescription>
              </DialogHeader>
              <CreateProductForm
                onSubmit={handleCreateProduct}
                isLoading={createProductMutation.isPending}
              />
            </DialogContent>
          </Dialog>
        </div>
      </div>

      {/* Stats en haut */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
        <div className="bg-gradient-to-br from-blue-50 to-blue-100 p-4 rounded-lg border border-blue-200">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-blue-600">Total produits</p>
              <p className="text-2xl font-bold text-blue-900">{products.length}</p>
            </div>
            <Package className="w-8 h-8 text-blue-200" />
          </div>
        </div>

        <div className="bg-gradient-to-br from-green-50 to-green-100 p-4 rounded-lg border border-green-200">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-green-600">En stock</p>
              <p className="text-2xl font-bold text-green-900">
                {products.filter((p: any) => (p.stock_disponible || 0) > 0).length}
              </p>
            </div>
            <TrendingUp className="w-8 h-8 text-green-200" />
          </div>
        </div>

        <div className="bg-gradient-to-br from-orange-50 to-orange-100 p-4 rounded-lg border border-orange-200">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-orange-600">Faible stock</p>
              <p className="text-2xl font-bold text-orange-900">
                {products.filter((p: any) => (p.stock_disponible || 0) > 0 && (p.stock_disponible || 0) <= (p.seuil_alerte || 10)).length}
              </p>
            </div>
            <AlertCircle className="w-8 h-8 text-orange-200" />
          </div>
        </div>

        <div className="bg-gradient-to-br from-red-50 to-red-100 p-4 rounded-lg border border-red-200">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-red-600">Rupture stock</p>
              <p className="text-2xl font-bold text-red-900">
                {products.filter((p: any) => (p.stock_disponible || 0) === 0).length}
              </p>
            </div>
            <AlertCircle className="w-8 h-8 text-red-200" />
          </div>
        </div>
      </div>

      {/* Table des produits */}
      <div className="bg-white rounded-lg border border-gray-200 overflow-hidden">
        <Table>
          <TableHeader>
            <TableRow className="bg-gray-50 border-b">
              <TableHead className="font-semibold">Produit</TableHead>
              <TableHead className="font-semibold">Description</TableHead>
              <TableHead className="font-semibold text-right">Prix unitaire</TableHead>
              <TableHead className="font-semibold text-center">Unité</TableHead>
              <TableHead className="font-semibold text-center">Stock</TableHead>
              <TableHead className="font-semibold text-center">Seuil alerte</TableHead>
              <TableHead className="font-semibold text-center">Statut</TableHead>
              <TableHead className="text-right font-semibold">Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {isLoading ? (
              <TableRow>
                <TableCell colSpan={7} className="text-center py-8 text-gray-500">
                  Chargement...
                </TableCell>
              </TableRow>
            ) : isError ? (
              <TableRow>
                <TableCell colSpan={7} className="text-center py-8">
                  <div className="bg-red-50 rounded-lg border border-red-200 p-6 inline-block">
                    <p className="text-red-800 font-semibold mb-2">Erreur de chargement</p>
                    <p className="text-red-600 text-sm mb-4">{error?.message || "Impossible de récupérer les produits"}</p>
                    <Button onClick={() => refetch()} variant="outline" size="sm">
                      Réessayer
                    </Button>
                  </div>
                </TableCell>
              </TableRow>
            ) : filteredProducts.length === 0 ? (
              <TableRow>
                <TableCell colSpan={8} className="text-center py-8 text-gray-500">
                  Aucun produit trouvé
                </TableCell>
              </TableRow>
            ) : (
              filteredProducts.map((product: any) => (
                <TableRow key={product.id} className="border-b hover:bg-gray-50">
                  <TableCell className="font-medium">{product.nom}</TableCell>
                  <TableCell className="text-sm text-gray-600">
                    {product.description || "-"}
                  </TableCell>
                  <TableCell className="text-right font-semibold">
                    {product.prix_unitaire?.toLocaleString("fr-FR", {
                      style: "currency",
                      currency: "XOF",
                    }) || "-"}
                  </TableCell>
                  <TableCell className="text-center text-sm">
                    {product.unite || "pcs"}
                  </TableCell>
                  <TableCell className="text-center">
                    <span className="font-semibold">{product.quantite_disponible || product.stock_disponible || 0}</span>
                  </TableCell>
                  <TableCell className="text-center text-sm">
                    {product.seuil_alerte || "-"}
                  </TableCell>
                  <TableCell className="text-center">
                    {(product.quantite_disponible || product.stock_disponible || 0) === 0 ? (
                      <Badge className="bg-red-100 text-red-800 border-red-200">
                        Rupture
                      </Badge>
                    ) : (product.quantite_disponible || product.stock_disponible || 0) <= (product.seuil_alerte || 10) ? (
                      <Badge className="bg-orange-100 text-orange-800 border-orange-200">
                        Faible
                      </Badge>
                    ) : (
                      <Badge className="bg-green-100 text-green-800 border-green-200">
                        En stock
                      </Badge>
                    )}
                  </TableCell>
                  <TableCell className="text-right">
                    <DropdownMenu>
                      <DropdownMenuTrigger asChild>
                        <Button variant="ghost" size="sm">
                          <MoreVertical className="w-4 h-4" />
                        </Button>
                      </DropdownMenuTrigger>
                      <DropdownMenuContent align="end">
                        <DropdownMenuItem
                          onClick={() => navigate(`/products/${product.id}`)}
                        >
                          <Edit className="w-4 h-4 mr-2" />
                          Modifier
                        </DropdownMenuItem>
                        <DropdownMenuItem
                          onClick={() => navigate(`/products/${product.id}`)}
                        >
                          <Package className="w-4 h-4 mr-2" />
                          Gérer stock
                        </DropdownMenuItem>
                        {/* <DropdownMenuItem
                          className="text-red-600"
                          onClick={() => handleDeleteProduct(product.id)}
                        >
                          <Trash2 className="w-4 h-4 mr-2" />
                          Supprimer
                        </DropdownMenuItem> */}
                      </DropdownMenuContent>
                    </DropdownMenu>
                  </TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </div>

      {/* Summary Stats */}
      <div className="mt-6 grid grid-cols-1 md:grid-cols-2 gap-4">
        <div className="bg-white rounded-lg border border-gray-200 p-4">
          <h3 className="font-semibold text-gray-900 mb-4">Distribution par stock</h3>
          <div className="space-y-3">
            <div className="flex justify-between items-center">
              <span className="text-sm text-gray-600">En stock</span>
              <div className="flex items-center gap-2">
                <div className="w-32 h-2 bg-gray-200 rounded-full overflow-hidden">
                  <div
                    className="h-full bg-green-500"
                    style={{
                      width: `${
                        products.length > 0
                          ? (products.filter((p: any) => p.stock_disponible > 10).length /
                              products.length) *
                            100
                          : 0
                      }%`,
                    }}
                  />
                </div>
                <span className="text-xs font-semibold text-gray-700 w-12 text-right">
                  {products.filter((p: any) => p.stock_disponible > 10).length}
                </span>
              </div>
            </div>

            <div className="flex justify-between items-center">
              <span className="text-sm text-gray-600">Faible stock</span>
              <div className="flex items-center gap-2">
                <div className="w-32 h-2 bg-gray-200 rounded-full overflow-hidden">
                  <div
                    className="h-full bg-orange-500"
                    style={{
                      width: `${
                        products.length > 0
                          ? (products.filter(
                              (p: any) => p.stock_disponible > 0 && p.stock_disponible <= 10
                            ).length /
                              products.length) *
                            100
                          : 0
                      }%`,
                    }}
                  />
                </div>
                <span className="text-xs font-semibold text-gray-700 w-12 text-right">
                  {
                    products.filter((p: any) => p.stock_disponible > 0 && p.stock_disponible <= 10)
                      .length
                  }
                </span>
              </div>
            </div>

            <div className="flex justify-between items-center">
              <span className="text-sm text-gray-600">Rupture stock</span>
              <div className="flex items-center gap-2">
                <div className="w-32 h-2 bg-gray-200 rounded-full overflow-hidden">
                  <div
                    className="h-full bg-red-500"
                    style={{
                      width: `${
                        products.length > 0
                          ? (products.filter((p: any) => p.stock_disponible === 0).length /
                              products.length) *
                            100
                          : 0
                      }%`,
                    }}
                  />
                </div>
                <span className="text-xs font-semibold text-gray-700 w-12 text-right">
                  {products.filter((p: any) => p.stock_disponible === 0).length}
                </span>
              </div>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg border border-gray-200 p-4">
          <h3 className="font-semibold text-gray-900 mb-4">Dernier produit ajouté</h3>
          {products.length > 0 && (
            <div className="space-y-2">
              <p className="font-medium">{products[products.length - 1]?.nom}</p>
              <p className="text-sm text-gray-600">{products[products.length - 1]?.description}</p>
              <p className="text-sm font-semibold text-primary">
                {products[products.length - 1]?.prix_unitaire?.toLocaleString("fr-FR", {
                  style: "currency",
                  currency: "XOF",
                })}
              </p>
            </div>
          )}
        </div>
      </div>
    </DashboardLayout>
  );
};

export default Products;
