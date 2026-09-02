import { useState } from "react";
import {
  Bar,
  CartesianGrid,
  ComposedChart,
  Line,
  ResponsiveContainer,
  Tooltip as RTooltip,
  XAxis,
  YAxis,
} from "recharts";
import type { TrendPoint } from "@/lib/api";
import { formatPercent } from "@/lib/format";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { EmptyState } from "@/components/ui/empty";
import { cn } from "@/lib/utils";

const GRANULARITIES = ["day", "week", "month"] as const;
export type Granularity = (typeof GRANULARITIES)[number];

function ChartTooltip({ active, payload, label }: any) {
  if (!active || !payload?.length) return null;
  const d: TrendPoint = payload[0].payload;
  return (
    <div className="rounded-md border border-border bg-popover px-3 py-2 text-xs shadow-md">
      <p className="mb-1.5 font-medium">{label}</p>
      <dl className="space-y-0.5 tabular">
        <Row k="Calls" v={d.calls} />
        <Row k="Average score" v={formatPercent(d.avg_score)} />
        <Row k="Sentiment" v={d.avg_sentiment?.toFixed(2) ?? "—"} />
        <Row k="Auto-fails" v={d.auto_fails} danger={d.auto_fails > 0} />
      </dl>
    </div>
  );
}

const Row = ({ k, v, danger }: { k: string; v: React.ReactNode; danger?: boolean }) => (
  <div className="flex justify-between gap-6">
    <dt className="text-muted-foreground">{k}</dt>
    <dd className={cn("font-medium", danger && "text-danger-text")}>{v}</dd>
  </div>
);

export function TrendChart({
  data,
  granularity,
  onGranularityChange,
}: {
  data: TrendPoint[];
  granularity: Granularity;
  onGranularityChange: (g: Granularity) => void;
}) {
  const [showSentiment, setShowSentiment] = useState(false);

  return (
    <Card>
      <CardHeader>
        <div>
          <CardTitle>Quality trend</CardTitle>
          <p className="text-xs text-muted-foreground">Average score and call volume over time</p>
        </div>
        <div className="flex items-center gap-3">
          <label className="flex cursor-pointer items-center gap-1.5 text-2xs text-muted-foreground">
            <input
              type="checkbox"
              checked={showSentiment}
              onChange={(e) => setShowSentiment(e.target.checked)}
              className="size-3 accent-[hsl(var(--chart-2))]"
            />
            Sentiment
          </label>
          <div className="inline-flex rounded-md bg-muted p-0.5">
            {GRANULARITIES.map((g) => (
              <button
                key={g}
                onClick={() => onGranularityChange(g)}
                className={cn(
                  "rounded px-2 py-1 text-2xs font-medium capitalize transition-colors",
                  granularity === g
                    ? "bg-background text-foreground shadow-sm"
                    : "text-muted-foreground hover:text-foreground",
                )}
              >
                {g}
              </button>
            ))}
          </div>
        </div>
      </CardHeader>
      <CardContent>
        {data.length === 0 ? (
          <EmptyState title="No calls in this period" />
        ) : (
          <ResponsiveContainer width="100%" height={260}>
            <ComposedChart data={data} margin={{ top: 4, right: 8, bottom: 0, left: -12 }}>
              <CartesianGrid
                vertical={false}
                stroke="hsl(var(--border))"
                strokeDasharray="3 3"
              />
              <XAxis
                dataKey="bucket"
                tick={{ fontSize: 11, fill: "hsl(var(--muted-foreground))" }}
                tickLine={false}
                axisLine={false}
              />
              <YAxis
                yAxisId="score"
                domain={[0, 100]}
                tick={{ fontSize: 11, fill: "hsl(var(--muted-foreground))" }}
                tickLine={false}
                axisLine={false}
                width={38}
              />
              <YAxis
                yAxisId="calls"
                orientation="right"
                tick={{ fontSize: 11, fill: "hsl(var(--muted-foreground))" }}
                tickLine={false}
                axisLine={false}
                width={30}
              />
              <RTooltip content={<ChartTooltip />} cursor={{ fill: "hsl(var(--muted) / 0.5)" }} />
              <Bar
                isAnimationActive={false}
                yAxisId="calls"
                dataKey="calls"
                fill="hsl(var(--muted-foreground))"
                fillOpacity={0.15}
                radius={[3, 3, 0, 0]}
                maxBarSize={40}
              />
              <Line
                isAnimationActive={false}
                yAxisId="score"
                type="monotone"
                dataKey="avg_score"
                stroke="hsl(var(--chart-1))"
                strokeWidth={2.5}
                dot={false}
                activeDot={{ r: 5 }}
              />
              {showSentiment && (
                <Line
                isAnimationActive={false}
                  yAxisId="score"
                  type="monotone"
                  // Sentiment is -1..1; rescaled onto the 0-100 axis so both
                  // series share one axis instead of implying a false comparison
                  // across two differently-scaled ones.
                  dataKey={(d: TrendPoint) =>
                    d.avg_sentiment === null ? null : (d.avg_sentiment + 1) * 50
                  }
                  name="sentiment"
                  stroke="hsl(var(--chart-2))"
                  strokeWidth={2}
                  strokeDasharray="4 3"
                  dot={false}
                />
              )}
            </ComposedChart>
          </ResponsiveContainer>
        )}
      </CardContent>
    </Card>
  );
}
