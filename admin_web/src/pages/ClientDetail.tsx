import { useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { DashboardLayout } from "@/components/layout/DashboardLayout";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Card } from "@/components/ui/card";
import { Progress } from "@/components/ui/progress";
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
  ArrowLeft,
  Store,
  Phone,
  Mail,
  MapPin,
  Edit,
  Package,
  TrendingUp,
  Calendar,
  DollarSign,
  ShoppingCart,
  Clock,
  CheckCircle,
  XCircle,
  RefreshCw,
} from "lucide-react";
import { useClient, useUpdateClient } from "@/hooks/useApi";
import { EditClientForm } from "@/components/clients/EditClientForm";

// Mock client data
const clientsData: Record<string, any> = {
  "CL-001": {
    id: "CL-001",
    name: "Point de Vente Akwa",
    owner: "Mme. Akouavi Mensah",
    phone: "+228 90 11 22 33",
    email: "akwa.pdv@email.tg",
    address: "Lomé, Quartier Bè Kpota",
    gps: { lat: 6.1319, lng: 1.2228 },
    type: "retailer",
    status: "active",
    registeredDate: "15/01/2023",
    totalOrders: 245,
    totalAmount: 1225000,
    avgOrderValue: 5000,
    lastOrderDate: "22/12/2024",
  },
  "CL-002": {
    id: "CL-002",
    name: "Boutique Centrale",
    owner: "M. Kossi Adama",
    phone: "+228 91 22 33 44",
    email: "boutique.centrale@email.tg",
    address: "Lomé, Tokoin Habitat",
    gps: { lat: 6.1375, lng: 1.2150 },
    type: "retailer",
    status: "active",
    registeredDate: "22/03/2023",
    totalOrders: 189,
    totalAmount: 945000,
    avgOrderValue: 5000,
    lastOrderDate: "21/12/2024",
  },
  "CL-003": {
    id: "CL-003",
    name: "Kiosque du Marché",
    owner: "Mme. Afiwa Kodjo",
    phone: "+228 92 33 44 55",
    email: "kiosque.marche@email.tg",
    address: "Lomé, Grand Marché",
    gps: { lat: 6.1256, lng: 1.2300 },
    type: "wholesaler",
    status: "active",
    registeredDate: "08/06/2022",
    totalOrders: 523,
    totalAmount: 2615000,
    avgOrderValue: 5000,
    lastOrderDate: "23/12/2024",
  },
};

const typeConfig = {
  retailer: { label: "Détaillant", className: "bg-info/10 text-info border-info/20" },
  wholesaler: { label: "Grossiste", className: "bg-secondary/20 text-secondary-foreground border-secondary/30" },
  institution: { label: "Institution", className: "bg-accent/10 text-accent border-accent/20" },
};

const statusConfig = {
  active: { label: "Actif", className: "bg-success/10 text-success border-success/20" },
  inactive: { label: "Inactif", className: "bg-muted text-muted-foreground border-border" },
};

const orderHistory = [
  { id: "CMD-001", date: "23/12/2024", quantity: 50, amount: 25000, status: "delivered" },
  { id: "CMD-002", date: "20/12/2024", quantity: 30, amount: 15000, status: "delivered" },
  { id: "CMD-003", date: "18/12/2024", quantity: 45, amount: 22500, status: "delivered" },
  { id: "CMD-004", date: "15/12/2024", quantity: 60, amount: 30000, status: "cancelled" },
  { id: "CMD-005", date: "12/12/2024", quantity: 40, amount: 20000, status: "delivered" },
  { id: "CMD-006", date: "10/12/2024", quantity: 35, amount: 17500, status: "delivered" },
];

const monthlyStats = [
  { month: "Juil", orders: 18, amount: 90000 },
  { month: "Août", orders: 22, amount: 110000 },
  { month: "Sept", orders: 20, amount: 100000 },
  { month: "Oct", orders: 25, amount: 125000 },
  { month: "Nov", orders: 28, amount: 140000 },
  { month: "Déc", orders: 24, amount: 120000 },
];

