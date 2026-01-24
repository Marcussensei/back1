import { useParams, useNavigate } from "react-router-dom";
import { DashboardLayout } from "@/components/layout/DashboardLayout";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Progress } from "@/components/ui/progress";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { useToast } from "@/hooks/use-toast";
import {
  ArrowLeft,
  Phone,
  Mail,
  MapPin,
  Calendar,
  Truck,
  Package,
  TrendingUp,
  Clock,
  Star,
  Edit,
  MoreVertical,
  CheckCircle,
  XCircle,
  AlertCircle,
  RefreshCw,
} from "lucide-react";
import { useAgent } from "@/hooks/useApi";

// Mock data for the agent
const agentData = {
  "AG-001": {
    id: "AG-001",
    name: "Kofi Mensah",
    initials: "KM",
    phone: "+228 90 12 34 56",
    email: "kofi.mensah@essivi.tg",
    address: "Quartier Bè, Lomé, Togo",
    tricycle: "TO-1234-AA",
    status: "active",
    deliveries: 1245,
    hireDate: "15/03/2023",
    rating: 4.8,
    completionRate: 98,
    onTimeRate: 95,
    totalRevenue: 2450000,
    thisMonthDeliveries: 156,
    thisMonthRevenue: 312000,
  },
  "AG-002": {
    id: "AG-002",
    name: "Ama Diallo",
    initials: "AD",
    phone: "+228 91 23 45 67",
    email: "ama.diallo@essivi.tg",
    address: "Quartier Tokoin, Lomé, Togo",
    tricycle: "TO-5678-BB",
    status: "active",
    deliveries: 987,
    hireDate: "22/06/2023",
    rating: 4.6,
    completionRate: 96,
    onTimeRate: 92,
    totalRevenue: 1974000,
    thisMonthDeliveries: 134,
    thisMonthRevenue: 268000,
  },
};

const deliveryHistory = [
  {
    id: "LIV-2024-001",
    client: "Restaurant Le Palmier",
    date: "24/12/2024",
    time: "14:30",
    status: "completed",
    amount: 2500,
    zone: "Tokoin",
  },
  {
    id: "LIV-2024-002",
    client: "Boutique Mode Express",
    date: "24/12/2024",
    time: "11:15",
    status: "completed",
    amount: 3000,
    zone: "Bè",
  },
  {
    id: "LIV-2024-003",
    client: "Pharmacie Centrale",
    date: "23/12/2024",
    time: "16:45",
    status: "completed",
    amount: 1500,
    zone: "Nyékonakpoè",
  },
  {
    id: "LIV-2024-004",
    client: "Supermarché Bonheur",
    date: "23/12/2024",
    time: "09:00",
    status: "cancelled",
    amount: 4000,
    zone: "Adidogomé",
  },
  {
    id: "LIV-2024-005",
    client: "Hôtel Atlantic",
    date: "22/12/2024",
    time: "13:20",
    status: "completed",
    amount: 5500,
    zone: "Boulevard",
  },
  {
    id: "LIV-2024-006",
    client: "Clinique Espoir",
    date: "22/12/2024",
    time: "10:00",
    status: "completed",
    amount: 2000,
    zone: "Hédzranawoé",
  },
];

const monthlyStats = [
  { month: "Juil", deliveries: 120, revenue: 240000 },
  { month: "Août", deliveries: 135, revenue: 270000 },
  { month: "Sept", deliveries: 142, revenue: 284000 },
  { month: "Oct", deliveries: 128, revenue: 256000 },
  { month: "Nov", deliveries: 151, revenue: 302000 },
  { month: "Déc", deliveries: 156, revenue: 312000 },
];

const statusConfig = {
  active: {
    label: "Actif",
    className: "bg-success/10 text-success border-success/20",
  },
  inactive: {
    label: "Inactif",
    className: "bg-muted text-muted-foreground border-border",
  },
};

const deliveryStatusConfig = {
  completed: {
    label: "Livré",
    icon: CheckCircle,
    className: "text-success",
  },
  cancelled: {
    label: "Annulé",
    icon: XCircle,
    className: "text-destructive",
  },
  pending: {
    label: "En attente",
    icon: AlertCircle,
    className: "text-warning",
  },
};

