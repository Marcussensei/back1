import { useState, useMemo } from "react";
import { DashboardLayout } from "@/components/layout/DashboardLayout";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
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
import { Search, Filter, MoreVertical, MapPin, Calendar, Eye, Download, Printer, UserPlus } from "lucide-react";
import AssignAgentModal from "@/components/deliveries/AssignAgentModal";
import { useToast } from "@/hooks/use-toast";
import { useNavigate } from "react-router-dom";
import { useDeliveries, useAssignDelivery } from "@/hooks/useApi";
import { Loader2 } from "lucide-react";

const statusConfig: Record<string, { label: string; className: string }> = {
  completed: {
    label: "Livré",
    className: "bg-green-100 text-green-800 border-green-200 dark:bg-green-900/20 dark:text-green-400 dark:border-green-800",
  },
  in_progress: {
    label: "En cours",
    className: "bg-blue-100 text-blue-800 border-blue-200 dark:bg-blue-900/20 dark:text-blue-400 dark:border-blue-800",
  },
  assigned: {
    label: "Assigné",
    className: "bg-purple-100 text-purple-800 border-purple-200 dark:bg-purple-900/20 dark:text-purple-400 dark:border-purple-800",
  },
  en_cours: {
    label: "En cours",
    className: "bg-blue-100 text-blue-800 border-blue-200 dark:bg-blue-900/20 dark:text-blue-400 dark:border-blue-800",
  },
  pending: {
    label: "En attente",
    className: "bg-yellow-100 text-yellow-800 border-yellow-200 dark:bg-yellow-900/20 dark:text-yellow-400 dark:border-yellow-800",
  },
  en_attente: {
    label: "En attente",
    className: "bg-yellow-100 text-yellow-800 border-yellow-200 dark:bg-yellow-900/20 dark:text-yellow-400 dark:border-yellow-800",
  },
  cancelled: {
    label: "Annulé",
    className: "bg-red-100 text-red-800 border-red-200 dark:bg-red-900/20 dark:text-red-400 dark:border-red-800",
  },
  livré: {
    label: "Livré",
    className: "bg-green-100 text-green-800 border-green-200 dark:bg-green-900/20 dark:text-green-400 dark:border-green-800",
  },
  terminee: {
    label: "Terminée",
    className: "bg-emerald-100 text-emerald-800 border-emerald-200 dark:bg-emerald-900/20 dark:text-emerald-400 dark:border-emerald-800",
  },
};

// Normalize status from backend
const normalizeStatus = (status: string): string => {
  if (!status) return 'pending';
  const normalized = status.toLowerCase().trim();
  if (normalized === 'assigned' || normalized === 'en_cours' || normalized === 'en cours') {
    return 'in_progress';
  }
  if (normalized === 'en_attente' || normalized === 'en attente' || normalized === 'pending') {
    return 'pending';
  }
  if (normalized === 'livré' || normalized === 'livree' || normalized === 'completed' || normalized === 'terminee') {
    return 'completed';
  }
  // Return status as-is if not recognized, with fallback mapping
  return normalized in statusConfig ? normalized : 'pending';
};

