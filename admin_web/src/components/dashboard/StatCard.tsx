import { ReactNode } from "react";
import { cn } from "@/lib/utils";
import { TrendingUp, TrendingDown } from "lucide-react";

interface StatCardProps {
  title: string;
  value: string | number;
  icon: ReactNode;
  trend?: {
    value: number;
    isPositive: boolean;
  };
  variant?: "default" | "primary" | "secondary" | "accent" | "success";
  className?: string;
}

const variantStyles = {
  default: "bg-card",
  primary: "gradient-primary text-primary-foreground",
  secondary: "gradient-warm text-secondary-foreground",
  accent: "gradient-accent text-accent-foreground",
  success: "gradient-success text-success-foreground",
};

export function StatCard({
  title,
  value,
  icon,
  trend,
  variant = "default",
  className,
}: StatCardProps) {
  const isColored = variant !== "default";

  return (
    <div
      className={cn(
        "stat-card",
        variantStyles[variant],
        !isColored && "bg-card shadow-md",
        className
      )}
    >
      <div className="flex items-start justify-between">
        <div className="space-y-3">
          <p
            className={cn(
              "text-sm font-medium",
              isColored ? "text-current/80" : "text-muted-foreground"
            )}
          >
            {title}
          </p>
          <p className="text-3xl font-heading font-bold">{value}</p>
          {trend && (
            <div className="flex items-center gap-1">
              {trend.isPositive ? (
                <TrendingUp className="w-4 h-4" />
              ) : (
                <TrendingDown className="w-4 h-4" />
              )}
              <span
                className={cn(
                  "text-sm font-medium",
                  !isColored &&
                    (trend.isPositive ? "text-success" : "text-destructive")
                )}
              >
                {trend.isPositive ? "+" : ""}
                {trend.value}%
              </span>
              <span
                className={cn(
                  "text-xs",
                  isColored ? "text-current/70" : "text-muted-foreground"
                )}
              >
                vs hier
              </span>
            </div>
          )}
        </div>
        <div
          className={cn(
            "w-12 h-12 rounded-xl flex items-center justify-center",
            isColored ? "bg-white/20" : "bg-primary/10"
          )}
        >
          {icon}
        </div>
      </div>
    </div>
  );
}
