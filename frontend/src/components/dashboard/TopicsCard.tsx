import { useNavigate } from "react-router-dom";
import type { TopicBreakdown } from "@/lib/api";
import { formatPercent, formatSigned, humanise, scoreTextClass } from "@/lib/format";
import { Card, CardHeader, CardTitle } from "@/components/ui/card";
import { EmptyState } from "@/components/ui/empty";
import { Table, TBody, TD, TH, THead, TR } from "@/components/ui/table";
import { cn } from "@/lib/utils";

/** Sentiment renders as a diverging bar from a centre line, because a signed
 *  −1..+1 value read as a bare number is much slower to scan. */
function SentimentBar({ value }: { value: number | null }) {
  if (value === null) return <span className="text-muted-foreground">—</span>;
  // Real topic sentiment clusters near zero (±0.05), so scaling to the full
  // -1..1 range renders a sub-pixel sliver. A 6% floor keeps the direction
  // visible, and the number carries the actual magnitude.
  const magnitude = Math.min(50, Math.max(value === 0 ? 0 : 6, Math.abs(value) * 50));
  const positive = value >= 0;
  return (
    <div className="flex items-center gap-2">
      <div className="relative h-1.5 w-14 shrink-0 rounded-full bg-muted">
        <div className="absolute left-1/2 h-full w-px bg-border" />
        <div
          className={cn("absolute h-full rounded-full", positive ? "bg-success" : "bg-danger")}
          style={
            positive
              ? { left: "50%", width: `${magnitude}%` }
              : { right: "50%", width: `${magnitude}%` }
          }
        />
      </div>
      <span className="tabular text-2xs text-muted-foreground">{formatSigned(value)}</span>
    </div>
  );
}

export function TopicsCard({ data }: { data: TopicBreakdown[] }) {
  const navigate = useNavigate();

  return (
    <Card>
      <CardHeader>
        <div>
          <CardTitle>Topics</CardTitle>
          <p className="text-xs text-muted-foreground">What customers are calling about</p>
        </div>
      </CardHeader>
      {data.length === 0 ? (
        <EmptyState title="No topics tagged yet" description="Topics come from the summary agent." />
      ) : (
        <Table>
          <THead>
            <TR>
              <TH>Topic</TH>
              <TH className="text-right">Calls</TH>
              <TH className="text-right">Avg score</TH>
              <TH>Sentiment</TH>
            </TR>
          </THead>
          <TBody>
            {data.slice(0, 8).map((t) => (
              <TR
                key={t.topic}
                onClick={() => navigate(`/calls?topic=${encodeURIComponent(t.topic)}`)}
                className="cursor-pointer hover:bg-accent/50"
              >
                <TD className="font-medium">{humanise(t.topic)}</TD>
                <TD className="tabular text-right text-muted-foreground">{t.calls}</TD>
                <TD className={cn("tabular text-right font-semibold", scoreTextClass(t.avg_score))}>
                  {formatPercent(t.avg_score)}
                </TD>
                <TD>
                  <SentimentBar value={t.avg_sentiment} />
                </TD>
              </TR>
            ))}
          </TBody>
        </Table>
      )}
    </Card>
  );
}