const AgentDetail = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const { toast } = useToast();

  const { data: agentData, isLoading, isError, error, refetch } = useAgent(Number(id));

  const agent = agentData;

  if (isLoading) {
    return (
      <DashboardLayout title="Détail agent" subtitle="Chargement...">
        <div className="flex justify-center items-center h-64">
          <RefreshCw className="w-8 h-8 animate-spin" />
        </div>
      </DashboardLayout>
    );
  }

  if (isError || !agent) {
    return (
      <DashboardLayout title="Détail agent" subtitle="Erreur de chargement">
        <div className="text-center py-12 bg-red-50 rounded-lg border border-red-200 p-6">
          <p className="text-red-800 font-semibold mb-2">Erreur de chargement</p>
          <p className="text-red-600 text-sm mb-4">{error?.message || "Agent non trouvé"}</p>
          <Button onClick={() => refetch()} variant="outline" size="sm">
            Réessayer
          </Button>
        </div>
      </DashboardLayout>
    );
  }

  return (
    <DashboardLayout
      title={agent.name}
      subtitle={`Agent ${agent.id}`}
    >
      {/* Back Button */}
      <Button
        variant="ghost"
        className="mb-6 gap-2"
        onClick={() => navigate("/agents")}
      >
        <ArrowLeft className="w-4 h-4" />
        Retour aux agents
      </Button>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Profile Card */}
        <Card className="lg:col-span-1">
          <CardContent className="pt-6">
            <div className="text-center mb-6">
              <Avatar className="w-24 h-24 mx-auto mb-4 border-4 border-primary/20">
                <AvatarImage src="" />
                <AvatarFallback className="bg-primary/10 text-primary text-2xl font-bold">
                  {agent.name?.split(" ").map((n: string) => n[0]).join("").toUpperCase().slice(0, 2) || "??"}
                </AvatarFallback>
              </Avatar>
              <h2 className="text-xl font-bold">{agent.name}</h2>
              <p className="text-muted-foreground">Agent #{agent.id}</p>
              <Badge
                variant="outline"
                className={`mt-2 ${statusConfig[agent.status as keyof typeof statusConfig]?.className || ""}`}
              >
                {statusConfig[agent.status as keyof typeof statusConfig]?.label || agent.status}
              </Badge>
            </div>

            <div className="space-y-4">
              <div className="flex items-center gap-3 text-sm">
                <Phone className="w-4 h-4 text-primary" />
                <span>{agent.phone || "Non spécifié"}</span>
              </div>
              <div className="flex items-center gap-3 text-sm">
                <Mail className="w-4 h-4 text-primary" />
                <span>{agent.email || "Non spécifié"}</span>
              </div>
              <div className="flex items-center gap-3 text-sm">
                <MapPin className="w-4 h-4 text-primary" />
                <span>{agent.zone_livraison || "Non spécifiée"}</span>
              </div>
              <div className="flex items-center gap-3 text-sm">
                <Calendar className="w-4 h-4 text-primary" />
                <span>Embauché le {agent.date_embauche || "Non spécifiée"}</span>
              </div>
              <div className="flex items-center gap-3 text-sm">
                <Truck className="w-4 h-4 text-primary" />
                <span className="font-mono">{agent.tricycle_id || "Non assigné"}</span>
              </div>
            </div>

            <div className="mt-6 pt-6 border-t border-border">
              <div className="flex items-center justify-between mb-2">
                <span className="text-sm text-muted-foreground">Note moyenne</span>
                <div className="flex items-center gap-1">
                  <Star className="w-4 h-4 text-warning fill-warning" />
                  <span className="font-bold">{agent.note_moyenne || "N/A"}</span>
                </div>
              </div>
              <Progress value={(agent.note_moyenne || 0) * 20} className="h-2" />
            </div>

            <Button className="w-full mt-6 gap-2">
              <Edit className="w-4 h-4" />
              Modifier le profil
            </Button>
          </CardContent>
        </Card>

        {/* Stats and History */}
        <div className="lg:col-span-2 space-y-6">
          {/* Stats Cards */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <Card>
              <CardContent className="pt-4 pb-4">
                <div className="flex items-center gap-3">
                  <div className="p-2 rounded-lg bg-primary/10">
                    <Package className="w-5 h-5 text-primary" />
                  </div>
                  <div>
                    <p className="text-2xl font-bold">{agent.deliveries.toLocaleString()}</p>
                    <p className="text-xs text-muted-foreground">Livraisons totales</p>
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardContent className="pt-4 pb-4">
                <div className="flex items-center gap-3">
                  <div className="p-2 rounded-lg bg-success/10">
                    <CheckCircle className="w-5 h-5 text-success" />
                  </div>
                  <div>
                    <p className="text-2xl font-bold">{agent.completionRate}%</p>
                    <p className="text-xs text-muted-foreground">Taux de succès</p>
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardContent className="pt-4 pb-4">
                <div className="flex items-center gap-3">
                  <div className="p-2 rounded-lg bg-info/10">
                    <Clock className="w-5 h-5 text-info" />
                  </div>
                  <div>
                    <p className="text-2xl font-bold">{agent.onTimeRate}%</p>
                    <p className="text-xs text-muted-foreground">À l'heure</p>
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardContent className="pt-4 pb-4">
                <div className="flex items-center gap-3">
                  <div className="p-2 rounded-lg bg-warning/10">
                    <TrendingUp className="w-5 h-5 text-warning" />
                  </div>
                  <div>
                    <p className="text-2xl font-bold">{(agent.totalRevenue / 1000).toFixed(0)}K</p>
                    <p className="text-xs text-muted-foreground">Revenu (FCFA)</p>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Tabs */}
          <Tabs defaultValue="history" className="w-full">
            <TabsList className="grid w-full grid-cols-2">
              <TabsTrigger value="history">Historique des livraisons</TabsTrigger>
              <TabsTrigger value="stats">Statistiques mensuelles</TabsTrigger>
            </TabsList>

            <TabsContent value="history">
              <Card>
                <CardHeader>
                  <CardTitle className="text-lg">Dernières livraisons</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="space-y-4">
                    {deliveryHistory.map((delivery, index) => {
                      const StatusIcon = deliveryStatusConfig[delivery.status as keyof typeof deliveryStatusConfig].icon;
                      return (
                        <div
                          key={delivery.id}
                          className="flex items-center justify-between p-4 rounded-lg bg-muted/50 hover:bg-muted transition-colors animate-fade-in"
                          style={{ animationDelay: `${index * 50}ms` }}
                        >
                          <div className="flex items-center gap-4">
                            <StatusIcon
                              className={`w-5 h-5 ${deliveryStatusConfig[delivery.status as keyof typeof deliveryStatusConfig].className}`}
                            />
                            <div>
                              <p className="font-medium">{delivery.client}</p>
                              <p className="text-sm text-muted-foreground">
                                {delivery.date} à {delivery.time} • {delivery.zone}
                              </p>
                            </div>
                          </div>
                          <div className="text-right">
                            <p className="font-bold">{delivery.amount.toLocaleString()} FCFA</p>
                            <Badge variant="outline" className="text-xs">
                              {delivery.id}
                            </Badge>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="stats">
              <Card>
                <CardHeader>
                  <CardTitle className="text-lg">Performance des 6 derniers mois</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="space-y-4">
                    {monthlyStats.map((stat, index) => (
                      <div
                        key={stat.month}
                        className="animate-fade-in"
                        style={{ animationDelay: `${index * 50}ms` }}
                      >
                        <div className="flex justify-between text-sm mb-2">
                          <span className="font-medium">{stat.month}</span>
                          <span className="text-muted-foreground">
                            {stat.deliveries} livraisons • {(stat.revenue / 1000).toFixed(0)}K FCFA
                          </span>
                        </div>
                        <Progress
                          value={(stat.deliveries / 160) * 100}
                          className="h-3"
                        />
                      </div>
                    ))}
                  </div>

                  <div className="mt-6 pt-6 border-t border-border grid grid-cols-2 gap-4">
                    <div className="text-center p-4 rounded-lg bg-primary/5">
                      <p className="text-3xl font-bold text-primary">
                        {agent.thisMonthDeliveries}
                      </p>
                      <p className="text-sm text-muted-foreground">Livraisons ce mois</p>
                    </div>
                    <div className="text-center p-4 rounded-lg bg-success/5">
                      <p className="text-3xl font-bold text-success">
                        {(agent.thisMonthRevenue / 1000).toFixed(0)}K
                      </p>
                      <p className="text-sm text-muted-foreground">Revenu ce mois (FCFA)</p>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </TabsContent>
          </Tabs>
        </div>
      </div>
    </DashboardLayout>
  );
};

export default AgentDetail;
