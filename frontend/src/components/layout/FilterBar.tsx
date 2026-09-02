import { useQuery } from "@tanstack/react-query";
import { RotateCcw } from "lucide-react";
import { DATE_PRESETS, useFilters } from "@/hooks/useFilters";
import { api } from "@/lib/api";
import { Button } from "@/components/ui/button";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";

const ALL = "__all__";

export function FilterBar() {
  const { preset, teamId, agentId, setFilter, reset, isActive, filters } = useFilters();

  const { data: teams } = useQuery({ queryKey: ["teams"], queryFn: () => api.teams.list() });

  // The agent list is itself filtered by the selected team, so the dropdown
  // never offers an agent whose calls the current team filter would exclude.
  const { data: agents } = useQuery({
    queryKey: ["agents-filter", teamId],
    queryFn: () => api.analytics.agents({ ...filters, support_agent_id: undefined, limit: 200 }),
  });

  return (
    <div className="flex flex-wrap items-center gap-2">
      <Select value={preset} onValueChange={(v) => setFilter("preset", v === "6w" ? undefined : v)}>
        <SelectTrigger className="w-[140px]">
          <SelectValue />
        </SelectTrigger>
        <SelectContent>
          {DATE_PRESETS.map((p) => (
            <SelectItem key={p.key} value={p.key}>
              {p.label}
            </SelectItem>
          ))}
        </SelectContent>
      </Select>

      <Select
        value={teamId ?? ALL}
        onValueChange={(v) => setFilter("team_id", v === ALL ? undefined : v)}
      >
        <SelectTrigger className="w-[160px]">
          <SelectValue placeholder="All teams" />
        </SelectTrigger>
        <SelectContent>
          <SelectItem value={ALL}>All teams</SelectItem>
          {teams?.map((t) => (
            <SelectItem key={t.id} value={t.id}>
              {t.name}
            </SelectItem>
          ))}
        </SelectContent>
      </Select>

      <Select
        value={agentId ?? ALL}
        onValueChange={(v) => setFilter("support_agent_id", v === ALL ? undefined : v)}
      >
        <SelectTrigger className="w-[160px]">
          <SelectValue placeholder="All agents" />
        </SelectTrigger>
        <SelectContent>
          <SelectItem value={ALL}>All agents</SelectItem>
          {agents?.map((a) => (
            <SelectItem key={a.support_agent_id} value={a.support_agent_id}>
              {a.agent_name}
            </SelectItem>
          ))}
        </SelectContent>
      </Select>

      {isActive && (
        <Button variant="ghost" size="sm" onClick={reset} className="text-muted-foreground">
          <RotateCcw />
          Reset
        </Button>
      )}
    </div>
  );
}
