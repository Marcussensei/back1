import { useEffect, useState } from "react";
import { DashboardLayout } from "@/components/layout/DashboardLayout";
import { StatCard } from "@/components/dashboard/StatCard";
import { RecentDeliveries } from "@/components/dashboard/RecentDeliveries";
import { DeliveryChart } from "@/components/dashboard/DeliveryChart";
import { ActiveAgents } from "@/components/dashboard/ActiveAgents";
import { QuickActions } from "@/components/dashboard/QuickActions";
import { Truck, Users, Package, Wallet } from "lucide-react";
import { useToast } from "@/hooks/use-toast";

const Index = () => {
  const [stats, setStats] = useState<any>(null);
  const [topAgents, setTopAgents] = useState<any[]>([]);
  const [recentDeliveries, setRecentDeliveries] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const { toast } = useToast();

  useEffect(() => {
    const fetchDashboardData = async () => {
      try {
        const response = await fetch("https://essivivi-project.onrender.com/rapports/dashboard", {
          headers: { accept: "application/json" },
          credentials: "include",
        });

        if (response.ok) {
          const data = await response.json();
          setStats(data.stats);
          setTopAgents(data.top_agents);
          setRecentDeliveries(data.recent_deliveries);
        }
        setLoading(false);
      } catch (error) {
        console.error("Error fetching dashboard data:", error);
        toast({
          title: "Erreur",
          description: "Impossible de récupérer les données du dashboard",
          variant: "destructive",
        });
        setLoading(false);
      }
    };

    fetchDashboardData();
    // Refresh every 30 seconds
    const interval = setInterval(fetchDashboardData, 30000);
    return () => clearInterval(interval);
  }, [toast]);

  return (
    <DashboardLayout
      title="Tableau de bord"
      subtitle="Bienvenue ! Voici un aperçu de votre activité aujourd'hui."
    >
      {/* Quick Actions */}
      <section className="mb-8">
        <QuickActions />
      </section>

      {/* Stats Grid */}
      <section className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <StatCard
          title="Livraisons aujourd'hui"
          value={stats?.livraisons_today || "0"}
          icon={<Truck className="w-6 h-6 text-primary-foreground" />}
          trend={{ value: stats?.livraisons_completed || 0, isPositive: true }}
          variant="primary"
        />
        <StatCard
          title="Agents actifs"
          value={stats?.agents_active || "0"}
          icon={<Users className="w-6 h-6 text-secondary-foreground" />}
          trend={{ value: stats?.livraisons_in_progress || 0, isPositive: true }}
          variant="secondary"
        />
        <StatCard
          title="Quantité livrée"
          value={(stats?.quantity_delivered || 0).toLocaleString()}
          icon={<Package className="w-6 h-6 text-accent-foreground" />}
          trend={{ value: 0, isPositive: true }}
          variant="accent"
        />
        <StatCard
          title="Recettes du jour"
          value={(stats?.revenue_today || 0).toFixed(0) + " FCFA"}
          icon={<Wallet className="w-6 h-6 text-success-foreground" />}
          trend={{ value: stats?.livraisons_completed || 0, isPositive: true }}
          variant="success"
        />
      </section>

      {/* Main Content Grid */}
      <section className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-8">
        {/* Chart - 2 columns */}
        <div className="lg:col-span-2">
          <DeliveryChart />
        </div>

        {/* Active Agents - 1 column */}
        <div className="lg:col-span-1">
          <ActiveAgents agents={topAgents || []} />
        </div>
      </section>

      {/* Recent Deliveries */}
      <section>
        <RecentDeliveries deliveries={recentDeliveries || []} />
      </section>

      {/* Decorative Wave Pattern */}
      <div className="fixed bottom-0 left-64 right-0 h-32 wave-pattern pointer-events-none opacity-50" />
    </DashboardLayout>
  );
};

export default Index;