const Deliveries = () => {
  const { toast } = useToast();
  const navigate = useNavigate();
  const [assignModalOpen, setAssignModalOpen] = useState(false);
  const [selectedDelivery, setSelectedDelivery] = useState<any>(null);
  const [searchTerm, setSearchTerm] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");
  
  const { data: deliveriesData, isLoading, error } = useDeliveries();
  const assignDeliveryMutation = useAssignDelivery(selectedDelivery?.id);
  
  // Transform backend data to frontend format
  const deliveries = useMemo(() => {
    if (!deliveriesData?.livraisons) return [];
    
    return deliveriesData.livraisons.map((d: any) => {
      // Parse datetime
      const dateStr = d.date_livraison ? new Date(d.date_livraison).toLocaleDateString('fr-FR') : '';
      const timeStr = d.heure_livraison ? d.heure_livraison.substring(0, 5) : '';
      
      // Get agent initials
      const agentInitials = d.agent_nom
        ? d.agent_nom
            .split(' ')
            .map((n: string) => n[0])
            .join('')
            .toUpperCase()
        : null;
      
      return {
        id: d.id.toString(),
        agent: d.agent_nom ? {
          name: d.agent_nom,
          initials: agentInitials,
          id: d.agent_id
        } : null,
        client: d.nom_point_vente || 'Client inconnu',
        clientPhone: d.client_telephone || '',
        address: d.adresse_livraison || '',
        quantity: d.quantite || 0,
        amount: d.montant_percu || 0,
        date: dateStr,
        time: timeStr,
        status: normalizeStatus(d.statut),
        lat: d.latitude_gps || 0,
        lng: d.longitude_gps || 0,
        clientId: d.client_id,
        commandeId: d.commande_id,
        originalData: d
      };
    });
  }, [deliveriesData]);
  
  // Filter deliveries
  const filteredDeliveries = useMemo(() => {
    return deliveries.filter(d => {
      const matchesSearch = 
        d.id.toLowerCase().includes(searchTerm.toLowerCase()) ||
        d.client.toLowerCase().includes(searchTerm.toLowerCase()) ||
        d.address.toLowerCase().includes(searchTerm.toLowerCase());
      
      const matchesStatus = statusFilter === 'all' || d.status === statusFilter;
      
      return matchesSearch && matchesStatus;
    });
  }, [deliveries, searchTerm, statusFilter]);

  const handleOpenAssignModal = (delivery: any) => {
    setSelectedDelivery(delivery);
    setAssignModalOpen(true);
  };

  const handleAssign = async (deliveryId: string, agentId: string) => {
    try {
      await assignDeliveryMutation.mutateAsync(parseInt(agentId));
      toast({
        title: "Livreur assigné",
        description: `La livraison ${deliveryId} a été assignée avec succès.`,
      });
      setAssignModalOpen(false);
    } catch (error) {
      toast({
        title: "Erreur",
        description: "Impossible d'assigner le livreur",
        variant: "destructive"
      });
    }
  };

  const pendingCount = filteredDeliveries.filter(d => d.status === "pending").length;
  const totalQuantity = filteredDeliveries.reduce((sum, d) => sum + d.quantity, 0);
  const totalAmount = filteredDeliveries.reduce((sum, d) => sum + d.amount, 0);
  const successRate = filteredDeliveries.length > 0 
    ? Math.round((filteredDeliveries.filter((d) => d.status === "completed").length / filteredDeliveries.length) * 100)
    : 0;
  
  return (
    <DashboardLayout
      title="Livraisons"
      subtitle={`Suivi et historique des livraisons ${pendingCount > 0 ? `• ${pendingCount} en attente` : ""}`}
    >
      {/* Filters Bar */}
      <div className="flex flex-col lg:flex-row gap-4 justify-between mb-6">
        <div className="flex flex-wrap gap-3">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
            <Input
              placeholder="Rechercher..."
              className="pl-10 w-64 bg-card"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>
          <Select value={statusFilter} onValueChange={setStatusFilter}>
            <SelectTrigger className="w-40 bg-card">
              <SelectValue placeholder="Statut" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">Tous les statuts</SelectItem>
              <SelectItem value="completed">Livrés</SelectItem>
              <SelectItem value="in_progress">En cours</SelectItem>
              <SelectItem value="assigned">Assignés</SelectItem>
              <SelectItem value="pending">En attente</SelectItem>
              <SelectItem value="cancelled">Annulés</SelectItem>
            </SelectContent>
          </Select>
          <Select defaultValue="today">
            <SelectTrigger className="w-40 bg-card">
              <SelectValue placeholder="Période" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="today">Aujourd'hui</SelectItem>
              <SelectItem value="week">Cette semaine</SelectItem>
              <SelectItem value="month">Ce mois</SelectItem>
              <SelectItem value="custom">Personnalisé</SelectItem>
            </SelectContent>
          </Select>
          <Button variant="outline" className="gap-2">
            <Filter className="w-4 h-4" />
            Plus de filtres
          </Button>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" className="gap-2">
            <Download className="w-4 h-4" />
            Exporter
          </Button>
          <Button variant="outline" className="gap-2">
            <Printer className="w-4 h-4" />
            Imprimer
          </Button>
        </div>
      </div>

      {/* Summary Stats */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
        <div className="bg-card rounded-xl p-4 shadow-sm">
          <p className="text-sm text-muted-foreground">Total livraisons</p>
          <p className="text-2xl font-heading font-bold">{filteredDeliveries.length}</p>
        </div>
        <div className="bg-card rounded-xl p-4 shadow-sm">
          <p className="text-sm text-muted-foreground">Quantité totale</p>
          <p className="text-2xl font-heading font-bold">
            {totalQuantity}
          </p>
        </div>
        <div className="bg-card rounded-xl p-4 shadow-sm">
          <p className="text-sm text-muted-foreground">Montant total</p>
          <p className="text-2xl font-heading font-bold">
            {(totalAmount / 1000).toFixed(0)}K
          </p>
        </div>
        <div className="bg-card rounded-xl p-4 shadow-sm">
          <p className="text-sm text-muted-foreground">Taux de réussite</p>
          <p className="text-2xl font-heading font-bold text-success">
            {successRate}%
          </p>
        </div>
      </div>

      {/* Deliveries Table */}
      <div className="bg-card rounded-xl shadow-md overflow-hidden">
        {isLoading ? (
          <div className="flex items-center justify-center h-64">
            <div className="flex flex-col items-center gap-2">
              <Loader2 className="w-8 h-8 animate-spin text-primary" />
              <p className="text-sm text-muted-foreground">Chargement des livraisons...</p>
            </div>
          </div>
        ) : error ? (
          <div className="flex items-center justify-center h-64">
            <div className="text-center">
              <p className="text-destructive font-medium">Erreur lors du chargement</p>
              <p className="text-sm text-muted-foreground">{error instanceof Error ? error.message : 'Une erreur est survenue'}</p>
            </div>
          </div>
        ) : filteredDeliveries.length === 0 ? (
          <div className="flex items-center justify-center h-64">
            <p className="text-muted-foreground">Aucune livraison trouvée</p>
          </div>
        ) : (
          <>
            <div className="overflow-x-auto">
              <table className="data-table">
                <thead>
                  <tr>
                    <th>ID</th>
                    <th>Agent</th>
                    <th>Client</th>
                    <th>Adresse</th>
                    <th>Quantité</th>
                    <th>Montant</th>
                    <th>Date/Heure</th>
                    <th>Statut</th>
                    <th className="text-right">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredDeliveries.map((delivery, index) => (
                    <tr
                      key={delivery.id}
                      className="animate-fade-in"
                      style={{ animationDelay: `${index * 50}ms` }}
                    >
                      <td>
                        <span className="font-mono text-sm">{delivery.id}</span>
                      </td>
                      <td>
                        {delivery.agent ? (
                          <div className="flex items-center gap-2">
                            <Avatar className="w-8 h-8">
                              <AvatarImage src="" />
                              <AvatarFallback className="bg-primary/10 text-primary text-xs font-medium">
                                {delivery.agent.initials}
                              </AvatarFallback>
                            </Avatar>
                            <span className="text-sm">{delivery.agent.name}</span>
                          </div>
                        ) : (
                          <Button
                            variant="outline"
                            size="sm"
                            className="gap-1 text-info border-info/30 hover:bg-info/10"
                            onClick={() => handleOpenAssignModal(delivery)}
                          >
                            <UserPlus className="w-3 h-3" />
                            Assigner
                          </Button>
                        )}
                      </td>
                      <td>
                        <div>
                          <p className="font-medium text-sm">{delivery.client}</p>
                          <p className="text-xs text-muted-foreground">
                            {delivery.clientPhone}
                          </p>
                        </div>
                      </td>
                      <td>
                        <div className="flex items-center gap-1 text-sm text-muted-foreground max-w-[200px] truncate">
                          <MapPin className="w-3 h-3 flex-shrink-0" />
                          {delivery.address}
                        </div>
                      </td>
                      <td>
                        <span className="font-semibold">{delivery.quantity}</span>
                        <span className="text-muted-foreground text-sm"> sachets</span>
                      </td>
                      <td>
                        <span className="font-semibold">
                          {delivery.amount.toLocaleString()}
                        </span>
                        <span className="text-muted-foreground text-sm"> FCFA</span>
                      </td>
                      <td>
                        <div className="flex items-center gap-1 text-sm">
                          <Calendar className="w-3 h-3 text-muted-foreground" />
                          <span>{delivery.date}</span>
                          <span className="text-muted-foreground">
                            à {delivery.time}
                          </span>
                        </div>
                      </td>
                      <td>
                        <Badge
                          variant="outline"
                          className={
                            statusConfig[delivery.status]?.className ||
                            statusConfig['pending'].className
                          }
                        >
                          {
                            statusConfig[delivery.status]?.label ||
                            delivery.status
                          }
                        </Badge>
                      </td>
                      <td className="text-right">
                        <DropdownMenu>
                          <DropdownMenuTrigger asChild>
                            <Button variant="ghost" size="icon">
                              <MoreVertical className="w-4 h-4" />
                            </Button>
                          </DropdownMenuTrigger>
                          <DropdownMenuContent align="end" className="bg-card">
                            <DropdownMenuItem onClick={() => navigate(`/deliveries/${delivery.id}`)}>
                              <Eye className="w-4 h-4 mr-2" />
                              Voir détails
                            </DropdownMenuItem>
                            {!delivery.agent && (
                              <DropdownMenuItem onClick={() => handleOpenAssignModal(delivery)}>
                                <UserPlus className="w-4 h-4 mr-2" />
                                Assigner un livreur
                              </DropdownMenuItem>
                            )}
                            <DropdownMenuItem>
                              <MapPin className="w-4 h-4 mr-2" />
                              Voir sur la carte
                            </DropdownMenuItem>
                            <DropdownMenuItem>
                              <Download className="w-4 h-4 mr-2" />
                              Exporter
                            </DropdownMenuItem>
                          </DropdownMenuContent>
                        </DropdownMenu>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            {/* Pagination */}
            <div className="flex items-center justify-between p-4 border-t border-border">
              <p className="text-sm text-muted-foreground">
                Affichage de 1 à {filteredDeliveries.length} sur {deliveries.length} livraisons
              </p>
              <div className="flex gap-2">
                <Button variant="outline" size="sm" disabled>
                  Précédent
                </Button>
                <Button variant="outline" size="sm" disabled>
                  Suivant
                </Button>
              </div>
            </div>
          </>
        )}
      </div>

      <AssignAgentModal
        open={assignModalOpen}
        onOpenChange={setAssignModalOpen}
        delivery={selectedDelivery}
        onAssign={handleAssign}
      />
    </DashboardLayout>
  );
};

export default Deliveries;
