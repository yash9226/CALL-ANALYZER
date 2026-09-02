/**
 * Display formatting and the score colour rule.
 *
 * Everything visual that depends on a score routes through here, so the banding
 * cannot drift between the dashboard, the call list and the drill-down.
 */

import { format, formatDistanceToNow, parseISO } from "date-fns";
import type { Grade } from "./api";

/** score >= 80 success · 60-79 warning · < 60 danger */
export type ScoreBand = "success" | "warning" | "danger" | "muted";

export function scoreBand(score: number | null | undefined): ScoreBand {
  if (score === null || score === undefined) return "muted";
  if (score >= 80) return "success";
  if (score >= 60) return "warning";
  return "danger";
}

/** Text colour for a score. Uses the -text variants, which are darkened to pass
 *  WCAG AA — the base fills measure 2.6:1 and 2.1:1 on white and are unreadable
 *  as small text. */
export const scoreTextClass = (score: number | null | undefined) =>
  ({
    success: "text-success-text",
    warning: "text-warning-text",
    danger: "text-danger-text",
    muted: "text-muted-foreground",
  })[scoreBand(score)];

/** Fill colour for bars and chart marks, where contrast-as-text does not apply. */
export const scoreFillClass = (score: number | null | undefined) =>
  ({
    success: "bg-success",
    warning: "bg-warning",
    danger: "bg-danger",
    muted: "bg-muted-foreground/30",
  })[scoreBand(score)];

export const scoreHex = (score: number | null | undefined) =>
  ({
    success: "hsl(var(--success))",
    warning: "hsl(var(--warning))",
    danger: "hsl(var(--danger))",
    muted: "hsl(var(--muted-foreground))",
  })[scoreBand(score)];

export function formatPercent(value: number | null | undefined, digits = 1): string {
  if (value === null || value === undefined) return "—";
  return `${value.toFixed(digits)}%`;
}

export function formatNumber(value: number | null | undefined): string {
  if (value === null || value === undefined) return "—";
  return value.toLocaleString();
}

export function formatSigned(value: number | null | undefined, digits = 2): string {
  if (value === null || value === undefined) return "—";
  return `${value >= 0 ? "+" : ""}${value.toFixed(digits)}`;
}

export function formatDuration(seconds: number | null | undefined): string {
  if (seconds === null || seconds === undefined) return "—";
  const m = Math.floor(seconds / 60);
  const s = Math.round(seconds % 60);
  return `${m}m ${String(s).padStart(2, "0")}s`;
}

export function formatMs(ms: number | null | undefined): string {
  if (ms === null || ms === undefined) return "—";
  if (ms < 1000) return `${ms}ms`;
  return `${(ms / 1000).toFixed(1)}s`;
}

export function formatDate(iso: string | null | undefined): string {
  if (!iso) return "—";
  try {
    return format(parseISO(iso), "d MMM, HH:mm");
  } catch {
    return "—";
  }
}

export function formatRelative(iso: string | null | undefined): string {
  if (!iso) return "—";
  try {
    return formatDistanceToNow(parseISO(iso), { addSuffix: true });
  } catch {
    return "—";
  }
}

/** billing_dispute -> Billing dispute */
export function humanise(value: string | null | undefined): string {
  if (!value) return "—";
  const spaced = value.replace(/_/g, " ");
  return spaced.charAt(0).toUpperCase() + spaced.slice(1);
}

export const GRADE_LABEL: Record<Grade, string> = {
  A: "Excellent",
  B: "Good",
  C: "Satisfactory",
  D: "Needs improvement",
  F: "Unsatisfactory",
};

/** Explains a trigger_reason in the terms a manager cares about: did the score
 *  change because the agent improved, or because we changed the rubric? */
export const TRIGGER_LABEL: Record<string, string> = {
  initial: "Initial evaluation",
  framework_change: "Rubric changed",
  manual_rerun: "Manual re-run",
  model_upgrade: "Model upgraded",
  reevaluate: "Re-evaluated",
  evaluate: "Evaluated",
};

export const SEVERITY_ORDER = ["critical", "high", "medium", "low"] as const;
