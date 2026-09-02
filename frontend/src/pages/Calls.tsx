import { useQuery, keepPreviousData } from "@tanstack/react-query";
import { ChevronDown, ChevronUp, Flag, Inbox, Search, X } from "lucide-react";
import { useEffect, useMemo, useState } from "react";
import { useNavigate, useSearchParams } from "react-router-dom";
import { PageHeader } from "@/components/layout/AppLayout";
import { QueryBoundary } from "@/components/QueryBoundary";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { EmptyState } from "@/components/ui/empty";
import { Input } from "@/components/ui/input";
import { Skeleton } from "@/components/ui/skeleton";
import { Table, TBody, TD, TH, THead, TR } from "@/components/ui/table";
import { Tooltip } from "@/components/ui/tooltip";
import { api, type CallFilters, type Grade } from "@/lib/api";
import { formatDuration, formatPercent, formatRelative, scoreTextClass } from "@/lib/format";
import { cn } from "@/lib/utils";

const GRADES: Grade[] = ["A", "B", "C", "D", "F"];
const PAGE_SIZES = [25, 50, 100];

const gradeVariant = (g: Grade) =>
  ({ A: "success", B: "success", C: "warning", D: "warning", F: "danger" }) as const;

export default function Calls() {
  const [params, setParams] = useSearchParams();
  const navigate = useNavigate();

  const [searchInput, setSearchInput] = useState(params.get("search") ?? "");

  // Debounced so a search does not fire a request per keystroke.
  useEffect(() => {
    const t = setTimeout(() => {
      const next = new URLSearchParams(params);
      if (searchInput) next.set("search", searchInput);
      else next.delete("search");
      next.delete("offset");
      if (next.toString() !== params.toString()) setParams(next, { replace: true });
    }, 300);
    return () => clearTimeout(t);
  }, [searchInput]); // eslint-disable-line react-hooks/exhaustive-deps

  const filters = useMemo<CallFilters>(() => {
    const get = (k: string) => params.get(k) ?? undefined;
    return {
      limit: Number(get("limit") ?? 25),
      offset: Number(get("offset") ?? 0),
      team_id: get("team_id"),
      support_agent_id: get("support_agent_id"),
      grade: get("grade") as Grade | undefined,
      topic: get("topic"),
      search: get("search"),
      has_flags: get("has_flags") === "1" ? true : undefined,
      auto_failed: get("auto_failed") === "1" ? true : undefined,
      sort_by: (get("sort_by") ?? "started_at") as CallFilters["sort_by"],
      sort_dir: (get("sort_dir") ?? "desc") as "asc" | "desc",
    };
  }, [params]);

  const set = (key: string, value: string | undefined) => {
    const next = new URLSearchParams(params);
    if (value) next.set(key, value);
    else next.delete(key);
    if (key !== "offset") next.delete("offset"); // any filter change resets paging
    setParams(next, { replace: true });
  };

  const toggleSort = (column: NonNullable<CallFilters["sort_by"]>) => {
    const next = new URLSearchParams(params);
    if (filters.sort_by === column) {
      next.set("sort_dir", filters.sort_dir === "asc" ? "desc" : "asc");
    } else {
      next.set("sort_by", column);
      next.set("sort_dir", "desc");
    }
    setParams(next, { replace: true });
  };

  const query = useQuery({
    queryKey: ["calls", filters],
    queryFn: () => api.calls.list(filters),
    placeholderData: keepPreviousData,
  });

  const activeChips = [
    params.get("grade") && { key: "grade", label: `Grade ${params.get("grade")}` },
    params.get("topic") && { key: "topic", label: `Topic: ${params.get("topic")}` },
    params.get("has_flags") && { key: "has_flags", label: "Has flags" },
    params.get("auto_failed") && { key: "auto_failed", label: "Auto-failed" },
    params.get("support_agent_id") && { key: "support_agent_id", label: "Agent filtered" },
    params.get("team_id") && { key: "team_id", label: "Team filtered" },
  ].filter(Boolean) as { key: string; label: string }[];

  const total = query.data?.total ?? 0;
  const offset = filters.offset ?? 0;
  const limit = filters.limit ?? 25;

  const SortHead = ({
    column,
    children,
    className,
  }: {
    column: NonNullable<CallFilters["sort_by"]>;
    children: React.ReactNode;
    className?: string;
  }) => (
    <TH className={className}>
      <button
        onClick={() => toggleSort(column)}
        className="inline-flex items-center gap-1 hover:text-foreground focus-ring rounded"
      >
        {children}
        {filters.sort_by === column &&
          (filters.sort_dir === "asc" ? (
            <ChevronUp className="size-3" />
          ) : (
            <ChevronDown className="size-3" />
          ))}
      </button>
    </TH>
  );

  return (
    <>
      <PageHeader title="Calls" description={`${total} calls`} />

      <div className="space-y-4 p-6">
        <Card className="p-3">
          <div className="flex flex-wrap items-center gap-2">
            <div className="relative min-w-[260px] flex-1">
              <Search className="pointer-events-none absolute left-2.5 top-1/2 size-3.5 -translate-y-1/2 text-muted-foreground" />
              <Tooltip content="Searches inside transcript content, not just call metadata.">
                <Input
                  value={searchInput}
                  onChange={(e) => setSearchInput(e.target.value)}
                  placeholder="Search call code, agent, or transcript text…"
                  className="pl-8"
                />
              </Tooltip>
            </div>

            <div className="flex items-center gap-1">
              {GRADES.map((g) => (
                <button
                  key={g}
                  onClick={() => set("grade", params.get("grade") === g ? undefined : g)}
                  className={cn(
                    "h-8 w-8 rounded-md border text-xs font-medium transition-colors focus-ring",
                    params.get("grade") === g
                      ? "border-primary bg-primary/10 text-primary"
                      : "border-border text-muted-foreground hover:bg-accent",
                  )}
                >
                  {g}
                </button>
              ))}
            </div>

            <Button
              variant={params.get("has_flags") ? "default" : "outline"}
              size="sm"
              onClick={() => set("has_flags", params.get("has_flags") ? undefined : "1")}
            >
              <Flag />
              Has flags
            </Button>
            <Button
              variant={params.get("auto_failed") ? "destructive" : "outline"}
              size="sm"
              onClick={() => set("auto_failed", params.get("auto_failed") ? undefined : "1")}
            >
              Auto-failed
            </Button>
          </div>

          {activeChips.length > 0 && (
            <div className="mt-2 flex flex-wrap items-center gap-1.5 border-t border-border pt-2">
              {activeChips.map((c) => (
                <button
                  key={c.key}
                  onClick={() => set(c.key, undefined)}
                  className="inline-flex items-center gap-1 rounded-full bg-secondary px-2 py-0.5 text-2xs hover:bg-accent focus-ring"
                >
                  {c.label}
                  <X className="size-2.5" />
                </button>
              ))}
              <Button
                variant="ghost"
                size="xs"
                onClick={() => setParams(new URLSearchParams(), { replace: true })}
              >
                Clear all
              </Button>
            </div>
          )}
        </Card>

        <Card>
          <QueryBoundary
            isLoading={query.isLoading}
            error={query.error}
            onRetry={query.refetch}
            skeleton={
              <div className="space-y-1 p-3">
                {Array.from({ length: 10 }, (_, i) => (
                  <Skeleton key={i} className="h-11 w-full" />
                ))}
              </div>
            }
          >
            {query.data && query.data.items.length === 0 ? (
              <EmptyState
                icon={Inbox}
                title={activeChips.length || filters.search ? "No calls match these filters" : "No calls yet"}
                description={
                  activeChips.length || filters.search
                    ? "Try widening the date range or clearing a filter."
                    : "Ingest calls to see them here."
                }
                action={
                  (activeChips.length > 0 || filters.search) && (
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => {
                        setSearchInput("");
                        setParams(new URLSearchParams(), { replace: true });
                      }}
                    >
                      Clear filters
                    </Button>
                  )
                }
              />
            ) : (
              <Table>
                <THead>
                  <TR>
                    <SortHead column="started_at">Call</SortHead>
                    <SortHead column="agent">Agent</SortHead>
                    <TH>Team</TH>
                    <SortHead column="duration" className="text-right">
                      Duration
                    </SortHead>
                    <SortHead column="score" className="text-right">
                      Score
                    </SortHead>
                    <SortHead column="sentiment">Sentiment</SortHead>
                    <TH className="text-right">Flags</TH>
                    <TH>Summary</TH>
                  </TR>
                </THead>
                <TBody>
                  {query.data?.items.map((c) => (
                    <TR
                      key={c.call_id}
                      onClick={() => navigate(`/calls/${c.call_id}`)}
                      className="cursor-pointer hover:bg-accent/50"
                    >
                      <TD>
                        <p className="font-mono text-xs">{c.call_code}</p>
                        <p className="text-2xs text-muted-foreground">
                          {formatRelative(c.started_at)}
                        </p>
                      </TD>
                      <TD>
                        <p className="font-medium">{c.agent_name ?? "—"}</p>
                        <p className="font-mono text-2xs text-muted-foreground">{c.agent_code}</p>
                      </TD>
                      <TD>
                        <Badge variant="outline">{c.team_name ?? "—"}</Badge>
                      </TD>
                      <TD className="tabular text-right text-muted-foreground">
                        {formatDuration(c.duration_seconds)}
                      </TD>
                      <TD className="text-right">
                        {c.auto_fail_triggered ? (
                          <Badge variant="solid-danger">AUTO-FAIL</Badge>
                        ) : c.score_percentage === null ? (
                          <span className="text-muted-foreground">—</span>
                        ) : (
                          <span className="inline-flex items-center gap-1.5">
                            <span
                              className={cn(
                                "tabular text-base font-bold",
                                scoreTextClass(c.score_percentage),
                              )}
                            >
                              {formatPercent(c.score_percentage, 0)}
                            </span>
                            {c.grade && <Badge variant={gradeVariant(c.grade)[c.grade]}>{c.grade}</Badge>}
                          </span>
                        )}
                      </TD>
                      <TD>
                        {c.sentiment_delta === null ? (
                          <span className="text-muted-foreground">—</span>
                        ) : (
                          <span
                            className={cn(
                              "tabular text-xs",
                              c.sentiment_delta > 0 ? "text-success-text" : "text-muted-foreground",
                            )}
                          >
                            {c.sentiment_delta > 0 ? "↑" : "↓"} {Math.abs(c.sentiment_delta).toFixed(2)}
                          </span>
                        )}
                      </TD>
                      <TD className="text-right">
                        {c.flag_count > 0 && (
                          <Badge variant={c.critical_flag_count > 0 ? "solid-danger" : "warning"}>
                            {c.flag_count}
                          </Badge>
                        )}
                      </TD>
                      <TD className="max-w-[280px]">
                        <p className="truncate text-xs text-muted-foreground">{c.headline ?? "—"}</p>
                      </TD>
                    </TR>
                  ))}
                </TBody>
              </Table>
            )}
          </QueryBoundary>

          {total > 0 && (
            <div className="flex flex-wrap items-center justify-between gap-3 border-t border-border px-4 py-3">
              <p className="text-xs text-muted-foreground">
                Showing {offset + 1}–{Math.min(offset + limit, total)} of {total}
              </p>
              <div className="flex items-center gap-2">
                <div className="flex gap-1">
                  {PAGE_SIZES.map((n) => (
                    <button
                      key={n}
                      onClick={() => set("limit", String(n))}
                      className={cn(
                        "rounded px-1.5 py-0.5 text-2xs transition-colors",
                        limit === n
                          ? "bg-secondary font-medium"
                          : "text-muted-foreground hover:text-foreground",
                      )}
                    >
                      {n}
                    </button>
                  ))}
                </div>
                <Button
                  variant="outline"
                  size="sm"
                  disabled={offset === 0}
                  onClick={() => set("offset", String(Math.max(0, offset - limit)))}
                >
                  Previous
                </Button>
                <Button
                  variant="outline"
                  size="sm"
                  disabled={offset + limit >= total}
                  onClick={() => set("offset", String(offset + limit))}
                >
                  Next
                </Button>
              </div>
            </div>
          )}
        </Card>
      </div>
    </>
  );
}
