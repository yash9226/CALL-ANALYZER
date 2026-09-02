import {
  Area,
  AreaChart,
  CartesianGrid,
  ReferenceLine,
  ResponsiveContainer,
  Tooltip as RTooltip,
  XAxis,
  YAxis,
} from "recharts";
import type { CallDetail } from "@/lib/api";
import { formatSigned, humanise } from "@/lib/format";
import { Badge } from "@/components/ui/badge";
import { EmptyState } from "@/components/ui/empty";
import { cn } from "@/lib/utils";

export function SentimentPanel({
  detail,
  onJumpToTurn,
}: {
  detail: CallDetail;
  onJumpToTurn: (index: number) => void;
}) {
  const timeline = detail.sentiment_timeline;
  if (timeline.length === 0) {
    return <EmptyState title="No sentiment analysis" description="No customer turns were scored." />;
  }

  const opening = timeline[0]?.score ?? 0;
  const closing = timeline[timeline.length - 1]?.score ?? 0;
  const delta = closing - opening;
  const trajectory = detail.call.sentiment_trajectory;

  return (
    <div className="space-y-4">
      <ResponsiveContainer width="100%" height={200}>
        <AreaChart
          data={timeline}
          margin={{ top: 8, right: 8, bottom: 0, left: -22 }}
          onClick={(e: any) => {
            const idx = e?.activePayload?.[0]?.payload?.turn_index;
            if (idx !== undefined) onJumpToTurn(idx);
          }}
        >
          <defs>
            <linearGradient id="pos" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor="hsl(var(--success))" stopOpacity={0.35} />
              <stop offset="100%" stopColor="hsl(var(--success))" stopOpacity={0} />
            </linearGradient>
          </defs>
          <CartesianGrid vertical={false} stroke="hsl(var(--border))" strokeDasharray="3 3" />
          <XAxis
            dataKey="turn_index"
            tick={{ fontSize: 10, fill: "hsl(var(--muted-foreground))" }}
            tickLine={false}
            axisLine={false}
          />
          <YAxis
            domain={[-1, 1]}
            ticks={[-1, -0.5, 0, 0.5, 1]}
            tick={{ fontSize: 10, fill: "hsl(var(--muted-foreground))" }}
            tickLine={false}
            axisLine={false}
            width={34}
          />
          <ReferenceLine y={0} stroke="hsl(var(--border))" strokeWidth={1.5} />
          <RTooltip
            contentStyle={{
              background: "hsl(var(--popover))",
              border: "1px solid hsl(var(--border))",
              borderRadius: 8,
              fontSize: 12,
            }}
            formatter={(v: number) => [v.toFixed(2), "Sentiment"]}
            labelFormatter={(l) => `Turn ${l}`}
          />
          <Area
                isAnimationActive={false}
            type="monotone"
            dataKey="score"
            stroke="hsl(var(--chart-2))"
            strokeWidth={2}
            fill="url(#pos)"
            dot={{ r: 3, cursor: "pointer" }}
          />
        </AreaChart>
      </ResponsiveContainer>

      <div className="grid grid-cols-3 gap-3">
        <Stat label="Opening" value={formatSigned(opening)} />
        <Stat label="Closing" value={formatSigned(closing)} />
        <Stat
          label="Change"
          value={formatSigned(delta)}
          className={delta > 0.05 ? "text-success-text" : delta < -0.05 ? "text-danger-text" : ""}
        />
      </div>

      {trajectory && (
        <div className="flex items-center gap-2 rounded-md border border-border px-3 py-2">
          <Badge variant={trajectory === "recovered" || trajectory === "improving" ? "success" : "muted"}>
            {humanise(trajectory)}
          </Badge>
          <p className="text-xs text-muted-foreground">
            {trajectory === "recovered"
              ? "The customer started negative and ended positive — the agent turned the call around."
              : trajectory === "declining"
                ? "Sentiment fell over the course of the call."
                : trajectory === "volatile"
                  ? "Sentiment swung sharply in both directions."
                  : "Sentiment stayed broadly level."}
          </p>
        </div>
      )}
    </div>
  );
}

const Stat = ({ label, value, className }: { label: string; value: string; className?: string }) => (
  <div className="rounded-md border border-border px-3 py-2">
    <p className="text-2xs uppercase tracking-wide text-muted-foreground">{label}</p>
    <p className={cn("tabular text-lg font-semibold", className)}>{value}</p>
  </div>
);
