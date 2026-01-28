import { useEffect, useState } from "react";
import { DashboardLayout } from "@/components/layout/DashboardLayout";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import {
  AreaChart,
  Area,
  BarChart,
  Bar,
  PieChart,
  Pie,
  Cell,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Legend,
} from "recharts";
import {
  Download,
  TrendingUp,
  Users,
  Package,
  Wallet,
  RefreshCw,
} from "lucide-react";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { useToast } from "@/hooks/use-toast";

const Reports = () => {
  const [startDate, setStartDate] = useState("");
  const [endDate, setEndDate] = useState("");
  const [loading, setLoading] = useState(true);
  const [kpiData, setKpiData] = useState<any>(null);
  const [monthlyData, setMonthlyData] = useState<any[]>([]);
  const [agentPerformance, setAgentPerformance] = useState<any[]>([]);
  const [statusStats, setStatusStats] = useState<any[]>([]);
  const [exportLoading, setExportLoading] = useState(false);
  const { toast } = useToast();

  const fetchReportData = async () => {
    setLoading(true);
    try {
      // Fetch KPI
      const kpiRes = await fetch(
        `https://essivivi-project.onrender.com/rapports/resume${
          startDate && endDate ? `?start_date=${startDate}&end_date=${endDate}` : ""
        }`,
        {
          headers: { accept: "application/json" },
          credentials: "include",
        }
      );

      if (kpiRes.ok) {
        const kpiResult = await kpiRes.json();
        setKpiData(kpiResult);
      }

      // Fetch monthly trends
      const monthlyRes = await fetch("https://essivivi-project.onrender.com/rapports/tendances-mensuelles", {
        headers: { accept: "application/json" },
        credentials: "include",
      });

      if (monthlyRes.ok) {
        const monthlyResult = await monthlyRes.json();
        setMonthlyData(monthlyResult);
      }

      // Fetch agent performance
      const agentRes = await fetch(
        `https://essivivi-project.onrender.com/rapports/performance-agents${
          startDate && endDate ? `?start_date=${startDate}&end_date=${endDate}` : ""
        }`,
        {
          headers: { accept: "application/json" },
          credentials: "include",
        }
      );

      if (agentRes.ok) {
        const agentResult = await agentRes.json();
        setAgentPerformance(agentResult);
      }

      // Fetch status statistics
      const statusRes = await fetch(
        `https://essivivi-project.onrender.com/rapports/statistiques-par-statut${
          startDate && endDate ? `?start_date=${startDate}&end_date=${endDate}` : ""
        }`,
        {
          headers: { accept: "application/json" },
          credentials: "include",
        }
      );

      if (statusRes.ok) {
        const statusResult = await statusRes.json();
        setStatusStats(statusResult);
      }

      setLoading(false);
    } catch (error) {
      console.error("Error fetching reports:", error);
      toast({
        title: "Erreur",
        description: "Impossible de récupérer les données de rapports",
        variant: "destructive",
      });
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchReportData();
  }, []);

  const handleExport = async (format: "csv" | "xlsx") => {
    setExportLoading(true);
    try {
      const type = "livraisons";
      let url = `https://essivivi-project.onrender.com/rapports/export/${format}?type=${type}`;

      if (startDate && endDate) {
        url += `&start_date=${startDate}&end_date=${endDate}`;
      }

      const response = await fetch(url, {
        headers: { accept: "application/json" },
        credentials: "include",
      });

      if (response.ok) {
        const blob = await response.blob();
        const downloadUrl = window.URL.createObjectURL(blob);
        const a = document.createElement("a");
        a.href = downloadUrl;
        const ext = format === "xlsx" ? "xlsx" : "csv";
        a.download = `rapport_${type}_${new Date().toISOString().split("T")[0]}.${ext}`;
        document.body.appendChild(a);
        a.click();
        window.URL.revokeObjectURL(downloadUrl);
        document.body.removeChild(a);

        toast({
          title: "Succès",
          description: `Rapport exporté en ${format.toUpperCase()}`,
        });
      }
    } catch (error) {
      console.error("Export error:", error);
      toast({
        title: "Erreur",
        description: `Impossible d'exporter en ${format.toUpperCase()}`,
        variant: "destructive",
      });
    } finally {
      setExportLoading(false);
    }
  };

  const today = new Date().toISOString().split("T")[0];
  const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)
    .toISOString()
    .split("T")[0];

  if (loading) {
    return (
      <DashboardLayout
        title="Rapports"
        subtitle="Analyses et statistiques de performance"
      >
        <div className="flex items-center justify-center h-96">
          <RefreshCw className="w-8 h-8 animate-spin text-primary" />
        </div>
      </DashboardLayout>
    );
  }

  return (
    <DashboardLayout
      title="Rapports"
      subtitle="Analyses et statistiques de performance"
    >
      {/* Controls */}
      <div className="flex flex-wrap gap-4 justify-between mb-8">
        <div className="flex gap-3">
          <div>
            <label className="text-sm text-muted-foreground block mb-2">
              Date début
            </label>
            <input
              type="date"
              value={startDate || thirtyDaysAgo}
              onChange={(e) => setStartDate(e.target.value)}
              className="px-3 py-2 border border-border rounded-lg bg-card"
            />
          </div>
          <div>
            <label className="text-sm text-muted-foreground block mb-2">
              Date fin
            </label>
            <input
              type="date"
              value={endDate || today}
              onChange={(e) => setEndDate(e.target.value)}
              className="px-3 py-2 border border-border rounded-lg bg-card"
            />
          </div>
          <div className="flex items-end">
            <Button onClick={() => fetchReportData()} className="gap-2">
              <RefreshCw className="w-4 h-4" />
              Rafraîchir
            </Button>
          </div>
        </div>
        <div className="flex gap-2">
          <Button
            variant="outline"
            className="gap-2"
            onClick={() => handleExport("csv")}
            disabled={exportLoading}
          >
            <Download className="w-4 h-4" />
            CSV
          </Button>
          <Button
            className="gradient-primary gap-2"
            onClick={() => handleExport("xlsx")}
            disabled={exportLoading}
          >
            <Download className="w-4 h-4" />
            {exportLoading ? "Export..." : "Excel"}
          </Button>
        </div>
      </div>

      {/* KPI Summary */}
      {kpiData && (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
          <Card className="p-6">
            <div className="flex items-center gap-3 mb-3">
              <div className="w-10 h-10 rounded-lg bg-primary/10 flex items-center justify-center">
                <Package className="w-5 h-5 text-primary" />
              </div>
              <span className="text-sm text-muted-foreground">Total livraisons</span>
            </div>
            <p className="text-3xl font-heading font-bold">
              {kpiData.total_livraisons}
            </p>
            <p className="text-xs text-muted-foreground mt-1">
              {kpiData.livraisons_terminees} terminées
            </p>
          </Card>

          <Card className="p-6">
            <div className="flex items-center gap-3 mb-3">
              <div className="w-10 h-10 rounded-lg bg-success/10 flex items-center justify-center">
                <TrendingUp className="w-5 h-5 text-success" />
              </div>
              <span className="text-sm text-muted-foreground">Taux de réussite</span>
            </div>
            <p className="text-3xl font-heading font-bold">
              {kpiData.taux_reussite}%
            </p>
            <p className="text-xs text-muted-foreground mt-1">
              Des livraisons complétées
            </p>
          </Card>

          <Card className="p-6">
            <div className="flex items-center gap-3 mb-3">
              <div className="w-10 h-10 rounded-lg bg-warning/10 flex items-center justify-center">
                <Wallet className="w-5 h-5 text-warning" />
              </div>
              <span className="text-sm text-muted-foreground">Montant collecté</span>
            </div>
            <p className="text-3xl font-heading font-bold">
              {(kpiData.montant_collecte ).toFixed(1)}
            </p>
            <p className="text-xs text-muted-foreground mt-1">FCFA</p>
          </Card>

          <Card className="p-6">
            <div className="flex items-center gap-3 mb-3">
              <div className="w-10 h-10 rounded-lg bg-accent/10 flex items-center justify-center">
                <Users className="w-5 h-5 text-accent" />
              </div>
              <span className="text-sm text-muted-foreground">Agents actifs</span>
            </div>
            <p className="text-3xl font-heading font-bold">
              {kpiData.nombre_agents}
            </p>
            <p className="text-xs text-muted-foreground mt-1">
              {kpiData.nombre_clients} clients
            </p>
          </Card>
        </div>
      )}

      {/* Charts Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
        {/* Monthly Evolution */}
        {monthlyData.length > 0 && (
          <Card className="p-6 lg:col-span-2">
            <h3 className="text-lg font-heading font-semibold mb-6">
              Évolution mensuelle des livraisons
            </h3>
            <ResponsiveContainer width="100%" height={300}>
              <AreaChart data={monthlyData}>
                <defs>
                  <linearGradient id="colorLivraisons" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.3} />
                    <stop offset="95%" stopColor="#3b82f6" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                <XAxis dataKey="month" stroke="#9ca3af" />
                <YAxis stroke="#9ca3af" />
                <Tooltip
                  contentStyle={{
                    backgroundColor: "#1f2937",
                    border: "1px solid #374151",
                    borderRadius: "8px",
                  }}
                  formatter={(value) => [value, "Livraisons"]}
                />
                <Area
                  type="monotone"
                  dataKey="livraisons"
                  stroke="#3b82f6"
                  fillOpacity={1}
                  fill="url(#colorLivraisons)"
                />
              </AreaChart>
            </ResponsiveContainer>
          </Card>
        )}

        {/* Status Distribution */}
        {statusStats.length > 0 && (
          <Card className="p-6">
            <h3 className="text-lg font-heading font-semibold mb-6">
              Distribution par statut
            </h3>
            <ResponsiveContainer width="100%" height={300}>
              <PieChart>
                <Pie
                  data={statusStats}
                  cx="50%"
                  cy="50%"
                  labelLine={false}
                  label={({ statut, nombre }) => `${statut}: ${nombre}`}
                  outerRadius={80}
                  fill="#8884d8"
                  dataKey="nombre"
                >
                  {statusStats.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
                  ))}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          </Card>
        )}

        {/* Monthly Revenue */}
        {monthlyData.length > 0 && (
          <Card className="p-6">
            <h3 className="text-lg font-heading font-semibold mb-6">
              Revenus mensuels
            </h3>
            <ResponsiveContainer width="100%" height={300}>
              <BarChart data={monthlyData}>
                <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                <XAxis dataKey="month" stroke="#9ca3af" />
                <YAxis stroke="#9ca3af" />
                <Tooltip
                  contentStyle={{
                    backgroundColor: "#1f2937",
                    border: "1px solid #374151",
                    borderRadius: "8px",
                  }}
                  formatter={(value: any) => [(Number(value) / 1000000).toFixed(1) + "FCFA"]}
                />
                <Bar dataKey="montant" fill="#10b981" radius={[8, 8, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </Card>
        )}
      </div>

      {/* Agent Performance Table */}
      {agentPerformance.length > 0 && (
        <Card className="p-6 mb-8">
          <h3 className="text-lg font-heading font-semibold mb-6">
            Performance des agents
          </h3>
          <div className="overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow className="border-b border-border hover:bg-transparent">
                  <TableHead>Agent</TableHead>
                  <TableHead>Téléphone</TableHead>
                  <TableHead>Total</TableHead>
                  <TableHead>Complétées</TableHead>
                  <TableHead>En cours</TableHead>
                  <TableHead>Montant</TableHead>
                  <TableHead>Collecté</TableHead>
                  <TableHead>Taux</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {agentPerformance.map((agent) => (
                  <TableRow key={agent.id} className="border-b border-border hover:bg-muted/50">
                    <TableCell className="font-medium">{agent.nom}</TableCell>
                    <TableCell className="text-sm text-muted-foreground">
                      {agent.telephone}
                    </TableCell>
                    <TableCell>{agent.total_livraisons}</TableCell>
                    <TableCell className="text-success">
                      {agent.livraisons_completees}
                    </TableCell>
                    <TableCell className="text-info">
                      {agent.livraisons_en_cours}
                    </TableCell>
                    <TableCell>
                      {(agent.montant_total / 1000).toFixed(2)}CFA
                    </TableCell>
                    <TableCell className="text-success">
                      {(agent.montant_collecte / 1000).toFixed(2)}CFA
                    </TableCell>
                    <TableCell>
                      <span className="px-2 py-1 rounded-full bg-success/10 text-success text-sm font-medium">
                        {agent.taux_completion}%
                      </span>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        </Card>
      )}
    </DashboardLayout>
  );
};

export default Reports;
