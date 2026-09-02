import { AlertCircle, CheckCircle2, Circle, RefreshCw } from "lucide-react";
import type { AgentRun } from "@/lib/api";
import { formatMs, formatNumber, humanise } from "@/lib/format";
import { Badge } from "@/components/ui/badge";
import { EmptyState } from "@/components/ui/empty";
import { Tooltip } from "@/components/ui/tooltip";
import { cn } from "@/lib/utils";

/**
 * The trace that makes the multi-agent design inspectable rather than asserted.
 * Five discrete agents, each with its own model, latency and token cost.
 */
export function PipelinePanel({ runs }: { runs: AgentRun[] }) {
  if (runs.length === 0) {
    return <EmptyState title="No pipeline trace" description="This call has not been evaluated." />;
  }

  const totals = runs.reduce(
    (a, r) => ({
      input: a.input + r.input_tokens,
      output: a.output + r.output_tokens,
      latency: a.latency + (r.latency_ms ?? 0),
    }),
    { input: 0, output: 0, latency: 0 },
  );
  const models = [...new Set(runs.map((r) => r.model).filter(Boolean))];

  return (
    <div className="space-y-3">
      <div className="relative space-y-0 pl-1">
        {runs.map((r, i) => (
          <div key={`${r.agent_name}-${i}`} className="relative flex gap-3 pb-4 last:pb-0">
            {i < runs.length - 1 && (
              <span className="absolute left-[7px] top-5 h-full w-px bg-border" aria-hidden />
            )}
            <span className="relative z-10 mt-0.5 shrink-0">
              {r.status === "completed" ? (
                <CheckCircle2 className="size-3.5 text-success-text" />
              ) : r.status === "failed" ? (
                <AlertCircle className="size-3.5 text-danger-text" />
              ) : (
                <Circle className="size-3.5 text-muted-foreground" />
              )}
            </span>

            <div className="min-w-0 flex-1">
              <div className="flex flex-wrap items-center gap-2">
                <span className="text-[13px] font-semibold">{humanise(r.agent_name)}</span>
                {r.attempt_count > 1 && (
                  <Tooltip content="The model was rate-limited or timed out; the provider retried automatically.">
                    <Badge variant="warning">
                      <RefreshCw className="size-2.5" />
                      retried ×{r.attempt_count}
                    </Badge>
                  </Tooltip>
                )}
                {r.status === "failed" && <Badge variant="danger">failed</Badge>}
              </div>

              <p className="mt-0.5 flex flex-wrap gap-x-2 text-2xs text-muted-foreground">
                <span className="font-mono">{r.model ?? "no LLM"}</span>
                <span>·</span>
                <span className="tabular">{formatMs(r.latency_ms)}</span>
                {r.input_tokens + r.output_tokens > 0 && (
                  <>
                    <span>·</span>
                    <span className="tabular">
                      {formatNumber(r.input_tokens)} → {formatNumber(r.output_tokens)} tokens
                    </span>
                  </>
                )}
              </p>

              {r.error_message && (
                <p className="mt-1 text-2xs text-danger-text">{r.error_message}</p>
              )}
            </div>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-3 gap-3 border-t border-border pt-3">
        <Total label="Total tokens" value={formatNumber(totals.input + totals.output)} />
        <Total label="Total latency" value={formatMs(totals.latency)} />
        <Total label="Models" value={models.join(", ") || "—"} mono />
      </div>
    </div>
  );
}

const Total = ({ label, value, mono }: { label: string; value: string; mono?: boolean }) => (
  <div>
    <p className="text-2xs uppercase tracking-wide text-muted-foreground">{label}</p>
    <p className={cn("truncate text-xs font-semibold tabular", mono && "font-mono text-2xs")}>{value}</p>
  </div>
);
