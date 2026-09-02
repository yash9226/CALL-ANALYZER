import { X } from "lucide-react";
import { useEffect, useRef } from "react";
import type { CallStatistics, ScoreCitation, TranscriptTurn } from "@/lib/api";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Tooltip } from "@/components/ui/tooltip";
import { cn } from "@/lib/utils";

export interface Highlight {
  criterionName: string;
  citations: ScoreCitation[];
}

const ms = (v: number | null) =>
  v === null ? null : `${Math.floor(v / 60000)}:${String(Math.floor((v % 60000) / 1000)).padStart(2, "0")}`;

function StatTile({ label, value, alert }: { label: string; value: React.ReactNode; alert?: boolean }) {
  return (
    <div className="min-w-0">
      <p className="truncate text-2xs uppercase tracking-wide text-muted-foreground">{label}</p>
      <p className={cn("tabular text-sm font-semibold", alert && "text-warning-text")}>{value}</p>
    </div>
  );
}

export function TranscriptPanel({
  turns,
  statistics,
  highlight,
  onClearHighlight,
}: {
  turns: TranscriptTurn[];
  statistics: CallStatistics | null;
  highlight: Highlight | null;
  onClearHighlight: () => void;
}) {
  const containerRef = useRef<HTMLDivElement>(null);

  /**
   * Citations are resolved by TURN INDEX, never by searching for the quoted
   * text. The scoring model paraphrases when it quotes, so a text search
   * silently matches nothing and the highlight never appears. The backend
   * guarantees turn_index and the character offsets are exact.
   */
  const cited = new Map(highlight?.citations.map((c) => [c.turn_index, c]) ?? []);

  useEffect(() => {
    if (!highlight?.citations.length) return;
    const first = highlight.citations[0]?.turn_index;
    if (first === null || first === undefined) return;
    document
      .getElementById(`turn-${first}`)
      ?.scrollIntoView({ behavior: "smooth", block: "center" });
  }, [highlight]);

  const talkRatio = statistics?.agent_talk_ratio ?? null;

  return (
    <Card className="flex h-full flex-col">
      <CardHeader className="flex-col items-stretch gap-3">
        <CardTitle>Transcript</CardTitle>
        {statistics && (
          <div className="grid grid-cols-3 gap-3 sm:grid-cols-5">
            <Tooltip
              content={
                talkRatio && talkRatio > 0.75
                  ? "The agent dominated the conversation — a listening red flag."
                  : "Share of words spoken by the agent."
              }
            >
              <div>
                <StatTile
                  label="Agent talk"
                  value={talkRatio === null ? "—" : `${Math.round(talkRatio * 100)}%`}
                  alert={!!talkRatio && talkRatio > 0.75}
                />
                <div className="mt-1 h-1 w-full overflow-hidden rounded-full bg-muted">
                  <div
                    className={cn(
                      "h-full rounded-full",
                      talkRatio && talkRatio > 0.75 ? "bg-warning" : "bg-primary",
                    )}
                    style={{ width: `${(talkRatio ?? 0) * 100}%` }}
                  />
                </div>
              </div>
            </Tooltip>
            <StatTile label="Questions" value={statistics.question_count_agent} />
            <StatTile
              label="Interruptions"
              value={statistics.interruption_count}
              alert={statistics.interruption_count > 0}
            />
            <StatTile label="Agent turns" value={statistics.agent_turn_count} />
            <StatTile label="Customer turns" value={statistics.customer_turn_count} />
          </div>
        )}
      </CardHeader>

      {highlight && (
        <div className="sticky top-0 z-10 mx-5 mb-2 flex items-center justify-between gap-2 rounded-md border border-primary/30 bg-primary/10 px-3 py-1.5">
          <p className="truncate text-2xs">
            Showing evidence for <span className="font-semibold">{highlight.criterionName}</span>
          </p>
          <Button variant="ghost" size="icon-sm" onClick={onClearHighlight} aria-label="Clear highlight">
            <X />
          </Button>
        </div>
      )}

      <CardContent ref={containerRef} className="flex-1 space-y-2 overflow-y-auto pt-0">
        {turns.map((t) => {
          const citation = cited.get(t.turn_index);
          const isAgent = t.speaker === "agent";
          return (
            <div
              key={t.id}
              id={`turn-${t.turn_index}`}
              className={cn("flex", isAgent ? "justify-start" : "justify-end")}
            >
              <div
                className={cn(
                  "max-w-[88%] rounded-lg px-3 py-2 transition-colors",
                  isAgent ? "bg-muted" : "border-l-2 border-primary/40 bg-primary/[0.07]",
                  citation &&
                    (citation.polarity === "detracting"
                      ? "!border-l-2 !border-danger bg-danger-soft ring-1 ring-danger/20"
                      : "!border-l-2 !border-success bg-success-soft ring-1 ring-success/20"),
                )}
              >
                <div className="mb-0.5 flex items-center gap-2">
                  <span className="text-2xs font-semibold uppercase tracking-wide text-muted-foreground">
                    {t.speaker_label}
                  </span>
                  {ms(t.start_ms) && (
                    <span className="tabular text-2xs text-muted-foreground/70">{ms(t.start_ms)}</span>
                  )}
                  {citation && (
                    <Badge variant={citation.polarity === "detracting" ? "danger" : "success"}>
                      {citation.polarity === "detracting" ? "Evidence against" : "Evidence for"}
                    </Badge>
                  )}
                </div>
                <p className="whitespace-pre-wrap text-[13px] leading-relaxed">{t.text}</p>
              </div>
            </div>
          );
        })}
      </CardContent>
    </Card>
  );
}
