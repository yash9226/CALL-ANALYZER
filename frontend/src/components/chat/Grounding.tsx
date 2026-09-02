import { ChevronDown, Code2, Database, ExternalLink, Search, Sparkles } from "lucide-react";
import { useState } from "react";
import { Link } from "react-router-dom";
import type { ChatCitation, RetrievalMode } from "@/lib/api";
import { formatPercent, scoreTextClass } from "@/lib/format";
import { Badge } from "@/components/ui/badge";
import { Tooltip } from "@/components/ui/tooltip";
import { cn } from "@/lib/utils";

const MODE: Record<RetrievalMode, { label: string; icon: typeof Search; hint: string }> = {
  semantic: {
    label: "Transcript search",
    icon: Search,
    hint: "Answered by searching what was actually said inside calls.",
  },
  analytical: {
    label: "Data query",
    icon: Database,
    hint: "Answered by aggregating across calls. This answer exists in no single transcript.",
  },
  hybrid: {
    label: "Query + transcripts",
    icon: Sparkles,
    hint: "Needed both an aggregate and supporting examples.",
  },
};

export function ModeBadge({ mode }: { mode: RetrievalMode }) {
  const { label, icon: Icon, hint } = MODE[mode] ?? MODE.semantic;
  return (
    <Tooltip content={hint}>
      <Badge variant="primary">
        <Icon className="size-2.5" />
        {label}
      </Badge>
    </Tooltip>
  );
}

/**
 * The SQL panel is the anti-hallucination affordance for analytical answers.
 *
 * A manager cannot verify "Fatima Sheikh averaged 7% on empathy" by reading a
 * transcript — the number is an aggregate. Showing the query that produced it
 * is the only way to make it checkable, and an uncheckable number in a
 * quality-assurance tool is worse than no number at all.
 */
export function SqlPanel({ sql, rowCount }: { sql: string; rowCount: number }) {
  const [open, setOpen] = useState(false);
  return (
    <div className="mt-3 rounded-md border border-border">
      <button
        onClick={() => setOpen((o) => !o)}
        className="flex w-full items-center gap-2 px-3 py-2 text-left focus-ring rounded-md"
      >
        <Code2 className="size-3.5 shrink-0 text-muted-foreground" />
        <span className="flex-1 text-xs font-medium">How I calculated this</span>
        <span className="text-2xs text-muted-foreground">
          {rowCount} row{rowCount === 1 ? "" : "s"}
        </span>
        <ChevronDown className={cn("size-3.5 transition-transform", open && "rotate-180")} />
      </button>
      {open && (
        <pre className="whitespace-pre-wrap break-words border-t border-border bg-muted/50 px-3 py-2.5 text-2xs leading-relaxed">
          <code className="font-mono">{sql}</code>
        </pre>
      )}
    </div>
  );
}

export function Citations({ citations }: { citations: ChatCitation[] }) {
  if (!citations.length) return null;
  return (
    <div className="mt-3">
      <p className="mb-1.5 text-2xs text-muted-foreground">
        Based on {citations.length} call{citations.length === 1 ? "" : "s"}
      </p>
      <div className="flex gap-2 overflow-x-auto pb-1">
        {citations.map((c, i) => (
          <Link
            key={`${c.call_id}-${i}`}
            to={`/calls/${c.call_id}`}
            className="group w-64 shrink-0 rounded-md border border-border bg-card p-2.5 transition-colors hover:border-primary/40 focus-ring"
          >
            <div className="flex items-center justify-between gap-2">
              <span className="truncate font-mono text-2xs">{c.call_code}</span>
              {c.score_percentage !== null && (
                <span className={cn("tabular text-2xs font-semibold", scoreTextClass(c.score_percentage))}>
                  {formatPercent(c.score_percentage, 0)}
                </span>
              )}
            </div>
            <p className="mt-0.5 truncate text-2xs text-muted-foreground">
              {c.agent_name} · turns {c.turn_start}–{c.turn_end}
            </p>
            <p className="mt-1.5 line-clamp-3 text-2xs leading-relaxed text-muted-foreground">
              {c.excerpt}
            </p>
            <span className="mt-1.5 inline-flex items-center gap-1 text-2xs text-primary opacity-0 transition-opacity group-hover:opacity-100">
              Open call <ExternalLink className="size-2.5" />
            </span>
          </Link>
        ))}
      </div>
    </div>
  );
}

/** Aggregate results as a table. Numbers a manager can scan beat a paragraph
 *  that describes them. */
export function ResultTable({ rows }: { rows: Array<Record<string, unknown>> }) {
  if (!rows.length) return null;
  const columns = Object.keys(rows[0]);

  const format = (v: unknown) => {
    if (v === null || v === undefined) return "—";
    if (typeof v === "number") return Number.isInteger(v) ? v : v.toFixed(1);
    return String(v);
  };

  return (
    <div className="mt-3 overflow-x-auto rounded-md border border-border">
      <table className="w-full text-2xs">
        <thead className="border-b border-border bg-muted/50">
          <tr>
            {columns.map((c) => (
              <th key={c} className="px-2.5 py-1.5 text-left font-medium uppercase tracking-wide text-muted-foreground">
                {c.replace(/_/g, " ")}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.slice(0, 12).map((r, i) => (
            <tr key={i} className="border-b border-border last:border-0">
              {columns.map((c) => (
                <td key={c} className="tabular px-2.5 py-1.5">
                  {format(r[c])}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
      {rows.length > 12 && (
        <p className="px-2.5 py-1.5 text-2xs text-muted-foreground">
          {rows.length - 12} more row{rows.length - 12 === 1 ? "" : "s"} not shown
        </p>
      )}
    </div>
  );
}
