import { useState } from "react";
import { DashboardLayout } from "@/components/layout/DashboardLayout";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
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
  Filter,
  Plus,
  MoreVertical,
  Eye,
  Edit,
  Trash2,
  Download,
  RefreshCw,
} from "lucide-react";
import { useCommands, useCreateCommand, useDeleteCommand, useCommandsStatistics } from "@/hooks/useApi";
import { CreateOrderForm } from "@/components/orders/CreateOrderForm";

const Orders = () => {
  const [searchTerm, setSearchTerm] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");
  const [isCreateOpen, setIsCreateOpen] = useState(false);
  const { toast } = useToast();
  const navigate = useNavigate();

  const { data: ordersData, isLoading, isError, error, refetch } = useCommands({
    statut: statusFilter !== "all" ? statusFilter : undefined,
  });

  const { data: statistics } = useCommandsStatistics();

  const createOrderMutation = useCreateCommand();
  const deleteOrderMutation = useDeleteCommand(0);

  // Use data from API
  const orders = Array.isArray(ordersData)
    ? ordersData
    : ordersData?.commandes || [];

  console.log('[ORDERS] ordersData:', ordersData);
  console.log('[ORDERS] ordersData type:', typeof ordersData);
  console.log('[ORDERS] ordersData keys:', ordersData ? Object.keys(ordersData) : 'null/undefined');
  console.log('[ORDERS] orders array:', orders);
  console.log('[ORDERS] orders length:', orders.length);
  console.log('[ORDERS] isArray check:', Array.isArray(ordersData));
  console.log('[ORDERS] commandes property:', ordersData?.commandes);

  const filteredOrders = orders.filter((order: any) =>
    order.id.toString().includes(searchTerm) ||
    order.client_id?.toString().includes(searchTerm)
  );

  const statusConfig = {
    en_attente: { label: "En attente", color: "bg-yellow-100 text-yellow-800" },
    confirmee: { label: "Confirmée", color: "bg-blue-100 text-blue-800" },
    en_cours: { label: "En cours", color: "bg-purple-100 text-purple-800" },
    livree: { label: "Livrée", color: "bg-green-100 text-green-800" },
    annulee: { label: "Annulée", color: "bg-red-100 text-red-800" },
  };

  const handleCreateOrder = async (data: any) => {
    try {
      await createOrderMutation.mutateAsync(data);
      toast({
        title: "Succès",
        description: "Commande créée avec succès",
      });
      setIsCreateOpen(false);
      refetch();
    } catch (error) {
      toast({
        title: "Erreur",
        description: "Impossible de créer la commande",
        variant: "destructive",
      });
    }
  };

  const handleDeleteOrder = async (id: number) => {
    try {
      await deleteOrderMutation.mutateAsync(undefined);
      toast({
        title: "Succès",
        description: "Commande supprimée",
      });
      refetch();
    } catch (error) {
      toast({
        title: "Erreur",
        description: "Impossible de supprimer la commande",
        variant: "destructive",
      });
    }
  };

  return (
    <DashboardLayout
      title="Commandes"
      subtitle="Gérez toutes les commandes clients"
    >
      {/* Header avec actions */}
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 mb-6">
        <div className="flex-1 flex gap-2 w-full">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
            <Input
              placeholder="Rechercher par ID ou client..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="pl-10"
            />
          </div>
          <Select value={statusFilter} onValueChange={setStatusFilter}>
            <SelectTrigger className="w-[180px]">
              <SelectValue placeholder="Statut" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">Tous les statuts</SelectItem>
              <SelectItem value="en_attente">En attente</SelectItem>
              <SelectItem value="confirmee">Confirmée</SelectItem>
              <SelectItem value="en_cours">En cours</SelectItem>
              <SelectItem value="livree">Livrée</SelectItem>
              <SelectItem value="annulee">Annulée</SelectItem>
            </SelectContent>
          </Select>
          <Button
            variant="outline"
            size="icon"
            onClick={() => refetch()}
            disabled={isLoading}
          >
            <RefreshCw className="w-4 h-4" />
          </Button>
        </div>

        <Dialog open={isCreateOpen} onOpenChange={setIsCreateOpen}>
          
          <DialogContent className="max-w-md">
            <DialogHeader>
              <DialogTitle>Créer une nouvelle commande</DialogTitle>
              <DialogDescription>
                Remplissez les informations pour créer une commande
              </DialogDescription>
            </DialogHeader>
            <CreateOrderForm onSubmit={handleCreateOrder} isLoading={createOrderMutation.isPending} />
          </DialogContent>
        </Dialog>
      </div>

      {/* Table des commandes */}
      <div className="bg-white rounded-lg border border-gray-200 overflow-hidden">
        <Table>
          <TableHeader>
            <TableRow className="bg-gray-50 border-b">
              <TableHead className="font-semibold">ID Commande</TableHead>
              <TableHead className="font-semibold">Client</TableHead>
              <TableHead className="font-semibold">Date</TableHead>
              <TableHead className="font-semibold">Montant</TableHead>
              <TableHead className="font-semibold">Statut</TableHead>
              <TableHead className="text-right font-semibold">Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {isLoading ? (
              <TableRow>
                <TableCell colSpan={6} className="text-center py-8 text-gray-500">
                  Chargement...
                </TableCell>
              </TableRow>
            ) : isError ? (
              <TableRow>
                <TableCell colSpan={6} className="text-center py-8">
                  <div className="bg-red-50 rounded-lg border border-red-200 p-6 inline-block">
                    <p className="text-red-800 font-semibold mb-2">Erreur de chargement</p>
                    <p className="text-red-600 text-sm mb-4">{error?.message || "Impossible de récupérer les commandes"}</p>
                    <Button onClick={() => refetch()} variant="outline" size="sm">
                      Réessayer
                    </Button>
                  </div>
                </TableCell>
              </TableRow>
            ) : filteredOrders.length === 0 ? (
              <TableRow>
                <TableCell colSpan={6} className="text-center py-8 text-gray-500">
                  Aucune commande trouvée
                </TableCell>
              </TableRow>
            ) : (
              filteredOrders.map((order: any) => (
                <TableRow key={order.id} className="border-b hover:bg-gray-50">
                  <TableCell className="font-medium text-primary">
                    #{order.id}
                  </TableCell>
                  <TableCell>Client #{order.client_id}</TableCell>
                  <TableCell>
                    {new Date(order.date_commande).toLocaleDateString("fr-FR")}
                  </TableCell>
                  <TableCell className="font-semibold">
                    {order.montant_total?.toLocaleString("fr-FR", {
                      style: "currency",
                      currency: "XOF",
                    })}
                  </TableCell>
                  <TableCell>
                    <Badge
                      className={statusConfig[order.statut as keyof typeof statusConfig]?.color}
                    >
                      {statusConfig[order.statut as keyof typeof statusConfig]?.label || order.statut}
                    </Badge>
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
                          onClick={() => navigate(`/orders/${order.id}`)}
                        >
                          <Eye className="w-4 h-4 mr-2" />
                          Voir détails
                        </DropdownMenuItem>
                        <DropdownMenuItem>
                          <Edit className="w-4 h-4 mr-2" />
                          Modifier
                        </DropdownMenuItem>
                        <DropdownMenuItem
                          className="text-red-600"
                          onClick={() => handleDeleteOrder(order.id)}
                        >
                          <Trash2 className="w-4 h-4 mr-2" />
                          Supprimer
                        </DropdownMenuItem>
                      </DropdownMenuContent>
                    </DropdownMenu>
                  </TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </div>

      {/* Stats en bas */}
      <div className="mt-6 grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="bg-gradient-to-br from-blue-50 to-blue-100 p-4 rounded-lg border border-blue-200">
          <p className="text-sm text-blue-600">Total</p>
          <p className="text-2xl font-bold text-blue-900">{statistics?.total_commandes || 0}</p>
        </div>
        <div className="bg-gradient-to-br from-yellow-50 to-yellow-100 p-4 rounded-lg border border-yellow-200">
          <p className="text-sm text-yellow-600">En attente</p>
          <p className="text-2xl font-bold text-yellow-900">
            {statistics?.en_attente || 0}
          </p>
        </div>
        <div className="bg-gradient-to-br from-purple-50 to-purple-100 p-4 rounded-lg border border-purple-200">
          <p className="text-sm text-purple-600">En cours</p>
          <p className="text-2xl font-bold text-purple-900">
            {statistics?.en_cours || 0}
          </p>
        </div>
        <div className="bg-gradient-to-br from-green-50 to-green-100 p-4 rounded-lg border border-green-200">
          <p className="text-sm text-green-600">Livrées</p>
          <p className="text-2xl font-bold text-green-900">
            {statistics?.livrees || 0}
          </p>
        </div>
      </div>
    </DashboardLayout>
  );
};

export default Orders;
