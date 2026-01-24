import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from "recharts";

const data = [
  { name: "Lun", livraisons: 45, montant: 225000 },
  { name: "Mar", livraisons: 52, montant: 260000 },
  { name: "Mer", livraisons: 38, montant: 190000 },
  { name: "Jeu", livraisons: 65, montant: 325000 },
  { name: "Ven", livraisons: 72, montant: 360000 },
  { name: "Sam", livraisons: 58, montant: 290000 },
  { name: "Dim", livraisons: 25, montant: 125000 },
];

export function DeliveryChart() {
  return (
    <div className="bg-card rounded-xl shadow-md p-6">
      <div className="mb-6">
        <h3 className="text-lg font-heading font-semibold">
          Performance hebdomadaire
        </h3>
        <p className="text-sm text-muted-foreground mt-1">
          Évolution des livraisons cette semaine
        </p>
      </div>
      <div className="h-[300px]">
        <ResponsiveContainer width="100%" height="100%">
          <AreaChart data={data}>
            <defs>
              <linearGradient id="colorLivraisons" x1="0" y1="0" x2="0" y2="1">
                <stop
                  offset="5%"
                  stopColor="hsl(204, 70%, 53%)"
                  stopOpacity={0.3}
                />
                <stop
                  offset="95%"
                  stopColor="hsl(204, 70%, 53%)"
                  stopOpacity={0}
                />
              </linearGradient>
              <linearGradient id="colorMontant" x1="0" y1="0" x2="0" y2="1">
                <stop
                  offset="5%"
                  stopColor="hsl(42, 55%, 58%)"
                  stopOpacity={0.3}
                />
                <stop
                  offset="95%"
                  stopColor="hsl(42, 55%, 58%)"
                  stopOpacity={0}
                />
              </linearGradient>
            </defs>
            <CartesianGrid
              strokeDasharray="3 3"
              stroke="hsl(var(--border))"
              vertical={false}
            />
            <XAxis
              dataKey="name"
              axisLine={false}
              tickLine={false}
              tick={{ fill: "hsl(var(--muted-foreground))", fontSize: 12 }}
            />
            <YAxis
              axisLine={false}
              tickLine={false}
              tick={{ fill: "hsl(var(--muted-foreground))", fontSize: 12 }}
            />
            <Tooltip
              contentStyle={{
                backgroundColor: "hsl(var(--card))",
                border: "1px solid hsl(var(--border))",
                borderRadius: "8px",
                boxShadow: "var(--shadow-lg)",
              }}
              labelStyle={{ color: "hsl(var(--foreground))", fontWeight: 600 }}
            />
            <Area
              type="monotone"
              dataKey="livraisons"
              stroke="hsl(204, 70%, 53%)"
              strokeWidth={2}
              fill="url(#colorLivraisons)"
              name="Livraisons"
            />
          </AreaChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}
