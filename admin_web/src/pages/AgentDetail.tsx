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
import { useAgent, useAgentDeliveries, useAgentMonthlyStats } from "@/hooks/useApi";

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

  const agentId = Number(id);
  const { data: agent, isLoading, isError, error, refetch } = useAgent(agentId);
  const { data: deliveryResponse, isLoading: deliveriesLoading } = useAgentDeliveries(agentId);
  const { data: statsData, isLoading: statsLoading } = useAgentMonthlyStats(agentId);

  // Extraire l'array de livraisons de la réponse
  const deliveryData = Array.isArray(deliveryResponse) ? deliveryResponse : (deliveryResponse?.livraisons || []);

  // Mapper les livraisons API au format attendu
  const deliveryHistory = deliveryData?.map((delivery: any) => ({
    id: delivery.id,
    client: delivery.nom_point_vente || "Client inconnu",
    date: new Date(delivery.created_at).toLocaleDateString('fr-FR'),
    time: new Date(delivery.created_at).toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' }),
    status: delivery.statut?.toLowerCase() === 'livree' ? 'completed' : delivery.statut?.toLowerCase() === 'annulee' ? 'cancelled' : 'pending',
    amount: delivery.montant_percu || 0,
    zone: delivery.adresse_livraison || "Zone inconnue",
  })) || [];

  // Mapper les statistiques mensuelles
  const monthlyStats = statsData?.monthly_stats?.slice(0, 6).reverse() || [];

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
                    <p className="text-2xl font-bold">{agent.deliveries || 0}</p>
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
                    <p className="text-2xl font-bold">{statsData?.global_stats?.completion_rate || 0}%</p>
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
                    <p className="text-2xl font-bold">{statsData?.global_stats?.on_time_rate || 0}%</p>
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
                    <p className="text-2xl font-bold">{((statsData?.global_stats?.total_revenue || 0) / 1000).toFixed(0)}K</p>
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
                  {deliveriesLoading ? (
                    <div className="flex justify-center items-center h-64">
                      <RefreshCw className="w-6 h-6 animate-spin" />
                    </div>
                  ) : deliveryHistory.length > 0 ? (
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
                  ) : (
                    <div className="text-center py-8 text-muted-foreground">
                      <p>Aucune livraison enregistrée pour cet agent</p>
                    </div>
                  )}
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="stats">
              <Card>
                <CardHeader>
                  <CardTitle className="text-lg">Performance des 6 derniers mois</CardTitle>
                </CardHeader>
                <CardContent>
                  {statsLoading ? (
                    <div className="flex justify-center items-center h-64">
                      <RefreshCw className="w-6 h-6 animate-spin" />
                    </div>
                  ) : monthlyStats.length > 0 ? (
                    <>
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
                            {statsData?.current_month?.deliveries || 0}
                          </p>
                          <p className="text-sm text-muted-foreground">Livraisons ce mois</p>
                        </div>
                        <div className="text-center p-4 rounded-lg bg-success/5">
                          <p className="text-3xl font-bold text-success">
                            {((statsData?.current_month?.revenue || 0) / 1000).toFixed(0)}K
                          </p>
                          <p className="text-sm text-muted-foreground">Revenu ce mois (FCFA)</p>
                        </div>
                      </div>
                    </>
                  ) : (
                    <div className="text-center py-8 text-muted-foreground">
                      <p>Aucune donnée statistique disponible</p>
                    </div>
                  )}
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
