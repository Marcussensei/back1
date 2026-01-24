//Agents.tsx

import { useState } from "react";
import { DashboardLayout } from "@/components/layout/DashboardLayout";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
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
  Eye,
  Edit,
  Trash2,
  MapPin,
  Phone,
  Mail,
  RefreshCw,
  Activity,
} from "lucide-react";
import { useAgents, useCreateAgent, useUpdateAgent, useDeleteAgent } from "@/hooks/useApi";
import { CreateAgentForm } from "@/components/agents/CreateAgentForm";

const Agents = () => {
  const [searchTerm, setSearchTerm] = useState("");
  const [isCreateOpen, setIsCreateOpen] = useState(false);
  const [isEditOpen, setIsEditOpen] = useState(false);
  const [editingAgent, setEditingAgent] = useState<any>(null);
  const { toast } = useToast();
  const navigate = useNavigate();

  const { data: agentsData, isLoading, isError, error, refetch } = useAgents();
  const createAgentMutation = useCreateAgent();
  const updateAgentMutation = useUpdateAgent();
  const deleteAgentMutation = useDeleteAgent();

  // Use data from API
  const agents = Array.isArray(agentsData) 
    ? agentsData
    : agentsData?.agents || [];

  const filteredAgents = agents.filter((agent: any) =>
    agent.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    agent.phone?.includes(searchTerm) ||
    agent.email?.includes(searchTerm)
  );

  const statusConfig = {
    active: { label: "Actif", color: "bg-green-100 text-green-800", dot: "bg-green-500" },
    inactive: { label: "Inactif", color: "bg-gray-100 text-gray-800", dot: "bg-gray-500" },
    on_leave: { label: "En congé", color: "bg-orange-100 text-orange-800", dot: "bg-orange-500" },
  };

  const handleCreateAgent = async (data: any) => {
    try {
      await createAgentMutation.mutateAsync(data);
      toast({
        title: "Succès",
        description: "Agent créé avec succès",
      });
      setIsCreateOpen(false);
      refetch();
    } catch (error: any) {
      const errorMsg = error?.message || "Impossible de créer l'agent";
      toast({
        title: "Erreur",
        description: errorMsg,
        variant: "destructive",
      });
    }
  };

  const handleEditAgent = async (data: any) => {
    try {
      await updateAgentMutation.mutateAsync({ id: editingAgent?.id, data });
      toast({
        title: "Succès",
        description: "Agent mis à jour avec succès",
      });
      setIsEditOpen(false);
      setEditingAgent(null);
      refetch();
    } catch (error) {
      toast({
        title: "Erreur",
        description: "Impossible de mettre à jour l'agent",
        variant: "destructive",
      });
    }
  };

  const handleDeleteAgent = async (id: number) => {
    try {
      await deleteAgentMutation.mutateAsync(id);
      toast({
        title: "Succès",
        description: "Agent supprimé",
      });
      refetch();
    } catch (error) {
      toast({
        title: "Erreur",
        description: "Impossible de supprimer l'agent",
        variant: "destructive",
      });
    }
  };

  const getInitials = (name: string) => {
    return name
      .split(" ")
      .map((n) => n[0])
      .join("")
      .toUpperCase()
      .slice(0, 2);
  };

  return (
    <DashboardLayout
      title="Agents de Livraison"
      subtitle="Gérez les équipes de livraison"
    >
      {/* Header avec actions */}
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 mb-6">
        <div className="flex-1 w-full">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
            <Input
              placeholder="Rechercher par nom, téléphone ou email..."
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
                Nouvel agent
              </Button>
            </DialogTrigger>
            <DialogContent className="max-w-md">
              <DialogHeader>
                <DialogTitle>Créer un nouvel agent</DialogTitle>
                <DialogDescription>
                  Ajoutez un nouveau membre à votre équipe de livraison
                </DialogDescription>
              </DialogHeader>
              <CreateAgentForm onSubmit={handleCreateAgent} isLoading={createAgentMutation.isPending} />
            </DialogContent>
          </Dialog>
        </div>
      </div>

      {/* Edit Dialog */}
      <Dialog open={isEditOpen} onOpenChange={setIsEditOpen}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle>Modifier l'agent</DialogTitle>
            <DialogDescription>
              Modifiez les informations de l'agent
            </DialogDescription>
          </DialogHeader>
          <CreateAgentForm
            onSubmit={handleEditAgent}
            isLoading={updateAgentMutation.isPending}
            initialData={editingAgent}
            isEdit={true}
          />
        </DialogContent>
      </Dialog>

      {/* Vue Carte - Agents en grille */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 mb-8">
        {isLoading ? (
          <div className="col-span-full text-center py-12 text-gray-500">
            Chargement...
          </div>
        ) : isError ? (
          <div className="col-span-full text-center py-12 bg-red-50 rounded-lg border border-red-200 p-6">
            <p className="text-red-800 font-semibold mb-2">Erreur de chargement</p>
            <p className="text-red-600 text-sm mb-4">{error?.message || "Impossible de récupérer les agents"}</p>
            <Button onClick={() => refetch()} variant="outline" size="sm">
              Réessayer
            </Button>
          </div>
        ) : filteredAgents.length === 0 ? (
          <div className="col-span-full text-center py-12 text-gray-500">
            Aucun agent trouvé
          </div>
        ) : (
          filteredAgents.map((agent: any) => (
            <div
              key={agent.id}
              className="bg-white rounded-lg border border-gray-200 p-4 hover:shadow-lg transition-shadow"
            >
              <div className="flex items-start justify-between mb-3">
                <div className="flex items-center gap-3">
                  <Avatar className="w-10 h-10">
                    <AvatarFallback className="bg-primary text-white">
                      {getInitials(agent.name)}
                    </AvatarFallback>
                  </Avatar>
                  <div>
                    <h3 className="font-semibold text-gray-900">{agent.name}</h3>
                    <Badge
                      className={statusConfig[agent.status as keyof typeof statusConfig]?.color || ""}
                    >
                      {statusConfig[agent.status as keyof typeof statusConfig]?.label || agent.status}
                    </Badge>
                  </div>
                </div>
                <DropdownMenu>
                  <DropdownMenuTrigger asChild>
                    <Button variant="ghost" size="sm">
                      <MoreVertical className="w-4 h-4" />
                    </Button>
                  </DropdownMenuTrigger>
                  <DropdownMenuContent align="end">
                    <DropdownMenuItem
                      onClick={() => navigate(`/agents/${agent.id}`)}
                    >
                      <Eye className="w-4 h-4 mr-2" />
                      Voir détails
                    </DropdownMenuItem>
                    <DropdownMenuItem
                      onClick={() => {
                        setEditingAgent(agent);
                        setIsEditOpen(true);
                      }}
                    >
                      <Edit className="w-4 h-4 mr-2" />
                      Modifier
                    </DropdownMenuItem>
                    <DropdownMenuItem
                      className="text-red-600"
                      onClick={() => handleDeleteAgent(agent.id)}
                    >
                      <Trash2 className="w-4 h-4 mr-2" />
                      Supprimer
                    </DropdownMenuItem>
                  </DropdownMenuContent>
                </DropdownMenu>
              </div>

              <div className="space-y-2 text-sm">
                <div className="flex items-center gap-2 text-gray-600">
                  <Phone className="w-4 h-4" />
                  {agent.phone}
                </div>
                {agent.email && (
                  <div className="flex items-center gap-2 text-gray-600">
                    <Mail className="w-4 h-4" />
                    {agent.email}
                  </div>
                )}
                {agent.zone_livraison && (
                  <div className="flex items-center gap-2 text-gray-600">
                    <MapPin className="w-4 h-4" />
                    {agent.zone_livraison}
                  </div>
                )}
              </div>

              <div className="mt-4 pt-4 border-t flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <div className={`w-2 h-2 rounded-full ${statusConfig[agent.status as keyof typeof statusConfig]?.dot}`}></div>
                  <span className="text-xs text-gray-600">
                    {agent.status === "active" ? "En ligne" : "Hors ligne"}
                  </span>
                </div>
                <Button variant="outline" size="sm">
                  <Activity className="w-3 h-3 mr-1" />
                  Voir activité
                </Button>
              </div>
            </div>
          ))
        )}
      </div>

      {/* Table de statistiques */}
      <div className="bg-white rounded-lg border border-gray-200 overflow-hidden">
        <div className="p-4 border-b">
          <h3 className="font-semibold text-gray-900">Vue détaillée</h3>
        </div>
        <Table>
          <TableHeader>
            <TableRow className="bg-gray-50 border-b">
              <TableHead className="font-semibold">Agent</TableHead>
              <TableHead className="font-semibold">Contact</TableHead>
              <TableHead className="font-semibold">Zone</TableHead>
              <TableHead className="font-semibold">Statut</TableHead>
              <TableHead className="text-right font-semibold">Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {filteredAgents.length === 0 ? (
              <TableRow>
                <TableCell colSpan={5} className="text-center py-8 text-gray-500">
                  Aucun agent
                </TableCell>
              </TableRow>
            ) : (
              filteredAgents.map((agent: any) => (
                <TableRow key={agent.id} className="border-b hover:bg-gray-50">
                  <TableCell className="font-medium">{agent.name}</TableCell>
                  <TableCell>
                    <div className="text-sm">
                      <p>{agent.phone}</p>
                      <p className="text-gray-500 text-xs">{agent.email}</p>
                    </div>
                  </TableCell>
                  <TableCell>{agent.zone_livraison || "-"}</TableCell>
                  <TableCell>
                    <Badge
                      className={statusConfig[agent.status as keyof typeof statusConfig]?.color || ""}
                    >
                      {statusConfig[agent.status as keyof typeof statusConfig]?.label || agent.status}
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
                          onClick={() => navigate(`/agents/${agent.id}`)}
                        >
                          <Eye className="w-4 h-4 mr-2" />
                          Voir détails
                        </DropdownMenuItem>
                        <DropdownMenuItem
                          onClick={() => {
                            setEditingAgent(agent);
                            setIsEditOpen(true);
                          }}
                        >
                          <Edit className="w-4 h-4 mr-2" />
                          Modifier
                        </DropdownMenuItem>
                        <DropdownMenuItem
                          className="text-red-600"
                          onClick={() => handleDeleteAgent(agent.id)}
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
      <div className="mt-6 grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-gradient-to-br from-blue-50 to-blue-100 p-4 rounded-lg border border-blue-200">
          <p className="text-sm text-blue-600">Total des agents</p>
          <p className="text-2xl font-bold text-blue-900">{filteredAgents.length}</p>
        </div>
        <div className="bg-gradient-to-br from-green-50 to-green-100 p-4 rounded-lg border border-green-200">
          <p className="text-sm text-green-600">Actifs</p>
          <p className="text-2xl font-bold text-green-900">
            {filteredAgents.filter((a: any) => a.status === "active").length}
          </p>
        </div>
        <div className="bg-gradient-to-br from-orange-50 to-orange-100 p-4 rounded-lg border border-orange-200">
          <p className="text-sm text-orange-600">En congé</p>
          <p className="text-2xl font-bold text-orange-900">
            {filteredAgents.filter((a: any) => a.status === "on_leave").length}
          </p>
        </div>
      </div>
    </DashboardLayout>
  );
};

export default Agents;
