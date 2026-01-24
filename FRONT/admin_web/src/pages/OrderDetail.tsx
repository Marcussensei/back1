import { useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { DashboardLayout } from "@/components/layout/DashboardLayout";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import { useToast } from "@/hooks/use-toast";
import {
  useCommand,
  useUpdateCommandStatus,
  useDeleteCommand,
} from "@/hooks/useApi";
import { ArrowLeft, Trash2, Edit, Loader2 } from "lucide-react";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";

const OrderDetail = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { toast } = useToast();
  const [isStatusDialogOpen, setIsStatusDialogOpen] = useState(false);
  const [selectedStatus, setSelectedStatus] = useState<string>("");

  const orderId = id ? parseInt(id) : 0;
  const { data: order, isLoading, isError, error } = useCommand(orderId);
  const updateStatusMutation = useUpdateCommandStatus(orderId);
  const deleteOrderMutation = useDeleteCommand(orderId);

  const statusConfig = {
    en_attente: { label: "En attente", color: "bg-yellow-100 text-yellow-800" },
    confirmee: { label: "Confirmée", color: "bg-blue-100 text-blue-800" },
    en_cours: { label: "En cours", color: "bg-purple-100 text-purple-800" },
    livree: { label: "Livrée", color: "bg-green-100 text-green-800" },
    annulee: { label: "Annulée", color: "bg-red-100 text-red-800" },
  };

  const handleStatusUpdate = async () => {
    if (!selectedStatus) return;
    try {
      await updateStatusMutation.mutateAsync(selectedStatus);
      toast({
        title: "Succès",
        description: `Statut changé à ${selectedStatus}`,
      });
      setIsStatusDialogOpen(false);
    } catch (error) {
      toast({
        title: "Erreur",
        description: "Impossible de modifier le statut",
        variant: "destructive",
      });
    }
  };

  const handleDelete = async () => {
    if (confirm("Êtes-vous sûr de vouloir supprimer cette commande ?")) {
      try {
        await deleteOrderMutation.mutateAsync();
        toast({
          title: "Succès",
          description: "Commande supprimée",
        });
        navigate("/orders");
      } catch (error) {
        toast({
          title: "Erreur",
          description: "Impossible de supprimer la commande",
          variant: "destructive",
        });
      }
    }
  };

  if (isLoading) {
    return (
      <DashboardLayout title="Détails de la commande">
        <div className="flex justify-center items-center py-12">
          <Loader2 className="w-8 h-8 animate-spin text-primary" />
        </div>
      </DashboardLayout>
    );
  }

  if (isError) {
    return (
      <DashboardLayout title="Détails de la commande">
        <div className="bg-red-50 rounded-lg border border-red-200 p-6">
          <p className="text-red-800 font-semibold mb-2">Erreur de chargement</p>
          <p className="text-red-600 mb-4">{error?.message || "Impossible de récupérer la commande"}</p>
          <Button onClick={() => navigate("/orders")} variant="outline">
            Retour aux commandes
          </Button>
        </div>
      </DashboardLayout>
    );
  }

  if (!order) {
    return (
      <DashboardLayout title="Détails de la commande">
        <div className="text-center py-12">
          <p className="text-gray-500 mb-4">Commande non trouvée</p>
          <Button onClick={() => navigate("/orders")} variant="outline">
            Retour aux commandes
          </Button>
        </div>
      </DashboardLayout>
    );
  }

  return (
    <DashboardLayout title={`Commande #${order.id}`}>
      {/* Header */}
      <div className="flex justify-between items-start mb-6">
        <div className="flex items-center gap-4">
          <Button
            variant="ghost"
            size="sm"
            onClick={() => navigate("/orders")}
            className="text-gray-600"
          >
            <ArrowLeft className="w-4 h-4 mr-2" />
            Retour
          </Button>
          <div>
            <h2 className="text-2xl font-bold">Commande #{order.id}</h2>
            <p className="text-gray-600">
              {new Date(order.date_commande).toLocaleDateString("fr-FR")}
            </p>
          </div>
        </div>
        <div className="flex gap-2">
          <Dialog open={isStatusDialogOpen} onOpenChange={setIsStatusDialogOpen}>
            <DialogTrigger asChild>
              <Button variant="outline">
                <Edit className="w-4 h-4 mr-2" />
                Modifier le statut
              </Button>
            </DialogTrigger>
            <DialogContent>
              <DialogHeader>
                <DialogTitle>Modifier le statut</DialogTitle>
                <DialogDescription>
                  Sélectionnez le nouveau statut de la commande
                </DialogDescription>
              </DialogHeader>
              <div className="space-y-4">
                <Select value={selectedStatus} onValueChange={setSelectedStatus}>
                  <SelectTrigger>
                    <SelectValue placeholder="Sélectionnez un statut" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="en_attente">En attente</SelectItem>
                    <SelectItem value="confirmee">Confirmée</SelectItem>
                    <SelectItem value="en_cours">En cours</SelectItem>
                    <SelectItem value="livree">Livrée</SelectItem>
                    <SelectItem value="annulee">Annulée</SelectItem>
                  </SelectContent>
                </Select>
                <div className="flex gap-2 justify-end">
                  <Button variant="outline" onClick={() => setIsStatusDialogOpen(false)}>
                    Annuler
                  </Button>
                  <Button onClick={handleStatusUpdate} disabled={updateStatusMutation.isPending}>
                    {updateStatusMutation.isPending && <Loader2 className="w-4 h-4 mr-2 animate-spin" />}
                    Confirmer
                  </Button>
                </div>
              </div>
            </DialogContent>
          </Dialog>

          <Button
            variant="destructive"
            onClick={handleDelete}
            disabled={deleteOrderMutation.isPending}
          >
            {deleteOrderMutation.isPending && <Loader2 className="w-4 h-4 mr-2 animate-spin" />}
            <Trash2 className="w-4 h-4 mr-2" />
            Supprimer
          </Button>
        </div>
      </div>

      {/* Main Content */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left Column - Order Info */}
        <div className="lg:col-span-2 space-y-6">
          {/* Status */}
          <div className="bg-white rounded-lg border border-gray-200 p-6">
            <h3 className="font-semibold mb-4">Statut</h3>
            <Badge
              className={statusConfig[order.statut as keyof typeof statusConfig]?.color}
            >
              {statusConfig[order.statut as keyof typeof statusConfig]?.label || order.statut}
            </Badge>
          </div>

          {/* Client Information */}
          <div className="bg-white rounded-lg border border-gray-200 p-6">
            <h3 className="font-semibold mb-4">Informations du client</h3>
            <div className="space-y-3">
              <div>
                <p className="text-sm text-gray-600">Client</p>
                <p className="font-medium">{order.client_nom || `Client #${order.client_id}`}</p>
              </div>
              {order.client_telephone && (
                <div>
                  <p className="text-sm text-gray-600">Téléphone</p>
                  <p className="font-medium">{order.client_telephone}</p>
                </div>
              )}
              {order.adresse_livraison && (
                <div>
                  <p className="text-sm text-gray-600">Adresse de livraison</p>
                  <p className="font-medium">{order.adresse_livraison}</p>
                </div>
              )}
            </div>
          </div>

          {/* Items */}
          <div className="bg-white rounded-lg border border-gray-200 overflow-hidden">
            <div className="p-6 border-b">
              <h3 className="font-semibold">Articles</h3>
            </div>
            <table className="w-full">
              <thead className="bg-gray-50 border-b">
                <tr>
                  <th className="px-6 py-3 text-left text-sm font-medium">Produit</th>
                  <th className="px-6 py-3 text-left text-sm font-medium">Quantité</th>
                  <th className="px-6 py-3 text-left text-sm font-medium">Prix unitaire</th>
                  <th className="px-6 py-3 text-right text-sm font-medium">Total</th>
                </tr>
              </thead>
              <tbody>
                {order.items && order.items.length > 0 ? (
                  order.items.map((item: any) => (
                    <tr key={item.id} className="border-b hover:bg-gray-50">
                      <td className="px-6 py-3">
                        <div>
                          <p className="font-medium">{item.produit_nom}</p>
                          <p className="text-sm text-gray-600">{item.description}</p>
                        </div>
                      </td>
                      <td className="px-6 py-3">{item.quantite} {item.unite}</td>
                      <td className="px-6 py-3">
                        {(item.prix_unitaire || 0).toLocaleString("fr-FR", {
                          style: "currency",
                          currency: "XOF",
                        })}
                      </td>
                      <td className="px-6 py-3 text-right font-medium">
                        {(item.montant_ligne || 0).toLocaleString("fr-FR", {
                          style: "currency",
                          currency: "XOF",
                        })}
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan={4} className="px-6 py-8 text-center text-gray-500">
                      Aucun article
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>

        {/* Right Column - Summary */}
        <div className="space-y-6">
          {/* Dates */}
          <div className="bg-white rounded-lg border border-gray-200 p-6">
            <h3 className="font-semibold mb-4">Dates</h3>
            <div className="space-y-3">
              <div>
                <p className="text-sm text-gray-600">Date de commande</p>
                <p className="font-medium">
                  {new Date(order.date_commande).toLocaleDateString("fr-FR")}
                </p>
              </div>
              {order.date_livraison_prevue && (
                <div>
                  <p className="text-sm text-gray-600">Livraison prévue</p>
                  <p className="font-medium">
                    {new Date(order.date_livraison_prevue).toLocaleDateString("fr-FR")}
                  </p>
                </div>
              )}
              {order.date_livraison_effective && (
                <div>
                  <p className="text-sm text-gray-600">Livrée le</p>
                  <p className="font-medium">
                    {new Date(order.date_livraison_effective).toLocaleDateString("fr-FR")}
                  </p>
                </div>
              )}
            </div>
          </div>

          {/* Summary */}
          <div className="bg-white rounded-lg border border-gray-200 p-6">
            <h3 className="font-semibold mb-4">Résumé</h3>
            <div className="space-y-3 border-t pt-4">
              <div className="flex justify-between">
                <span className="text-gray-600">Montant total</span>
                <span className="font-semibold text-lg">
                  {(order.montant_total || 0).toLocaleString("fr-FR", {
                    style: "currency",
                    currency: "XOF",
                  })}
                </span>
              </div>
            </div>
          </div>

          {/* Agent */}
          {order.agent_nom && (
            <div className="bg-white rounded-lg border border-gray-200 p-6">
              <h3 className="font-semibold mb-4">Livreur assigné</h3>
              <div className="space-y-3">
                <div>
                  <p className="text-sm text-gray-600">Nom</p>
                  <p className="font-medium">{order.agent_nom}</p>
                </div>
                {order.agent_telephone && (
                  <div>
                    <p className="text-sm text-gray-600">Téléphone</p>
                    <p className="font-medium">{order.agent_telephone}</p>
                  </div>
                )}
              </div>
            </div>
          )}

          {/* Notes */}
          {order.notes && (
            <div className="bg-white rounded-lg border border-gray-200 p-6">
              <h3 className="font-semibold mb-4">Notes</h3>
              <p className="text-gray-700">{order.notes}</p>
            </div>
          )}
        </div>
      </div>
    </DashboardLayout>
  );
};

export default OrderDetail;
