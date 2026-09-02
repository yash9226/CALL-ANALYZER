import { useMutation, useQuery } from "@tanstack/react-query";
import { AlertTriangle, ArrowUp, Database, Loader2, MessageSquareText, Sparkles } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { PageHeader } from "@/components/layout/AppLayout";
import { Citations, ModeBadge, ResultTable, SqlPanel } from "@/components/chat/Grounding";
import { Alert } from "@/components/ui/alert";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Textarea } from "@/components/ui/textarea";
import { Tooltip } from "@/components/ui/tooltip";
import { useToast } from "@/components/ui/toast";
import { ApiError, api, type ChatAnswer } from "@/lib/api";
import { formatMs } from "@/lib/format";
import { cn } from "@/lib/utils";

/** One prompt per retrieval path, so the first thing a user tries demonstrates
 *  that the assistant does more than transcript search. */
const EXAMPLES = [
  { q: "Which agents scored lowest on empathy this week?", mode: "analytical" as const },
  { q: "Show me calls where the customer mentioned billing issues", mode: "semantic" as const },
  { q: "What are the most common reasons for auto-failure?", mode: "analytical" as const },
  { q: "Find calls where a customer wanted to cancel", mode: "semantic" as const },
];

type Turn =
  | { role: "user"; content: string }
  | { role: "assistant"; answer: ChatAnswer }
  | { role: "error"; content: string };

/** Renders the minimal markdown the answer model actually emits: bold, bullets,
 *  paragraphs. A full markdown parser would be a dependency for three rules. */
function Answer({ text }: { text: string }) {
  return (
    <div className="space-y-2 text-[13px] leading-relaxed">
      {text.split("\n").map((line, i) => {
        const trimmed = line.trim();
        if (!trimmed) return null;
        const html = trimmed.replace(/\*\*(.+?)\*\*/g, "<strong>$1</strong>");
        if (trimmed.startsWith("- ") || trimmed.startsWith("* ")) {
          return (
            <div key={i} className="flex gap-2 pl-1">
              <span className="text-muted-foreground">•</span>
              <span dangerouslySetInnerHTML={{ __html: html.slice(2) }} />
            </div>
          );
        }
        return <p key={i} dangerouslySetInnerHTML={{ __html: html }} />;
      })}
    </div>
  );
}

