import { ChevronRight, Quote } from "lucide-react";
import { useState } from "react";
import type { CallDetail, CriterionScore } from "@/lib/api";
import { formatScore } from "@/lib/api";
import { formatPercent, scoreFillClass, scoreTextClass } from "@/lib/format";
import { Badge } from "@/components/ui/badge";
import { Tooltip } from "@/components/ui/tooltip";
import { cn } from "@/lib/utils";
import type { Highlight } from "./TranscriptPanel";

/** A ring filled in proportion to the model's own confidence. Surfacing this
 *  tells a manager which scores are worth spot-checking. */
function ConfidenceDot({ value }: { value: number | null }) {
  if (value === null) return null;
  return (
    <Tooltip content={`Model confidence: ${Math.round(value * 100)}%`}>
      <span className="relative inline-flex size-3 shrink-0 items-center justify-center">
        <span className="absolute inset-0 rounded-full border border-muted-foreground/30" />
        <span
          className="absolute rounded-full bg-primary"
          style={{ width: `${value * 10}px`, height: `${value * 10}px` }}
        />
      </span>
    </Tooltip>
  );
}

function CriterionRow({
  score,
  selected,
  onSelect,
  onJumpToTurn,
}: {
  score: CriterionScore;
  selected: boolean;
  onSelect: () => void;
  onJumpToTurn: (index: number) => void;
}) {
  const [open, setOpen] = useState(false);
  const pct = score.normalized === null ? null : score.normalized * 100;

  return (
    <div
      className={cn(
        "rounded-md border border-transparent px-2 py-1.5 transition-colors",
        selected && "border-primary/40 bg-primary/5",
        !score.is_applicable && "opacity-60",
      )}
    >
      <div className="flex items-center gap-2">
        <button
          onClick={() => setOpen((o) => !o)}
          className="shrink-0 text-muted-foreground focus-ring rounded"
          aria-label={open ? "Collapse" : "Expand"}
        >
          <ChevronRight className={cn("size-3.5 transition-transform", open && "rotate-90")} />
        </button>

        <button onClick={onSelect} className="flex min-w-0 flex-1 items-center gap-1.5 text-left focus-ring rounded">
          <span className="truncate text-[13px]">{score.criterion_name}</span>
          {score.is_critical_snapshot && <Badge variant="solid-danger">CRITICAL</Badge>}
        </button>

        <ConfidenceDot value={score.confidence} />

        {score.citations.length > 0 && (
          <Tooltip content={`${score.citations.length} transcript citation(s)`}>
            <span className="inline-flex shrink-0 items-center gap-0.5 text-2xs text-muted-foreground">
              <Quote className="size-2.5" />
              {score.citations.length}
            </span>
          </Tooltip>
        )}

        {/* An inapplicable criterion is N/A, never 0. The backend removes it from
            the weighted denominator entirely, so rendering 0 would state that
            the agent failed something that never came up. */}
        {!score.is_applicable ? (
          <Tooltip content={score.na_reason ?? "Not applicable to this call"}>
            <Badge variant="muted">N/A</Badge>
          </Tooltip>
        ) : (
          <span className={cn("tabular shrink-0 text-xs font-semibold", scoreTextClass(pct))}>
            {formatScore(score)}
          </span>
        )}
      </div>

      {open && (
        <div className="mt-2 space-y-2 pl-6">
          {score.reasoning && (
            <p className="text-xs leading-relaxed text-muted-foreground">{score.reasoning}</p>
          )}
          {score.citations.map((c) => (
            <blockquote
              key={c.id}
              className={cn(
                "border-l-2 pl-2.5 text-xs",
                c.polarity === "detracting" ? "border-danger" : "border-success",
              )}
            >
              <p className="italic text-muted-foreground">“{c.quoted_text}”</p>
              {c.turn_index !== null && (
                <button
                  onClick={() => onJumpToTurn(c.turn_index!)}
                  className="mt-0.5 text-2xs text-primary hover:underline focus-ring rounded"
                >
                  Jump to turn {c.turn_index}
                </button>
              )}
            </blockquote>
          ))}
        </div>
      )}
    </div>
  );
}

export function ScoresPanel({
  detail,
  selectedCode,
  onSelect,
  onJumpToTurn,
}: {
  detail: CallDetail;
  selectedCode: string | null;
  onSelect: (h: Highlight | null, code: string | null) => void;
  onJumpToTurn: (index: number) => void;
}) {
  return (
    <div className="space-y-3">
      {detail.section_scores.map((section) => {
        const subs = detail.subsection_scores.filter((s) => s.section_code === section.section_code);
        const pct = section.normalized === null ? null : section.normalized * 100;

        return (
          <div key={section.section_code} className="rounded-lg border border-border">
            <div className="border-b border-border px-3 py-2">
              <div className="mb-1.5 flex items-baseline justify-between gap-2">
                <span className="flex items-center gap-2 text-sm font-semibold">
                  {section.section_name}
                  <Badge variant="muted">{section.weight_snapshot}%</Badge>
                </span>
                <span className={cn("tabular text-sm font-semibold", scoreTextClass(pct))}>
                  {formatPercent(pct)}
                </span>
              </div>
              <div className="h-1.5 w-full overflow-hidden rounded-full bg-muted">
                <div
                  className={cn("h-full rounded-full", scoreFillClass(pct))}
                  style={{ width: `${Math.max(1, pct ?? 0)}%` }}
                />
              </div>
            </div>

            <div className="space-y-2 p-2">
              {subs.map((sub) => {
                const criteria = detail.criterion_scores.filter(
                  (c) => c.subsection_code === sub.subsection_code,
                );
                const subPct = sub.normalized === null ? null : sub.normalized * 100;

                return (
                  <div key={sub.subsection_code} className="pl-2">
                    <div className="mb-1 flex items-baseline justify-between gap-2">
                      <span className="flex items-center gap-1.5 text-xs font-medium text-muted-foreground">
                        {sub.subsection_name}
                        <span className="text-2xs opacity-70">{sub.weight_snapshot}%</span>
                      </span>
                      <span className="flex items-center gap-2">
                        <span className="text-2xs text-muted-foreground">
                          {sub.criteria_scored}/{sub.criteria_total} scored
                        </span>
                        <span className={cn("tabular text-xs font-semibold", scoreTextClass(subPct))}>
                          {formatPercent(subPct)}
                        </span>
                      </span>
                    </div>

                    <div className="space-y-0.5">
                      {criteria.map((c) => (
                        <CriterionRow
                          key={c.id}
                          score={c}
                          selected={selectedCode === c.criterion_code}
                          onSelect={() =>
                            selectedCode === c.criterion_code
                              ? onSelect(null, null)
                              : onSelect(
                                  { criterionName: c.criterion_name, citations: c.citations },
                                  c.criterion_code,
                                )
                          }
                          onJumpToTurn={onJumpToTurn}
                        />
                      ))}
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        );
      })}
    </div>
  );
}
