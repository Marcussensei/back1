import { useState } from "react";
import { DashboardLayout } from "@/components/layout/DashboardLayout";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Progress } from "@/components/ui/progress";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  Search,
  Plus,
  Filter,
  MoreVertical,
  Bike,
  Wrench,
  MapPin,
  Calendar,
  Fuel,
  Gauge,
  AlertTriangle,
  CheckCircle2,
  Settings,
  Activity,
} from "lucide-react";
import TricycleFormModal from "@/components/tricycles/TricycleFormModal";

const tricycles = [
  {
    id: "TRI-001",
    plate: "LM 2345 TG",
    agent: "Kofi Mensah",
    status: "active",
    fuel: 85,
    mileage: 12500,
    lastMaintenance: "2024-01-15",
    nextMaintenance: "2024-02-15",
    location: "Tokoin, Lomé",
    deliveriesToday: 18,
  },
  {
    id: "TRI-002",
    plate: "LM 6789 TG",
    agent: "Ama Kouassi",
    status: "active",
    fuel: 45,
    mileage: 8900,
    lastMaintenance: "2024-01-20",
    nextMaintenance: "2024-02-20",
    location: "Bè, Lomé",
    deliveriesToday: 22,
  },
  {
    id: "TRI-003",
    plate: "LM 1122 TG",
    agent: "",
    status: "maintenance",
    fuel: 0,
    mileage: 15200,
    lastMaintenance: "2024-01-25",
    nextMaintenance: "En cours",
    location: "Garage central",
    deliveriesToday: 0,
  },
  {
    id: "TRI-004",
    plate: "LM 3344 TG",
    agent: "Yao Agbeko",
    status: "active",
    fuel: 92,
    mileage: 6300,
    lastMaintenance: "2024-01-10",
    nextMaintenance: "2024-02-10",
    location: "Adidogomé",
    deliveriesToday: 15,
  },
  {
    id: "TRI-005",
    plate: "LM 5566 TG",
    agent: "",
    status: "available",
    fuel: 100,
    mileage: 3200,
    lastMaintenance: "2024-01-28",
    nextMaintenance: "2024-02-28",
    location: "Garage central",
    deliveriesToday: 0,
  },
  {
    id: "TRI-006",
    plate: "LM 7788 TG",
    agent: "Akouvi Dosseh",
    status: "warning",
    fuel: 20,
    mileage: 18900,
    lastMaintenance: "2023-12-15",
    nextMaintenance: "2024-01-15",
    location: "Agoè",
    deliveriesToday: 12,
  },
];

const statusConfig = {
  active: { label: "En service", variant: "default" as const, color: "bg-success" },
  available: { label: "Disponible", variant: "secondary" as const, color: "bg-primary" },
  maintenance: { label: "Maintenance", variant: "outline" as const, color: "bg-warning" },
  warning: { label: "Attention", variant: "destructive" as const, color: "bg-destructive" },
};

