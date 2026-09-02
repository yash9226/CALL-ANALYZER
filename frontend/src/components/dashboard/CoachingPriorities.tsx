import type { CriterionPerformance } from "@/lib/api";
import { formatPercent, scoreFillClass } from "@/lib/format";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { EmptyState } from "@/components/ui/empty";
import { Tooltip } from "@/components/ui/tooltip";

/** The API returns worst-first: this is the list a manager acts on. */
export function CoachingPriorities({ data }: { data: CriterionPerformance[] }) {
  return (
    <Card>
      <CardHeader>
        <div>
          <CardTitle>Coaching priorities</CardTitle>
          <p className="text-xs text-muted-foreground">Lowest-scoring criteria first</p>
        </div>
      </CardHeader>
      <CardContent className="space-y-3">
        {data.length === 0 ? (
          <EmptyState title="No criteria scored in this period" />
        ) : (
          data.map((c) => (
            <div key={c.criterion_code} className="space-y-1">
              <p className="text-2xs uppercase tracking-wide text-muted-foreground">
                {c.section_code} / {c.subsection_code}
              </p>
              <div className="flex items-baseline justify-between gap-3">
                <span className="flex items-center gap-1.5 text-[13px] font-medium">
                  {c.criterion_name}
                  {c.is_critical && <Badge variant="solid-danger">CRITICAL</Badge>}
                </span>
                <Tooltip content="Share of applicable scores below half marks">
                  <span className="tabular shrink-0 text-xs font-semibold text-danger-text">
                    {formatPercent(c.fail_rate_pct, 0)} fail
                  </span>
                </Tooltip>
              </div>
              <div className="flex items-center gap-2">
                <div className="h-1.5 flex-1 overflow-hidden rounded-full bg-muted">
                  <div
                    className={`h-full rounded-full ${scoreFillClass(c.avg_score)}`}
                    style={{ width: `${Math.max(1, c.avg_score ?? 0)}%` }}
                  />
                </div>
                <span className="tabular w-11 shrink-0 text-right text-2xs text-muted-foreground">
                  {formatPercent(c.avg_score, 0)}
                </span>
              </div>
              {c.not_applicable > 0 && (
                <p className="text-2xs text-muted-foreground">
                  N/A on {c.not_applicable} call{c.not_applicable === 1 ? "" : "s"}
                </p>
              )}
            </div>
          ))
        )}
      </CardContent>
    </Card>
  );
}
