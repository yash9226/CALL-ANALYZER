import { Bar, BarChart, Cell, ResponsiveContainer, Tooltip as RTooltip, XAxis, YAxis } from "recharts";
import type { ScoreDistribution } from "@/lib/api";
import { scoreHex } from "@/lib/format";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

const GRADES = ["A", "B", "C", "D", "F"] as const;

/**
 * All ten bands render, including empty ones. The API returns them deliberately:
 * dropping empty bands would compress the x-axis and make a bimodal
 * distribution look continuous, which is exactly the shape a manager needs to
 * see. A team averaging 70 because everyone scores 70 is a different problem
 * from half the team at 95 and half at 45.
 */
export function ScoreDistributionCard({ data }: { data: ScoreDistribution }) {
  const total = Object.values(data.grades).reduce((a, b) => a + (b ?? 0), 0);

  return (
    <Card>
      <CardHeader>
        <div>
          <CardTitle>Score distribution</CardTitle>
          <p className="text-xs text-muted-foreground">{total} evaluated calls</p>
        </div>
      </CardHeader>
      <CardContent>
        <ResponsiveContainer width="100%" height={190}>
          <BarChart data={data.bands} margin={{ top: 4, right: 4, bottom: 0, left: 0 }}>
            <XAxis
              dataKey="label"
              tick={{ fontSize: 10, fill: "hsl(var(--muted-foreground))" }}
              tickLine={false}
              axisLine={false}
              interval={0}
            />
            <YAxis
              tick={{ fontSize: 11, fill: "hsl(var(--muted-foreground))" }}
              tickLine={false}
              axisLine={false}
              width={28}
              allowDecimals={false}
            />
            <RTooltip
              cursor={{ fill: "hsl(var(--muted) / 0.5)" }}
              contentStyle={{
                background: "hsl(var(--popover))",
                border: "1px solid hsl(var(--border))",
                borderRadius: 8,
                fontSize: 12,
              }}
              formatter={(v: number) => [`${v} calls`, ""]}
            />
            <Bar dataKey="calls" radius={[3, 3, 0, 0]} isAnimationActive={false}>
              {data.bands.map((b) => (
                <Cell key={b.band} fill={scoreHex(b.band + 5)} />
              ))}
            </Bar>
          </BarChart>
        </ResponsiveContainer>

        <div className="mt-3 flex items-center justify-between border-t border-border pt-3">
          {GRADES.map((g) => (
            <div key={g} className="text-center">
              <p className="text-2xs uppercase tracking-wide text-muted-foreground">{g}</p>
              <p className="tabular text-[15px] font-semibold">{data.grades[g] ?? 0}</p>
            </div>
          ))}
        </div>
      </CardContent>
    </Card>
  );
}