export default function Chat() {
  const toast = useToast();
  const [turns, setTurns] = useState<Turn[]>([]);
  const [input, setInput] = useState("");
  const endRef = useRef<HTMLDivElement>(null);

  const index = useQuery({
    queryKey: ["chat-index"],
    queryFn: () => api.chat.indexStatus(),
  });

  const ask = useMutation({
    mutationFn: (question: string) => api.chat.ask(question),
    onSuccess: (answer) => setTurns((t) => [...t, { role: "assistant", answer }]),
    onError: (e) => {
      const message = e instanceof ApiError ? e.message : String(e);
      setTurns((t) => [...t, { role: "error", content: message }]);
      toast({ variant: "danger", title: "Could not answer that", body: message });
    },
  });

  useEffect(() => {
    endRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [turns, ask.isPending]);

  const submit = (question: string) => {
    const q = question.trim();
    if (!q || ask.isPending) return;
    setTurns((t) => [...t, { role: "user", content: q }]);
    setInput("");
    ask.mutate(q);
  };

  const status = index.data;
  const coverage = status
    ? Math.round((status.embedded / Math.max(1, status.with_transcript)) * 100)
    : 0;

  return (
    <>
      <PageHeader
        title="Assistant"
        description="Ask about your calls, scores and compliance"
        actions={
          status && (
            <Tooltip
              content={`${status.chunks} searchable passages from ${status.embedded} calls, embedded with ${status.current_model}.`}
            >
              <Badge variant={status.stale_chunks > 0 ? "warning" : "muted"}>
                <Database className="size-2.5" />
                {coverage}% indexed
              </Badge>
            </Tooltip>
          )
        }
      />

      <div className="mx-auto flex h-[calc(100vh-3.5rem)] max-w-4xl flex-col px-6">
        <div className="flex-1 space-y-5 overflow-y-auto py-6">
          {status && status.stale_chunks > 0 && (
            <Alert variant="warning" title="Search index is out of date">
              {status.stale_chunks} passages were embedded with a different model. Vectors from
              two models do not share a coordinate space, so results will be unreliable until the
              index is rebuilt.
            </Alert>
          )}

          {turns.length === 0 && (
            <div className="pt-10">
              <div className="mb-6 text-center">
                <MessageSquareText className="mx-auto size-7 text-muted-foreground/50" />
                <h2 className="mt-3 text-lg font-semibold">Ask about your calls</h2>
                <p className="mt-1 text-xs text-muted-foreground">
                  Questions are answered from transcripts, scores, or both — every answer shows
                  where it came from.
                </p>
              </div>
              <div className="grid gap-2 sm:grid-cols-2">
                {EXAMPLES.map((e) => (
                  <button
                    key={e.q}
                    onClick={() => submit(e.q)}
                    className="group rounded-lg border border-border bg-card p-3 text-left transition-colors hover:border-primary/40 focus-ring"
                  >
                    <span className="flex items-start gap-2">
                      {e.mode === "analytical" ? (
                        <Database className="mt-0.5 size-3.5 shrink-0 text-muted-foreground" />
                      ) : (
                        <Sparkles className="mt-0.5 size-3.5 shrink-0 text-muted-foreground" />
                      )}
                      <span className="text-[13px]">{e.q}</span>
                    </span>
                  </button>
                ))}
              </div>
            </div>
          )}

          {turns.map((turn, i) => {
            if (turn.role === "user") {
              return (
                <div key={i} className="flex justify-end">
                  <div className="max-w-[80%] rounded-lg bg-primary/10 px-3.5 py-2.5 text-[13px]">
                    {turn.content}
                  </div>
                </div>
              );
            }
            if (turn.role === "error") {
              return (
                <Alert key={i} title="Could not answer that">
                  {turn.content}
                </Alert>
              );
            }
            const a = turn.answer;
            return (
              <div key={i} className="space-y-1">
                <div className="flex flex-wrap items-center gap-2">
                  <ModeBadge mode={a.retrieval_mode} />
                  {a.confidence && (
                    <Badge variant={a.confidence === "high" ? "success" : "muted"}>
                      {a.confidence} confidence
                    </Badge>
                  )}
                  <span className="text-2xs text-muted-foreground">
                    {a.model} · {formatMs(a.latency_ms)}
                  </span>
                </div>

                <Answer text={a.answer} />

                {a.sql_error && (
                  <div className="mt-2 flex items-start gap-2 rounded-md border border-warning/30 bg-warning-soft px-3 py-2">
                    <AlertTriangle className="mt-0.5 size-3.5 shrink-0 text-warning-text" />
                    <p className="text-2xs text-warning-text">
                      A query was generated but refused by the safety check: {a.sql_error}
                    </p>
                  </div>
                )}

                {a.rows.length > 0 && <ResultTable rows={a.rows} />}
                {a.generated_sql && !a.sql_error && (
                  <SqlPanel sql={a.generated_sql} rowCount={a.rows.length} />
                )}
                <Citations citations={a.citations} />
              </div>
            );
          })}

          {ask.isPending && (
            <div className="flex items-center gap-2 text-xs text-muted-foreground">
              <Loader2 className="size-3.5 animate-spin" />
              Searching transcripts and scores…
            </div>
          )}

          <div ref={endRef} />
        </div>

        <Card className="mb-6 p-2">
          <div className="flex items-end gap-2">
            <Textarea
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === "Enter" && !e.shiftKey) {
                  e.preventDefault();
                  submit(input);
                }
              }}
              rows={1}
              placeholder="Ask about agents, scores, compliance, or what customers said…"
              className="max-h-40 min-h-[38px] resize-none border-0 bg-transparent text-[13px] focus-visible:ring-0"
              disabled={ask.isPending}
            />
            <Button
              size="icon"
              onClick={() => submit(input)}
              disabled={!input.trim() || ask.isPending}
              aria-label="Send"
            >
              {ask.isPending ? <Loader2 className="animate-spin" /> : <ArrowUp />}
            </Button>
          </div>
        </Card>
      </div>
    </>
  );
}
