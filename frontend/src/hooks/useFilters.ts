/**
 * Global dashboard filters, held in the URL query string.
 *
 * The URL is the source of truth rather than React state, so a filtered view can
 * be copied, bookmarked and shared — which is how managers actually pass
 * findings to each other ("look at Fatima's last 7 days").
 */

import { useCallback, useMemo } from "react";
import { useSearchParams } from "react-router-dom";
import type { AnalyticsFilters } from "@/lib/api";

export const DATE_PRESETS = [
  { key: "7d", label: "Last 7 days", days: 7 },
  { key: "30d", label: "Last 30 days", days: 30 },
  { key: "6w", label: "Last 6 weeks", days: 42 },
  { key: "all", label: "All time", days: null },
] as const;

export type PresetKey = (typeof DATE_PRESETS)[number]["key"];

export interface Filters extends AnalyticsFilters {
  preset: PresetKey;
}

export function useFilters() {
  const [params, setParams] = useSearchParams();

  // Default to 6 weeks: the seeded corpus spans exactly that, so a new user
  // lands on a populated dashboard rather than an empty one.
  const preset = (params.get("preset") ?? "6w") as PresetKey;
  const teamId = params.get("team_id") ?? undefined;
  const agentId = params.get("support_agent_id") ?? undefined;

  const filters = useMemo<AnalyticsFilters>(() => {
    const chosen = DATE_PRESETS.find((p) => p.key === preset) ?? DATE_PRESETS[2];
    const out: AnalyticsFilters = { team_id: teamId, support_agent_id: agentId };
    if (chosen.days !== null) {
      const from = new Date();
      from.setDate(from.getDate() - chosen.days);
      out.date_from = from.toISOString();
    }
    return out;
  }, [preset, teamId, agentId]);

  const setFilter = useCallback(
    (key: string, value: string | undefined) => {
      const next = new URLSearchParams(params);
      if (value) next.set(key, value);
      else next.delete(key);
      // Changing the team invalidates the agent selection — an agent from
      // another team would silently return zero results.
      if (key === "team_id") next.delete("support_agent_id");
      setParams(next, { replace: true });
    },
    [params, setParams],
  );

  const reset = useCallback(() => setParams(new URLSearchParams(), { replace: true }), [setParams]);

  const isActive = preset !== "6w" || !!teamId || !!agentId;

  return { filters, preset, teamId, agentId, setFilter, reset, isActive };
}
