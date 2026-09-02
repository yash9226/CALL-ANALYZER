import { useNavigate } from "react-router-dom";
import type { AgentScorecard } from "@/lib/api";
import { formatPercent, formatSigned, scoreFillClass, scoreTextClass } from "@/lib/format";
import { Badge } from "@/components/ui/badge";
import { Card, CardHeader, CardTitle } from "@/components/ui/card";
import { EmptyState } from "@/components/ui/empty";
import { Table, TBody, TD, TH, THead, TR } from "@/components/ui/table";
import { Tooltip } from "@/components/ui/tooltip";
import { cn } from "@/lib/utils";

/**
 * Consistency is shown next to the average, not instead of it.
 * A steady 78 and an erratic 60-95 have the same mean but need completely
 * different coaching, and the mean alone hides that entirely.
 */
function ConsistencyBar({ agent }: { agent: AgentScorecard }) {
  const { min_score: min, max_score: max, avg_score: avg, score_stddev: sd } = agent;
  if (min === null || max === null || avg === null) return <span className="text-muted-foreground">—</span>;

  return (
    <Tooltip
      content={
        <span>
          Range {formatPercent(min, 0)}–{formatPercent(max, 0)} · σ {sd?.toFixed(1) ?? "—"}
          <br />
          Lower σ means more consistent.
        </span>
      }
    >
      <div className="flex items-center gap-2">
        <div className="relative h-1.5 w-20 overflow-hidden rounded-full bg-muted">
          <div
            className="absolute h-full rounded-full bg-muted-foreground/25"
            style={{ left: `${min}%`, width: `${Math.max(2, max - min)}%` }}
          />
          <div
            className={cn("absolute h-full w-1 rounded-full", scoreFillClass(avg))}
            style={{ left: `calc(${avg}% - 2px)` }}
          />
        </div>
        <span className="tabular text-2xs text-muted-foreground">σ{sd?.toFixed(1) ?? "—"}</span>
      </div>
    </Tooltip>
  );
}

export function AgentLeaderboard({ data }: { data: AgentScorecard[] }) {
  const navigate = useNavigate();

  return (
    <Card>
      <CardHeader>
        <div>
          <CardTitle>Agent leaderboard</CardTitle>
          <p className="text-xs text-muted-foreground">Average score and consistency</p>
        </div>
      </CardHeader>
      {data.length === 0 ? (
        <EmptyState title="No agents with calls in this period" />
      ) : (
        <Table>
          <THead>
            <TR>
              <TH>Agent</TH>
              <TH>Team</TH>
              <TH className="text-right">Calls</TH>
              <TH className="text-right">Avg</TH>
              <TH>Consistency</TH>
              <TH className="text-right">Auto-fails</TH>
              <TH className="text-right">Sent. Δ</TH>
            </TR>
          </THead>
          <TBody>
            {data.map((a) => (
              <TR
                key={a.support_agent_id}
                onClick={() => navigate(`/calls?support_agent_id=${a.support_agent_id}`)}
                className="cursor-pointer hover:bg-accent/50"
              >
                <TD>
                  <p className="font-medium">{a.agent_name}</p>
                  <p className="font-mono text-2xs text-muted-foreground">{a.agent_code}</p>
                </TD>
                <TD>
                  <Badge variant="outline">{a.team_name ?? "—"}</Badge>
                </TD>
                <TD className="tabular text-right text-muted-foreground">{a.calls}</TD>
                <TD className={cn("tabular text-right font-semibold", scoreTextClass(a.avg_score))}>
                  {formatPercent(a.avg_score)}
                </TD>
                <TD>
                  <ConsistencyBar agent={a} />
                </TD>
                <TD className="text-right">
                  {a.auto_fails > 0 ? (
                    <Badge variant="danger">{a.auto_fails}</Badge>
                  ) : (
                    <span className="text-muted-foreground">0</span>
                  )}
                </TD>
                <TD
                  className={cn(
                    "tabular text-right",
                    (a.avg_sentiment_delta ?? 0) > 0 ? "text-success-text" : "text-muted-foreground",
                  )}
                >
                  {formatSigned(a.avg_sentiment_delta)}
                </TD>
              </TR>
            ))}
          </TBody>
        </Table>
      )}
    </Card>
  );
}