const ClientDetail = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const [isEditOpen, setIsEditOpen] = useState(false);
  const { toast } = useToast();

  const { data: clientData, isLoading, isError, error, refetch } = useClient(Number(id));
  const updateClientMutation = useUpdateClient(Number(id));

  const client = clientData;

  const handleUpdateClient = async (data: any) => {
    try {
      await updateClientMutation.mutateAsync(data);
      toast({
        title: "Succès",
        description: "Client mis à jour avec succès",
      });
      setIsEditOpen(false);
      refetch();
    } catch (error) {
      toast({
        title: "Erreur",
        description: "Impossible de mettre à jour le client",
        variant: "destructive",
      });
    }
  };

  if (isLoading) {
    return (
      <DashboardLayout title="Détail client" subtitle="Chargement...">
        <div className="flex justify-center items-center h-64">
          <RefreshCw className="w-8 h-8 animate-spin" />
        </div>
      </DashboardLayout>
    );
  }

  if (isError || !client) {
    return (
      <DashboardLayout title="Détail client" subtitle="Erreur de chargement">
        <div className="text-center py-12 bg-red-50 rounded-lg border border-red-200 p-6">
          <p className="text-red-800 font-semibold mb-2">Erreur de chargement</p>
          <p className="text-red-600 text-sm mb-4">{error?.message || "Client non trouvé"}</p>
          <Button onClick={() => refetch()} variant="outline" size="sm">
            Réessayer
          </Button>
        </div>
      </DashboardLayout>
    );
  }

  return (
    <DashboardLayout
      title="Détail client"
      subtitle={`Informations complètes de ${client.name || client.nom}`}
    >
      {/* Back button */}
      <Button
        variant="ghost"
        className="mb-6 gap-2"
        onClick={() => navigate("/clients")}
      >
        <ArrowLeft className="w-4 h-4" />
        Retour aux clients
      </Button>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Client Profile Card */}
        <Card className="lg:col-span-1 p-6">
          <div className="flex flex-col items-center text-center mb-6">
            <div className="w-24 h-24 rounded-2xl bg-primary/10 flex items-center justify-center mb-4">
              <Store className="w-12 h-12 text-primary" />
            </div>
            <h2 className="text-xl font-heading font-bold">{client.name || client.nom}</h2>
            <p className="text-muted-foreground">Client #{client.id}</p>
            <div className="flex gap-2 mt-3">
              <Badge className="bg-blue-50 text-blue-700 border-blue-200">
                {client.type_client || "Particulier"}
              </Badge>
            </div>
          </div>

          <div className="space-y-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-lg bg-muted flex items-center justify-center">
                <Phone className="w-5 h-5 text-muted-foreground" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Téléphone</p>
                <p className="font-medium">{client.phone || client.telephone}</p>
              </div>
            </div>

            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-lg bg-muted flex items-center justify-center">
                <Mail className="w-5 h-5 text-muted-foreground" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Email</p>
                <p className="font-medium">{client.email || "-"}</p>
              </div>
            </div>

            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-lg bg-muted flex items-center justify-center">
                <MapPin className="w-5 h-5 text-muted-foreground" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Adresse</p>
                <p className="font-medium">{client.address || client.adresse || "-"}</p>
              </div>
            </div>
          </div>

          <Dialog open={isEditOpen} onOpenChange={setIsEditOpen}>
            <DialogTrigger asChild>
              <Button className="w-full mt-6 gap-2">
                <Edit className="w-4 h-4" />
                Modifier le client
              </Button>
            </DialogTrigger>
            <DialogContent className="max-w-md">
              <DialogHeader>
                <DialogTitle>Modifier le client</DialogTitle>
                <DialogDescription>
                  Modifiez les informations du client
                </DialogDescription>
              </DialogHeader>
              <EditClientForm
                client={client}
                onSubmit={handleUpdateClient}
                isLoading={updateClientMutation.isPending}
              />
            </DialogContent>
          </Dialog>
        </Card>

        {/* Stats and History */}
        <div className="lg:col-span-2 space-y-6">
          {/* Statistics Cards */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <Card className="p-4">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-lg bg-primary/10 flex items-center justify-center">
                  <ShoppingCart className="w-5 h-5 text-primary" />
                </div>
                <div>
                  <p className="text-2xl font-heading font-bold">{client.totalOrders}</p>
                  <p className="text-xs text-muted-foreground">Commandes</p>
                </div>
              </div>
            </Card>

            <Card className="p-4">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-lg bg-success/10 flex items-center justify-center">
                  <DollarSign className="w-5 h-5 text-success" />
                </div>
                <div>
                  <p className="text-2xl font-heading font-bold">
                    {(client.totalAmount / 1000).toFixed(0)}K
                  </p>
                  <p className="text-xs text-muted-foreground">FCFA Total</p>
                </div>
              </div>
            </Card>

            <Card className="p-4">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-lg bg-info/10 flex items-center justify-center">
                  <TrendingUp className="w-5 h-5 text-info" />
                </div>
                <div>
                  <p className="text-2xl font-heading font-bold">{client.avgOrderValue}</p>
                  <p className="text-xs text-muted-foreground">FCFA/Cmd</p>
                </div>
              </div>
            </Card>

            <Card className="p-4">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-lg bg-warning/10 flex items-center justify-center">
                  <Clock className="w-5 h-5 text-warning" />
                </div>
                <div>
                  <p className="text-sm font-heading font-bold">{client.lastOrderDate}</p>
                  <p className="text-xs text-muted-foreground">Dernière cmd</p>
                </div>
              </div>
            </Card>
          </div>

          {/* Monthly Performance */}
          <Card className="p-6">
            <h3 className="text-lg font-semibold mb-4">Performance mensuelle</h3>
            <div className="space-y-4">
              {monthlyStats.map((stat, index) => (
                <div key={stat.month} className="space-y-2">
                  <div className="flex justify-between text-sm">
                    <span className="font-medium">{stat.month} 2024</span>
                    <span className="text-muted-foreground">
                      {stat.orders} cmd · {(stat.amount / 1000).toFixed(0)}K FCFA
                    </span>
                  </div>
                  <Progress
                    value={(stat.orders / 30) * 100}
                    className="h-2"
                  />
                </div>
              ))}
            </div>
          </Card>

          {/* Order History */}
          <Card className="p-6">
            <h3 className="text-lg font-semibold mb-4">Historique des commandes</h3>
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="text-left border-b border-border">
                    <th className="pb-3 text-sm font-medium text-muted-foreground">ID</th>
                    <th className="pb-3 text-sm font-medium text-muted-foreground">Date</th>
                    <th className="pb-3 text-sm font-medium text-muted-foreground">Quantité</th>
                    <th className="pb-3 text-sm font-medium text-muted-foreground">Montant</th>
                    <th className="pb-3 text-sm font-medium text-muted-foreground">Statut</th>
                  </tr>
                </thead>
                <tbody>
                  {orderHistory.map((order) => (
                    <tr key={order.id} className="border-b border-border/50">
                      <td className="py-3 font-mono text-sm">{order.id}</td>
                      <td className="py-3 text-sm">{order.date}</td>
                      <td className="py-3 text-sm">{order.quantity} bonbonnes</td>
                      <td className="py-3 text-sm font-medium">
                        {order.amount.toLocaleString()} FCFA
                      </td>
                      <td className="py-3">
                        {order.status === "delivered" ? (
                          <div className="flex items-center gap-1 text-success">
                            <CheckCircle className="w-4 h-4" />
                            <span className="text-sm">Livrée</span>
                          </div>
                        ) : (
                          <div className="flex items-center gap-1 text-destructive">
                            <XCircle className="w-4 h-4" />
                            <span className="text-sm">Annulée</span>
                          </div>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </Card>
        </div>
      </div>
    </DashboardLayout>
  );
};

export default ClientDetail;
