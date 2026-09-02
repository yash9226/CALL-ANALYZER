import { ShieldCheck } from "lucide-react";
import { useNavigate } from "react-router-dom";
import type { FlagSummary, RiskSeverity } from "@/lib/api";
import { formatRelative, humanise, SEVERITY_ORDER } from "@/lib/format";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { EmptyState } from "@/components/ui/empty";

const SEVERITY_VARIANT: Record<RiskSeverity, "solid-danger" | "danger" | "warning" | "muted"> = {
  critical: "solid-danger",
  high: "danger",
  medium: "warning",
  low: "muted",
};

export function RiskFlagsCard({ data }: { data: FlagSummary }) {
  const navigate = useNavigate();

  return (
    <Card>
      <CardHeader>
        <div>
          <CardTitle>Open risk flags</CardTitle>
          <p className="text-xs text-muted-foreground">{data.total} raised in this period</p>
        </div>
        <div className="flex gap-1">
          {SEVERITY_ORDER.map((sev) =>
            data.by_severity[sev] ? (
              <Badge key={sev} variant={SEVERITY_VARIANT[sev]}>
                {data.by_severity[sev]} {sev}
              </Badge>
            ) : null,
          )}
        </div>
      </CardHeader>
      <CardContent className="space-y-1">
        {data.recent_open.length === 0 ? (
          <EmptyState icon={ShieldCheck} title="No open flags" description="Nothing needs triage." />
        ) : (
          data.recent_open.map((f) => (
            <button
              key={f.id}
              onClick={() => navigate(`/calls/${f.call_id}`)}
              className="flex w-full items-start gap-2.5 rounded-md px-2 py-2 text-left transition-colors hover:bg-accent focus-ring"
            >
              <Badge variant={SEVERITY_VARIANT[f.severity]} className="mt-0.5 shrink-0">
                {f.severity}
              </Badge>
              <div className="min-w-0 flex-1">
                <p className="truncate text-[13px] font-medium">{f.title}</p>
                <p className="truncate text-2xs text-muted-foreground">
                  <span className="font-mono">{f.call_code}</span>
                  {f.agent_name && ` · ${f.agent_name}`} · {formatRelative(f.created_at)}
                </p>
              </div>
            </button>
          ))
        )}
      </CardContent>
    </Card>
  );
}
