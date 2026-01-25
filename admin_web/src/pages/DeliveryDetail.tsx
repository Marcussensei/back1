import { useState, useEffect } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { DashboardLayout } from "@/components/layout/DashboardLayout";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Separator } from "@/components/ui/separator";
import { Progress } from "@/components/ui/progress";
import {
  ArrowLeft,
  MapPin,
  Phone,
  Clock,
  Package,
  Truck,
  CheckCircle2,
  Circle,
  User,
  Calendar,
  Wallet,
  Navigation,
  MessageSquare,
  Printer,
  Share2,
  Send,
} from "lucide-react";
import { cn } from "@/lib/utils";
import { deliveriesAPI } from "@/lib/api";
import { useAuth } from "@/hooks/useAuth";
import { useDeliveryTrackingHistory, useDeliveryNotificationHistory, useSendDeliveryNotification } from "@/hooks/useApi";
import { SendNotificationModal, NotificationRecord } from "@/components/deliveries/SendNotificationModal";
import { DeliveryMap } from "@/components/deliveries/DeliveryMap";
import { NotificationHistory } from "@/components/deliveries/NotificationHistory";




const statusConfig = {
  completed: {
    label: "Livré",
    className: "bg-success/10 text-success border-success/20",
    progress: 100,
  },
  in_progress: {
    label: "En cours",
    className: "bg-warning/10 text-warning border-warning/20",
    progress: 66,
  },
  pending: {
    label: "En attente",
    className: "bg-info/10 text-info border-info/20",
    progress: 33,
  },
  cancelled: {
    label: "Annulé",
    className: "bg-destructive/10 text-destructive border-destructive/20",
    progress: 0,
  },
};

interface TrackingStep {
  id: string;
  title: string;
  description: string;
  time: string | null;
  completed: boolean;
  current: boolean;
}

