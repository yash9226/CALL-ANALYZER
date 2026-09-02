import { Check, ShieldCheck } from "lucide-react";
import type { RiskFlag, RiskSeverity } from "@/lib/api";
import { humanise } from "@/lib/format";
import { Badge } from "@/components/ui/badge";
import { EmptyState } from "@/components/ui/empty";
import { cn } from "@/lib/utils";

const VARIANT: Record<RiskSeverity, "solid-danger" | "danger" | "warning" | "muted"> = {
  critical: "solid-danger",
  high: "danger",
  medium: "warning",
  low: "muted",
};

export function FlagsPanel({
  flags,
  onJumpToTurn,
}: {
  flags: RiskFlag[];
  onJumpToTurn: (index: number) => void;
}) {
  if (flags.length === 0) {
    return (
      <EmptyState
        icon={ShieldCheck}
        title="No risks flagged"
        description="The compliance agent found nothing requiring attention."
      />
    );
  }

  return (
    <div className="space-y-2">
      {flags.map((f) => (
        <div
          key={f.id}
          className={cn(
            "rounded-lg border border-border p-3",
            f.is_acknowledged && "opacity-60",
          )}
        >
          <div className="mb-1 flex items-start justify-between gap-2">
            <span className="flex items-center gap-2">
              <Badge variant={VARIANT[f.severity]}>{f.severity}</Badge>
              <span className="text-[13px] font-semibold">{f.title}</span>
            </span>
            {f.is_acknowledged && <Check className="size-3.5 shrink-0 text-success-text" />}
          </div>

          <p className="text-xs leading-relaxed text-muted-foreground">{f.description}</p>

          <div className="mt-2 flex flex-wrap items-center gap-3">
            <Badge variant="outline">{humanise(f.flag_type)}</Badge>
            {f.confidence !== null && (
              <span className="text-2xs text-muted-foreground">
                {Math.round(f.confidence * 100)}% confidence
              </span>
            )}
          </div>

          {f.quoted_text && (
            <blockquote className="mt-2 border-l-2 border-danger pl-2.5">
              <p className="text-xs italic text-muted-foreground">“{f.quoted_text}”</p>
              {f.turn_index !== null && (
                <button
                  onClick={() => onJumpToTurn(f.turn_index!)}
                  className="mt-0.5 text-2xs text-primary hover:underline focus-ring rounded"
                >
                  Jump to turn {f.turn_index}
                </button>
              )}
            </blockquote>
          )}
        </div>
      ))}
    </div>
  );
}
