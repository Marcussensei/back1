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
  ShoppingBag,
} from "lucide-react";
import { useClients, useCreateClient, useDeleteClient } from "@/hooks/useApi";
import { CreateClientForm } from "@/components/clients/CreateClientForm";

const Clients = () => {
  const [searchTerm, setSearchTerm] = useState("");
  const [isCreateOpen, setIsCreateOpen] = useState(false);
  const { toast } = useToast();
  const navigate = useNavigate();

  const { data: clientsData, isLoading, isError, error, refetch } = useClients();
  const createClientMutation = useCreateClient();
  const deleteClientMutation = useDeleteClient();

  // Use data from API
  const clients = Array.isArray(clientsData) 
    ? clientsData 
    : clientsData?.clients || [];

  const filteredClients = clients.filter((client: any) =>
    client.nom?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    client.telephone?.includes(searchTerm) ||
    client.email?.includes(searchTerm) ||
    client.adresse?.includes(searchTerm)
  );

  const handleCreateClient = async (data: any) => {
    try {
      await createClientMutation.mutateAsync(data);
      toast({
        title: "Succès",
        description: "Client créé avec succès",
      });
      setIsCreateOpen(false);
      refetch();
    } catch (error: any) {
      const errorMsg = error?.message || "Impossible de créer le client";
      toast({
        title: "Erreur",
        description: errorMsg,
        variant: "destructive",
      });
    }
  };

  const handleDeleteClient = async (id: number) => {
    try {
      await deleteClientMutation.mutateAsync(id);
      toast({
        title: "Succès",
        description: "Client supprimé",
      });
      refetch();
    } catch (error) {
      toast({
        title: "Erreur",
        description: "Impossible de supprimer le client",
        variant: "destructive",
      });
    }
  };

  const getInitials = (name: string) => {
    if (!name) return "N/A";
    return name
      .split(" ")
      .map((n) => n[0])
      .join("")
      .toUpperCase()
      .slice(0, 2);
  };

  return (
    <DashboardLayout
      title="Clients"
      subtitle="Gérez votre base de clients"
    >
      {/* Header avec actions */}
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 mb-6">
        <div className="flex-1 w-full">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
            <Input
              placeholder="Rechercher par nom, téléphone, email ou adresse..."
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
                Nouveau client
              </Button>
            </DialogTrigger>
            <DialogContent className="max-w-md">
              <DialogHeader>
                <DialogTitle>Ajouter un nouveau client</DialogTitle>
                <DialogDescription>
                  Enregistrez un nouveau client dans votre base de données
                </DialogDescription>
              </DialogHeader>
              <CreateClientForm onSubmit={handleCreateClient} isLoading={createClientMutation.isPending} />
            </DialogContent>
          </Dialog>
        </div>
      </div>

      {/* Vue Carte - Clients en grille */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 mb-8">
        {isLoading ? (
          <div className="col-span-full text-center py-12 text-gray-500">
            Chargement...
          </div>
        ) : isError ? (
          <div className="col-span-full text-center py-12 bg-red-50 rounded-lg border border-red-200 p-6">
            <p className="text-red-800 font-semibold mb-2">Erreur de chargement</p>
            <p className="text-red-600 text-sm mb-4">{error?.message || "Impossible de récupérer les clients"}</p>
            <Button onClick={() => refetch()} variant="outline" size="sm">
              Réessayer
            </Button>
          </div>
        ) : filteredClients.length === 0 ? (
          <div className="col-span-full text-center py-12 text-gray-500">
            Aucun client trouvé
          </div>
        ) : (
          filteredClients.map((client: any) => (
            <div
              key={client.id}
              className="bg-white rounded-lg border border-gray-200 p-4 hover:shadow-lg transition-shadow"
            >
              <div className="flex items-start justify-between mb-3">
                <div className="flex items-center gap-3">
                  <Avatar className="w-10 h-10">
                    <AvatarFallback className="bg-blue-100 text-blue-800">
                      {getInitials(client.name)}
                    </AvatarFallback>
                  </Avatar>
                  <div>
                    <h3 className="font-semibold text-gray-900">{client.nom}</h3>
                    <p className="text-xs text-gray-500">Client #{client.id}</p>
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
                      onClick={() => navigate(`/clients/${client.id}`)}
                    >
                      <Eye className="w-4 h-4 mr-2" />
                      Voir détails
                    </DropdownMenuItem>
                    {/* <DropdownMenuItem>
                      <Edit className="w-4 h-4 mr-2" />
                      Modifier
                    </DropdownMenuItem> */}
                    <DropdownMenuItem
                      className="text-red-600"
                      onClick={() => handleDeleteClient(client.id)}
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
                  {client.phone}
                </div>
                {client.email && (
                  <div className="flex items-center gap-2 text-gray-600">
                    <Mail className="w-4 h-4" />
                    <span className="truncate">{client.email}</span>
                  </div>
                )}
                {client.address && (
                  <div className="flex items-start gap-2 text-gray-600">
                    <MapPin className="w-4 h-4 mt-0.5 flex-shrink-0" />
                    <span className="line-clamp-2">{client.address}</span>
                  </div>
                )}
              </div>

              <div className="mt-4 pt-4 border-t">
                <Badge className="bg-blue-50 text-blue-700 border-blue-200">
                  {client.type_client || "Particulier"}
                </Badge>
              </div>
            </div>
          ))
        )}
      </div>

      {/* Table détaillée */}
      <div className="bg-white rounded-lg border border-gray-200 overflow-hidden">
        <div className="p-4 border-b">
          <h3 className="font-semibold text-gray-900">Vue détaillée</h3>
        </div>
        <Table>
          <TableHeader>
            <TableRow className="bg-gray-50 border-b">
              <TableHead className="font-semibold">Client</TableHead>
              <TableHead className="font-semibold">Contact</TableHead>
              <TableHead className="font-semibold">Adresse</TableHead>
              <TableHead className="font-semibold">Type</TableHead>
              <TableHead className="text-right font-semibold">Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {filteredClients.length === 0 ? (
              <TableRow>
                <TableCell colSpan={5} className="text-center py-8 text-gray-500">
                  Aucun client
                </TableCell>
              </TableRow>
            ) : (
              filteredClients.map((client: any) => (
                <TableRow key={client.id} className="border-b hover:bg-gray-50">
                  <TableCell className="font-medium">{client.nom}</TableCell>
                  <TableCell>
                    <div className="text-sm">
                      <p>{client.telephone}</p>
                      <p className="text-gray-500 text-xs">{client.email}</p>
                    </div>
                  </TableCell>
                  <TableCell className="text-sm text-gray-600">{client.adresse || "-"}</TableCell>
                  <TableCell>
                    <Badge className="bg-blue-50 text-blue-700 border-blue-200">
                      {client.type_client || "Particulier"}
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
                          onClick={() => navigate(`/clients/${client.id}`)}
                        >
                          <Eye className="w-4 h-4 mr-2" />
                          Voir détails
                        </DropdownMenuItem>
                        <DropdownMenuItem>
                          <ShoppingBag className="w-4 h-4 mr-2" />
                          Commandes
                        </DropdownMenuItem>
                        <DropdownMenuItem>
                          <Edit className="w-4 h-4 mr-2" />
                          Modifier
                        </DropdownMenuItem>
                        <DropdownMenuItem
                          className="text-red-600"
                          onClick={() => handleDeleteClient(client.id)}
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
          <p className="text-sm text-blue-600">Total des clients</p>
          <p className="text-2xl font-bold text-blue-900">{clients.length}</p>
        </div>
        <div className="bg-gradient-to-br from-purple-50 to-purple-100 p-4 rounded-lg border border-purple-200">
          <p className="text-sm text-purple-600">Particuliers</p>
          <p className="text-2xl font-bold text-purple-900">
            {clients.filter((c: any) => c.type_client === "particulier").length}
          </p>
        </div>
        <div className="bg-gradient-to-br from-indigo-50 to-indigo-100 p-4 rounded-lg border border-indigo-200">
          <p className="text-sm text-indigo-600">Entreprises</p>
          <p className="text-2xl font-bold text-indigo-900">
            {clients.filter((c: any) => c.type_client === "entreprise").length}
          </p>
        </div>
      </div>
    </DashboardLayout>
  );
};

export default Clients;