const DeliveryDetail = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { user, loading: authLoading } = useAuth();
  const [delivery, setDelivery] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [notificationModalOpen, setNotificationModalOpen] = useState(false);
  const [trackingSteps, setTrackingSteps] = useState<TrackingStep[]>([]);

  // Fetch tracking history and notifications from API
  const { data: trackingData, isLoading: trackingLoading } = useDeliveryTrackingHistory(delivery?.id || 0);
  const { data: notificationsData, isLoading: notificationsLoading } = useDeliveryNotificationHistory(delivery?.id || 0);
  const sendNotification = useSendDeliveryNotification(delivery?.id || 0);

  const handleNotificationSent = (notification: NotificationRecord) => {
    // Refetch notifications to show the newly sent one
    // The hook will automatically update when the mutation succeeds
  };

  useEffect(() => {
    console.log('DeliveryDetail: useEffect triggered', { id, user: !!user, authLoading });

    if (!id || !user || authLoading) {
      console.log('DeliveryDetail: Skipping fetch', { id, user: !!user, authLoading });
      return;
    }

    console.log('DeliveryDetail: Starting fetch for delivery', id);

    const fetchDelivery = async () => {
      try {
        setLoading(true);
        setError(null);
        console.log('DeliveryDetail: Calling deliveriesAPI.getById', id);
        const data = await deliveriesAPI.getById(parseInt(id));
        console.log('DeliveryDetail: API response received', data);

        // Map backend data to frontend format
        const mappedData = {
          id: `LIV-${data.id}`,
          agent: data.agent_nom ? {
            name: data.agent_nom,
            initials: data.agent_nom.split(' ').map((n: string) => n[0]).join('').toUpperCase(),
            phone: data.agent_telephone
          } : null,
          client: data.nom_point_vente,
          clientPhone: data.client_telephone,
          address: data.adresse_livraison,
          quantity: data.quantite,
          amount: data.montant_percu,
          date: data.date_livraison,
          time: data.heure_livraison,
          status: data.statut === 'livree' ? 'completed' :
                  data.statut === 'completed' ? 'completed' :
                  data.statut === 'assigned' ? 'in_progress' :
                  data.statut === 'en_cours' ? 'in_progress' :
                  data.statut === 'annulee' ? 'cancelled' : 'pending',
          lat: data.latitude_gps,
          lng: data.longitude_gps,
          notes: '', // No notes field in backend
        };

        console.log('DeliveryDetail: Setting delivery data', mappedData);
        setDelivery(mappedData);
      } catch (err) {
        console.error('DeliveryDetail: Error fetching delivery', err);
        setError(err instanceof Error ? err.message : 'Erreur lors du chargement');
      } finally {
        setLoading(false);
      }
    };

    fetchDelivery();
  }, [id, user, authLoading]);

  // Update tracking steps when tracking data changes
  useEffect(() => {
    if (trackingData?.tracking_steps) {
      setTrackingSteps(trackingData.tracking_steps);
    }
  }, [trackingData]);

  if (loading) {
    return (
      <DashboardLayout title="Chargement..." subtitle="">
        <div className="flex flex-col items-center justify-center py-20">
          <div className="w-8 h-8 border-4 border-primary border-t-transparent rounded-full animate-spin mb-4" />
          <h2 className="text-xl font-semibold mb-2">Chargement de la livraison</h2>
          <p className="text-muted-foreground">Veuillez patienter...</p>
        </div>
      </DashboardLayout>
    );
  }

  if (error) {
    return (
      <DashboardLayout title="Erreur" subtitle="">
        <div className="flex flex-col items-center justify-center py-20">
          <Package className="w-16 h-16 text-destructive mb-4" />
          <h2 className="text-xl font-semibold mb-2">Erreur de chargement</h2>
          <p className="text-muted-foreground mb-6">{error}</p>
          <Button onClick={() => navigate("/deliveries")}>
            <ArrowLeft className="w-4 h-4 mr-2" />
            Retour aux livraisons
          </Button>
        </div>
      </DashboardLayout>
    );
  }

  if (!delivery) {
    return (
      <DashboardLayout title="Livraison introuvable" subtitle="">
        <div className="flex flex-col items-center justify-center py-20">
          <Package className="w-16 h-16 text-muted-foreground mb-4" />
          <h2 className="text-xl font-semibold mb-2">Livraison introuvable</h2>
          <p className="text-muted-foreground mb-6">
            La livraison que vous recherchez n'existe pas.
          </p>
          <Button onClick={() => navigate("/deliveries")}>
            <ArrowLeft className="w-4 h-4 mr-2" />
            Retour aux livraisons
          </Button>
        </div>
      </DashboardLayout>
    );
  }

  const statusInfo = statusConfig[delivery.status as keyof typeof statusConfig];

  return (
    <DashboardLayout
      title={`Livraison ${delivery.id}`}
      subtitle="Détails et suivi en temps réel"
    >
      {/* Back Button */}
      <Button
        variant="ghost"
        className="mb-6 gap-2 -ml-2"
        onClick={() => navigate("/deliveries")}
      >
        <ArrowLeft className="w-4 h-4" />
        Retour aux livraisons
      </Button>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Main Content - Left Side */}
        <div className="lg:col-span-2 space-y-6">
          {/* Status Overview Card */}
          <Card className="overflow-hidden">
            <div className="p-6 bg-gradient-to-r from-primary/5 to-accent/5">
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center gap-3">
                  <div className="w-12 h-12 rounded-xl bg-primary/10 flex items-center justify-center">
                    <Truck className="w-6 h-6 text-primary" />
                  </div>
                  <div>
                    <h2 className="text-lg font-semibold">{delivery.id}</h2>
                    <p className="text-sm text-muted-foreground">
                      {delivery.date} à {delivery.time}
                    </p>
                  </div>
                </div>
                <Badge variant="outline" className={statusInfo.className}>
                  {statusInfo.label}
                </Badge>
              </div>

              <div className="space-y-2">
                <div className="flex justify-between text-sm">
                  <span className="text-muted-foreground">Progression</span>
                  <span className="font-medium">{statusInfo.progress}%</span>
                </div>
                <Progress value={statusInfo.progress} className="h-2" />
              </div>
            </div>
          </Card>

          {/* Tracking Timeline */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Clock className="w-5 h-5 text-primary" />
                Suivi en temps réel
              </CardTitle>
            </CardHeader>
            <CardContent>
              {trackingLoading ? (
                <div className="flex items-center justify-center py-8">
                  <div className="w-6 h-6 border-3 border-primary border-t-transparent rounded-full animate-spin" />
                </div>
              ) : (
                <div className="relative">
                  {trackingSteps.map((step, index) => (
                    <div key={step.id} className="flex gap-4 pb-8 last:pb-0">
                      {/* Timeline Line */}
                      <div className="flex flex-col items-center">
                        <div
                          className={cn(
                            "w-10 h-10 rounded-full flex items-center justify-center transition-all duration-300",
                            step.completed
                              ? "bg-success text-success-foreground"
                              : step.current
                              ? "bg-primary text-primary-foreground animate-pulse"
                              : "bg-muted text-muted-foreground"
                          )}
                        >
                          {step.completed ? (
                            <CheckCircle2 className="w-5 h-5" />
                          ) : (
                            <Circle className="w-5 h-5" />
                          )}
                        </div>
                        {index < trackingSteps.length - 1 && (
                          <div
                            className={cn(
                              "w-0.5 flex-1 mt-2 transition-all duration-300",
                              step.completed ? "bg-success" : "bg-muted"
                            )}
                          />
                        )}
                      </div>

                      {/* Content */}
                      <div className="flex-1 pb-2">
                        <div className="flex items-center justify-between">
                          <h4
                            className={cn(
                              "font-medium",
                              step.current && "text-primary"
                            )}
                          >
                            {step.title}
                          </h4>
                          {step.time && (
                            <span className="text-sm text-muted-foreground">
                              {step.time}
                            </span>
                          )}
                        </div>
                        <p className="text-sm text-muted-foreground mt-1">
                          {step.description}
                        </p>
                        {step.current && (
                          <div className="mt-3 flex items-center gap-2">
                            <div className="w-2 h-2 rounded-full bg-primary animate-ping" />
                            <span className="text-xs text-primary font-medium">
                              En cours...
                            </span>
                          </div>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>

          {/* Delivery Info Grid */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <Card>
              <CardHeader className="pb-3">
                <CardTitle className="text-base flex items-center gap-2">
                  <Package className="w-4 h-4 text-primary" />
                  Détails de la commande
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Quantité</span>
                  <span className="font-semibold">{delivery.quantity} sachets</span>
                </div>
                <Separator />
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Montant</span>
                  <span className="font-semibold text-primary">
                    {delivery.amount.toLocaleString()} FCFA
                  </span>
                </div>
                {delivery.notes && (
                  <>
                    <Separator />
                    <div>
                      <span className="text-muted-foreground text-sm">Notes</span>
                      <p className="text-sm mt-1">{delivery.notes}</p>
                    </div>
                  </>
                )}
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="pb-3">
                <CardTitle className="text-base flex items-center gap-2">
                  <MapPin className="w-4 h-4 text-primary" />
                  Destination
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                <div>
                  <span className="text-muted-foreground text-sm">Adresse</span>
                  <p className="font-medium">{delivery.address}</p>
                </div>
                <Separator />
                <div className="flex gap-2">
                  <Button variant="outline" size="sm" className="flex-1 gap-2">
                    <Navigation className="w-4 h-4" />
                    Itinéraire
                  </Button>
                  <Button variant="outline" size="sm" className="flex-1 gap-2">
                    <MapPin className="w-4 h-4" />
                    Voir carte
                  </Button>
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Interactive Map - Temporarily disabled due to rendering issues */}
          {/* <DeliveryMap delivery={delivery} /> */}
        </div>

        {/* Sidebar - Right Side */}
        <div className="space-y-6">
          {/* Client Card */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base flex items-center gap-2">
                <User className="w-4 h-4 text-primary" />
                Client
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex items-center gap-3">
                <Avatar className="w-12 h-12">
                  <AvatarFallback className="bg-accent text-accent-foreground">
                    {delivery.client.charAt(0)}
                  </AvatarFallback>
                </Avatar>
                <div>
                  <p className="font-medium">{delivery.client}</p>
                  <p className="text-sm text-muted-foreground">Client régulier</p>
                </div>
              </div>
              <div className="flex gap-2">
                <Button variant="outline" size="sm" className="flex-1 gap-2">
                  <Phone className="w-4 h-4" />
                  Appeler
                </Button>
                <Button 
                  variant="outline" 
                  size="sm" 
                  className="flex-1 gap-2"
                  onClick={() => setNotificationModalOpen(true)}
                >
                  <Send className="w-4 h-4" />
                  Notifier
                </Button>
              </div>
              <div className="text-sm text-muted-foreground flex items-center gap-2">
                <Phone className="w-4 h-4" />
                {delivery.clientPhone}
              </div>
            </CardContent>
          </Card>

          {/* Agent Card */}
          {delivery.agent ? (
            <Card>
              <CardHeader>
                <CardTitle className="text-base flex items-center gap-2">
                  <Truck className="w-4 h-4 text-primary" />
                  Livreur assigné
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="flex items-center gap-3">
                  <Avatar className="w-12 h-12 border-2 border-primary/20">
                    <AvatarFallback className="bg-primary text-primary-foreground">
                      {delivery.agent.initials}
                    </AvatarFallback>
                  </Avatar>
                  <div>
                    <p className="font-medium">{delivery.agent.name}</p>
                    <div className="flex items-center gap-1 text-sm text-success">
                      <div className="w-2 h-2 rounded-full bg-success animate-pulse" />
                      En ligne
                    </div>
                  </div>
                </div>
                <div className="flex gap-2">
                  <Button variant="outline" size="sm" className="flex-1 gap-2">
                    <Phone className="w-4 h-4" />
                    Appeler
                  </Button>
                  <Button variant="outline" size="sm" className="flex-1 gap-2">
                    <MapPin className="w-4 h-4" />
                    Localiser
                  </Button>
                </div>
                <div className="text-sm text-muted-foreground flex items-center gap-2">
                  <Phone className="w-4 h-4" />
                  {delivery.agent.phone}
                </div>
              </CardContent>
            </Card>
          ) : (
            <Card className="border-dashed border-2">
              <CardContent className="py-8 text-center">
                <User className="w-12 h-12 text-muted-foreground mx-auto mb-3" />
                <p className="font-medium mb-1">Aucun livreur assigné</p>
                <p className="text-sm text-muted-foreground mb-4">
                  Cette livraison est en attente d'assignation
                </p>
                <Button className="gap-2">
                  <User className="w-4 h-4" />
                  Assigner un livreur
                </Button>
              </CardContent>
            </Card>
          )}

          {/* Quick Actions */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Actions rapides</CardTitle>
            </CardHeader>
            <CardContent className="space-y-2">
              <Button variant="outline" className="w-full justify-start gap-2">
                <Printer className="w-4 h-4" />
                Imprimer le bon
              </Button>
              <Button variant="outline" className="w-full justify-start gap-2">
                <Share2 className="w-4 h-4" />
                Partager le suivi
              </Button>
              <Button variant="outline" className="w-full justify-start gap-2">
                <MessageSquare className="w-4 h-4" />
                Ajouter une note
              </Button>
            </CardContent>
          </Card>

          {/* Notification History */}
          {notificationsLoading ? (
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <MessageSquare className="w-5 h-5 text-primary" />
                  Historique des notifications
                </CardTitle>
              </CardHeader>
              <CardContent className="flex items-center justify-center py-8">
                <div className="w-6 h-6 border-3 border-primary border-t-transparent rounded-full animate-spin" />
              </CardContent>
            </Card>
          ) : (
            <NotificationHistory notifications={notificationsData?.notifications || []} />
          )}
        </div>
      </div>

      {/* Send Notification Modal */}
      <SendNotificationModal
        open={notificationModalOpen}
        onOpenChange={setNotificationModalOpen}
        delivery={delivery}
        onNotificationSent={handleNotificationSent}
      />
    </DashboardLayout>
  );
};

export default DeliveryDetail;
