import type { EvaluationHistoryItem } from "@/lib/api";
import { formatDate, formatPercent, scoreTextClass, TRIGGER_LABEL } from "@/lib/format";
import { Badge } from "@/components/ui/badge";
import { EmptyState } from "@/components/ui/empty";
import { Table, TBody, TD, TH, THead, TR } from "@/components/ui/table";
import { cn } from "@/lib/utils";

/** Answers a question a manager genuinely asks: did this score change because
 *  the agent improved, or because we changed the rubric? */
export function HistoryPanel({ history }: { history: EvaluationHistoryItem[] }) {
  if (history.length === 0) return <EmptyState title="No evaluation history" />;

  return (
    <Table>
      <THead>
        <TR>
          <TH>Date</TH>
          <TH className="text-right">Score</TH>
          <TH>Reason</TH>
          <TH>Model</TH>
          <TH />
        </TR>
      </THead>
      <TBody>
        {history.map((h) => (
          <TR key={h.id}>
            <TD className="whitespace-nowrap text-xs text-muted-foreground">
              {formatDate(h.created_at)}
            </TD>
            <TD className="text-right">
              {h.auto_fail_triggered ? (
                <Badge variant="solid-danger">AUTO-FAIL</Badge>
              ) : (
                <span className={cn("tabular font-semibold", scoreTextClass(h.score_percentage))}>
                  {formatPercent(h.score_percentage)}
                  {h.grade && <span className="ml-1 text-2xs opacity-70">{h.grade}</span>}
                </span>
              )}
            </TD>
            <TD className="text-xs">{TRIGGER_LABEL[h.trigger_reason] ?? h.trigger_reason}</TD>
            <TD className="font-mono text-2xs text-muted-foreground">{h.model_used ?? "—"}</TD>
            <TD>{h.is_current && <Badge variant="primary">Current</Badge>}</TD>
          </TR>
        ))}
      </TBody>
    </Table>
  );
}
