import { useNavigate } from "react-router-dom";
import type { SectionPerformance as Section } from "@/lib/api";
import { formatPercent, humanise, scoreFillClass, scoreTextClass } from "@/lib/format";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { EmptyState } from "@/components/ui/empty";

/** The API returns weakest-first and that order is preserved deliberately —
 *  the point of this card is "what should we fix", not an alphabetical index. */
export function SectionPerformanceCard({ data }: { data: Section[] }) {
  const navigate = useNavigate();

  return (
    <Card>
      <CardHeader>
        <div>
          <CardTitle>Where we're weakest</CardTitle>
          <p className="text-xs text-muted-foreground">Average score by rubric section</p>
        </div>
      </CardHeader>
      <CardContent className="space-y-3">
        {data.length === 0 ? (
          <EmptyState title="No scored calls in this period" />
        ) : (
          data.map((s) => (
            <button
              key={s.section_code}
              onClick={() => navigate("/calls?sort_by=score&sort_dir=asc")}
              className="group block w-full text-left focus-ring rounded"
            >
              <div className="mb-1 flex items-baseline justify-between gap-3">
                <span className="flex items-center gap-2 text-[13px] font-medium group-hover:underline">
                  {humanise(s.section_name)}
                  <Badge variant="muted">{s.weight}% weight</Badge>
                </span>
                <span className={`text-[15px] font-semibold ${scoreTextClass(s.avg_score)}`}>
                  {formatPercent(s.avg_score)}
                </span>
              </div>
              <div className="h-2 w-full overflow-hidden rounded-full bg-muted">
                <div
                  className={`h-full rounded-full ${scoreFillClass(s.avg_score)}`}
                  style={{ width: `${Math.max(1, s.avg_score ?? 0)}%` }}
                />
              </div>
            </button>
          ))
        )}
      </CardContent>
    </Card>
  );
}
