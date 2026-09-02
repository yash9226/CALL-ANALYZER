import { useQuery } from "@tanstack/react-query";
import { ArrowLeft, ListChecks, Flag, GitBranch, History, Smile } from "lucide-react";
import { useState } from "react";
import { Link, useParams } from "react-router-dom";
import { PageHeader } from "@/components/layout/AppLayout";
import { QueryBoundary } from "@/components/QueryBoundary";
import { FlagsPanel } from "@/components/calls/FlagsPanel";
import { HistoryPanel } from "@/components/calls/HistoryPanel";
import { PipelinePanel } from "@/components/calls/PipelinePanel";
import { ScoresPanel } from "@/components/calls/ScoresPanel";
import { SentimentPanel } from "@/components/calls/SentimentPanel";
import { TranscriptPanel, type Highlight } from "@/components/calls/TranscriptPanel";
import { Alert } from "@/components/ui/alert";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { api } from "@/lib/api";
import { formatDate, formatDuration, formatPercent, humanise, scoreTextClass } from "@/lib/format";
import { cn } from "@/lib/utils";

export default function CallDetail() {
  const { callId } = useParams<{ callId: string }>();
  const [highlight, setHighlight] = useState<Highlight | null>(null);
  const [selectedCode, setSelectedCode] = useState<string | null>(null);

  const query = useQuery({
    queryKey: ["call", callId],
    queryFn: () => api.calls.get(callId!),
    enabled: !!callId,
  });

  const jumpToTurn = (index: number) =>
    document.getElementById(`turn-${index}`)?.scrollIntoView({ behavior: "smooth", block: "center" });

  const d = query.data;
  const call = d?.call;

  return (
    <>
      <PageHeader
        title={call?.call_code ?? "Call"}
        description={
          call
            ? `${call.agent_name ?? "Unknown agent"} · ${call.team_name ?? "—"} · ${formatDate(call.started_at)} · ${formatDuration(call.duration_seconds)}`
            : undefined
        }
        actions={
          <div className="flex items-center gap-4">
            <Link
              to="/calls"
              className="inline-flex items-center gap-1.5 text-xs text-muted-foreground hover:text-foreground focus-ring rounded"
            >
              <ArrowLeft className="size-3.5" />
              Calls
            </Link>
            {call && !call.auto_fail_triggered && call.score_percentage !== null && (
              <div className="text-right">
                <p
                  className={cn(
                    "tabular text-[32px] font-bold leading-none",
                    scoreTextClass(call.score_percentage),
                  )}
                >
                  {formatPercent(call.score_percentage)}
                </p>
                {call.grade && (
                  <Badge variant={call.score_percentage >= 60 ? "warning" : "danger"} className="mt-1">
                    Grade {call.grade}
                  </Badge>
                )}
              </div>
            )}
          </div>
        }
      />

      <div className="space-y-4 p-6">
        <QueryBoundary
          isLoading={query.isLoading}
          error={query.error}
          onRetry={query.refetch}
          skeleton={
            <div className="grid gap-4 lg:grid-cols-12">
              <Skeleton className="h-[600px] lg:col-span-7" />
              <Skeleton className="h-[600px] lg:col-span-5" />
            </div>
          }
        >
          {d && call && (
            <>
              {/* An auto-fail must never appear as a bare unexplained zero. */}
              {call.auto_fail_triggered && (
                <Alert title="Auto-fail — this call scores 0%">
                  {d.evaluation_history.find((h) => h.is_current)?.auto_fail_triggered
                    ? "A criterion marked CRITICAL was not met, which zeroes the entire call score regardless of performance elsewhere."
                    : ""}
                  {d.criterion_scores
                    .filter((c) => c.is_critical_snapshot && c.is_applicable && (c.normalized ?? 0) < 0.5)
                    .map((c) => (
                      <p key={c.id} className="mt-1 font-medium">
                        {c.criterion_name}: {c.reasoning}
                      </p>
                    ))}
                </Alert>
              )}

              {d.summary && (
                <Card>
                  <CardContent className="pt-4">
                    <p className="text-[15px] font-semibold">{d.summary.headline}</p>
                    <p className="mt-1.5 text-[13px] leading-relaxed text-muted-foreground">
                      {d.summary.summary}
                    </p>
                    <div className="mt-3 flex flex-wrap gap-1.5">
                      {d.summary.resolution_status && (
                        <Badge
                          variant={
                            d.summary.resolution_status === "resolved" ? "success" : "warning"
                          }
                        >
                          {humanise(d.summary.resolution_status)}
                        </Badge>
                      )}
                      {d.summary.customer_intent && (
                        <Badge variant="outline">{humanise(d.summary.customer_intent)}</Badge>
                      )}
                      {d.summary.topics.map((t) => (
                        <Badge key={t} variant="primary">
                          {humanise(t)}
                        </Badge>
                      ))}
                    </div>
                    {d.summary.next_actions.length > 0 && (
                      <ul className="mt-3 space-y-1 border-t border-border pt-3">
                        {d.summary.next_actions.map((a, i) => (
                          <li key={i} className="flex gap-2 text-xs">
                            <span className="text-muted-foreground">→</span>
                            <span>
                              {a.action}
                              {a.owner && (
                                <span className="text-muted-foreground"> · {a.owner}</span>
                              )}
                              {a.due && <span className="text-muted-foreground"> · {a.due}</span>}
                            </span>
                          </li>
                        ))}
                      </ul>
                    )}
                  </CardContent>
                </Card>
              )}

              <div className="grid gap-4 lg:grid-cols-12">
                <div className="lg:col-span-7">
                  <div className="lg:sticky lg:top-20 lg:max-h-[calc(100vh-6rem)]">
                    <TranscriptPanel
                      turns={d.turns}
                      statistics={d.statistics}
                      highlight={highlight}
                      onClearHighlight={() => {
                        setHighlight(null);
                        setSelectedCode(null);
                      }}
                    />
                  </div>
                </div>

                <div className="lg:col-span-5">
                  <Card>
                    <CardContent className="pt-4">
                      <Tabs defaultValue="scores">
                        <TabsList className="flex w-full flex-wrap justify-start gap-0.5">
                          <TabsTrigger value="scores">
                            <ListChecks className="size-3.5" />
                            Scores
                          </TabsTrigger>
                          <TabsTrigger value="sentiment">
                            <Smile className="size-3.5" />
                            Sentiment
                          </TabsTrigger>
                          <TabsTrigger value="flags">
                            <Flag className="size-3.5" />
                            Flags
                            {d.risk_flags.length > 0 && (
                              <Badge variant="danger">{d.risk_flags.length}</Badge>
                            )}
                          </TabsTrigger>
                          <TabsTrigger value="pipeline">
                            <GitBranch className="size-3.5" />
                            Pipeline
                          </TabsTrigger>
                          <TabsTrigger value="history">
                            <History className="size-3.5" />
                            History
                          </TabsTrigger>
                        </TabsList>

                        <TabsContent value="scores">
                          <ScoresPanel
                            detail={d}
                            selectedCode={selectedCode}
                            onSelect={(h, code) => {
                              setHighlight(h);
                              setSelectedCode(code);
                            }}
                            onJumpToTurn={jumpToTurn}
                          />
                        </TabsContent>
                        <TabsContent value="sentiment">
                          <SentimentPanel detail={d} onJumpToTurn={jumpToTurn} />
                        </TabsContent>
                        <TabsContent value="flags">
                          <FlagsPanel flags={d.risk_flags} onJumpToTurn={jumpToTurn} />
                        </TabsContent>
                        <TabsContent value="pipeline">
                          <PipelinePanel runs={d.agent_runs} />
                        </TabsContent>
                        <TabsContent value="history">
                          <HistoryPanel history={d.evaluation_history} />
                        </TabsContent>
                      </Tabs>
                    </CardContent>
                  </Card>
                </div>
              </div>
            </>
          )}
        </QueryBoundary>
      </div>
    </>
  );
}
