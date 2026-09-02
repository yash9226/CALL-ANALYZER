import { ArrowDown, ArrowUp, Minus } from "lucide-react";
import { Card } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { Tooltip } from "@/components/ui/tooltip";
import { cn } from "@/lib/utils";

export function KpiCard({
  label,
  value,
  sub,
  change,
  /** true when a DECREASE is the good outcome (auto-fails, risk flags). */
  invertTrend = false,
  alert = false,
  tooltip,
}: {
  label: string;
  value: React.ReactNode;
  sub?: React.ReactNode;
  change?: number | null;
  invertTrend?: boolean;
  alert?: boolean;
  tooltip?: string;
}) {
  // null is not zero. It means there was no comparable prior period, and
  // rendering "0%" would state something the data does not support.
  const hasChange = change !== null && change !== undefined && Number.isFinite(change);
  const improving = hasChange ? (invertTrend ? change! < 0 : change! > 0) : null;
  const flat = hasChange && Math.abs(change!) < 0.05;

  return (
    <Card className={cn("p-4", alert && "border-danger/40")}>
      <div className="flex items-start justify-between gap-2">
        <Tooltip content={tooltip}>
          <p className="text-2xs font-medium uppercase tracking-wider text-muted-foreground">
            {label}
          </p>
        </Tooltip>
        {hasChange && (
          <span
            className={cn(
              "inline-flex items-center gap-0.5 rounded-full px-1.5 py-0.5 text-2xs font-medium",
              flat
                ? "bg-muted text-muted-foreground"
                : improving
                  ? "bg-success-soft text-success-text"
                  : "bg-danger-soft text-danger-text",
            )}
          >
            {flat ? (
              <Minus className="size-2.5" />
            ) : change! > 0 ? (
              <ArrowUp className="size-2.5" />
            ) : (
              <ArrowDown className="size-2.5" />
            )}
            {Math.abs(change!).toFixed(1)}%
          </span>
        )}
      </div>
      <p className="kpi-value mt-2 text-[30px] font-bold leading-none tracking-tight">{value}</p>
      {sub && <p className="mt-1.5 text-xs text-muted-foreground">{sub}</p>}
    </Card>
  );
}

export const KpiSkeleton = () => (
  <Card className="p-4">
    <Skeleton className="h-3 w-24" />
    <Skeleton className="mt-3 h-8 w-20" />
    <Skeleton className="mt-2 h-3 w-28" />
  </Card>
);