const Tricycles = () => {
  const [searchTerm, setSearchTerm] = useState("");
  const [modalOpen, setModalOpen] = useState(false);
  const [modalMode, setModalMode] = useState<"create" | "edit">("create");
  const [selectedTricycle, setSelectedTricycle] = useState<any>(null);

  const filteredTricycles = tricycles.filter(
    (t) =>
      t.id.toLowerCase().includes(searchTerm.toLowerCase()) ||
      t.plate.toLowerCase().includes(searchTerm.toLowerCase()) ||
      t.agent?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const stats = {
    total: tricycles.length,
    active: tricycles.filter((t) => t.status === "active").length,
    available: tricycles.filter((t) => t.status === "available").length,
    maintenance: tricycles.filter((t) => t.status === "maintenance").length,
  };

  const handleCreate = () => {
    setSelectedTricycle(null);
    setModalMode("create");
    setModalOpen(true);
  };

  const handleEdit = (tricycle: any) => {
    setSelectedTricycle(tricycle);
    setModalMode("edit");
    setModalOpen(true);
  };

  return (
    <DashboardLayout title="Flotte de Tricycles" subtitle="Gestion et suivi des véhicules">
      {/* Stats Overview */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4 mb-6">
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-4">
              <div className="w-12 h-12 bg-primary/10 rounded-xl flex items-center justify-center">
                <Bike className="w-6 h-6 text-primary" />
              </div>
              <div>
                <p className="text-2xl font-bold">{stats.total}</p>
                <p className="text-sm text-muted-foreground">Total tricycles</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-4">
              <div className="w-12 h-12 bg-success/10 rounded-xl flex items-center justify-center">
                <Activity className="w-6 h-6 text-success" />
              </div>
              <div>
                <p className="text-2xl font-bold">{stats.active}</p>
                <p className="text-sm text-muted-foreground">En service</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-4">
              <div className="w-12 h-12 bg-accent/10 rounded-xl flex items-center justify-center">
                <CheckCircle2 className="w-6 h-6 text-accent" />
              </div>
              <div>
                <p className="text-2xl font-bold">{stats.available}</p>
                <p className="text-sm text-muted-foreground">Disponibles</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-4">
              <div className="w-12 h-12 bg-warning/10 rounded-xl flex items-center justify-center">
                <Wrench className="w-6 h-6 text-warning" />
              </div>
              <div>
                <p className="text-2xl font-bold">{stats.maintenance}</p>
                <p className="text-sm text-muted-foreground">En maintenance</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Search and Actions */}
      <div className="flex flex-col sm:flex-row gap-4 mb-6">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
          <Input
            placeholder="Rechercher par ID, plaque ou agent..."
            className="pl-10"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>
        <Button variant="outline" className="gap-2">
          <Filter className="w-4 h-4" />
          Filtrer
        </Button>
        <Button className="gradient-primary gap-2" onClick={handleCreate}>
          <Plus className="w-4 h-4" />
          Nouveau Tricycle
        </Button>
      </div>

      {/* Tricycles Grid */}
      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
        {filteredTricycles.map((tricycle) => {
          const status = statusConfig[tricycle.status];

          return (
            <Card key={tricycle.id} className="overflow-hidden hover:shadow-lg transition-shadow">
              <CardHeader className="pb-3">
                <div className="flex items-start justify-between">
                  <div className="flex items-center gap-3">
                    <div
                      className={`w-12 h-12 rounded-xl flex items-center justify-center ${
                        tricycle.status === "active"
                          ? "bg-success/10"
                          : tricycle.status === "maintenance"
                          ? "bg-warning/10"
                          : tricycle.status === "warning"
                          ? "bg-destructive/10"
                          : "bg-primary/10"
                      }`}
                    >
                      <Bike
                        className={`w-6 h-6 ${
                          tricycle.status === "active"
                            ? "text-success"
                            : tricycle.status === "maintenance"
                            ? "text-warning"
                            : tricycle.status === "warning"
                            ? "text-destructive"
                            : "text-primary"
                        }`}
                      />
                    </div>
                    <div>
                      <CardTitle className="text-base">{tricycle.id}</CardTitle>
                      <p className="text-sm text-muted-foreground font-mono">
                        {tricycle.plate}
                      </p>
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    <Badge variant={status.variant}>{status.label}</Badge>
                    <DropdownMenu>
                      <DropdownMenuTrigger asChild>
                        <Button variant="ghost" size="icon" className="h-8 w-8">
                          <MoreVertical className="w-4 h-4" />
                        </Button>
                      </DropdownMenuTrigger>
                      <DropdownMenuContent align="end">
                        <DropdownMenuItem onClick={() => handleEdit(tricycle)}>
                          <Settings className="w-4 h-4 mr-2" />
                          Modifier
                        </DropdownMenuItem>
                        <DropdownMenuItem>
                          <Wrench className="w-4 h-4 mr-2" />
                          Planifier maintenance
                        </DropdownMenuItem>
                        <DropdownMenuItem>
                          <MapPin className="w-4 h-4 mr-2" />
                          Localiser
                        </DropdownMenuItem>
                      </DropdownMenuContent>
                    </DropdownMenu>
                  </div>
                </div>
              </CardHeader>

              <CardContent className="space-y-4">
                {/* Agent assignment */}
                <div className="flex items-center justify-between p-3 bg-muted/50 rounded-lg">
                  <span className="text-sm text-muted-foreground">Agent assigné</span>
                  <span className="text-sm font-medium">
                    {tricycle.agent || "Non assigné"}
                  </span>
                </div>

                {/* Fuel level */}
                <div className="space-y-2">
                  <div className="flex items-center justify-between text-sm">
                    <span className="flex items-center gap-2 text-muted-foreground">
                      <Fuel className="w-4 h-4" />
                      Carburant
                    </span>
                    <span
                      className={`font-medium ${
                        tricycle.fuel < 25
                          ? "text-destructive"
                          : tricycle.fuel < 50
                          ? "text-warning"
                          : "text-success"
                      }`}
                    >
                      {tricycle.fuel}%
                    </span>
                  </div>
                  <Progress
                    value={tricycle.fuel}
                    className={`h-2 ${
                      tricycle.fuel < 25
                        ? "[&>div]:bg-destructive"
                        : tricycle.fuel < 50
                        ? "[&>div]:bg-warning"
                        : "[&>div]:bg-success"
                    }`}
                  />
                </div>

                {/* Stats row */}
                <div className="grid grid-cols-2 gap-3">
                  <div className="flex items-center gap-2 text-sm">
                    <Gauge className="w-4 h-4 text-muted-foreground" />
                    <span className="text-muted-foreground">Kilométrage:</span>
                    <span className="font-medium">{tricycle.mileage.toLocaleString()} km</span>
                  </div>
                  <div className="flex items-center gap-2 text-sm">
                    <Activity className="w-4 h-4 text-muted-foreground" />
                    <span className="text-muted-foreground">Aujourd'hui:</span>
                    <span className="font-medium">{tricycle.deliveriesToday} livraisons</span>
                  </div>
                </div>

                {/* Location */}
                <div className="flex items-center gap-2 text-sm">
                  <MapPin className="w-4 h-4 text-primary" />
                  <span>{tricycle.location}</span>
                </div>

                {/* Maintenance info */}
                <div className="flex items-center justify-between pt-3 border-t">
                  <div className="flex items-center gap-2 text-sm text-muted-foreground">
                    <Calendar className="w-4 h-4" />
                    <span>Prochaine maintenance</span>
                  </div>
                  <span
                    className={`text-sm font-medium ${
                      tricycle.status === "warning" ? "text-destructive" : ""
                    }`}
                  >
                    {tricycle.nextMaintenance}
                    {tricycle.status === "warning" && (
                      <AlertTriangle className="w-4 h-4 inline ml-1" />
                    )}
                  </span>
                </div>
              </CardContent>
            </Card>
          );
        })}
      </div>

      {filteredTricycles.length === 0 && (
        <div className="text-center py-12">
          <Bike className="w-12 h-12 mx-auto text-muted-foreground mb-4" />
          <p className="text-muted-foreground">Aucun tricycle trouvé</p>
        </div>
      )}

      <TricycleFormModal
        open={modalOpen}
        onOpenChange={setModalOpen}
        tricycle={selectedTricycle}
        mode={modalMode}
      />
    </DashboardLayout>
  );
};

export default Tricycles;
