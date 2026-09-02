import { ChevronRight, Plus, Trash2 } from "lucide-react";
import { useState } from "react";
import type { Criterion, FrameworkVersionDetail, Section, Subsection } from "@/lib/api";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Switch } from "@/components/ui/switch";
import { Tooltip } from "@/components/ui/tooltip";
import { cn } from "@/lib/utils";
import { WeightInput, WeightSum } from "./WeightInput";

const SCORING_CHIP: Record<string, string> = {
  binary: "Met / Not met",
  scale_5: "0–5",
  scale_10: "0–10",
  numeric: "Numeric",
};

/** Only ENABLED children count toward the total. Disabling a node removes it
 *  from both scoring and the weight denominator, so including it here would
 *  report a balanced tree as broken. */
const enabledTotal = (items: { weight: number; is_enabled: boolean }[]) =>
  items.filter((i) => i.is_enabled).reduce((sum, i) => sum + i.weight, 0);

export function FrameworkTree({
  framework,
  editable,
  onPatchSection,
  onPatchSubsection,
  onPatchCriterion,
  onOpenCriterion,
  onDeleteSection,
  onDeleteSubsection,
}: {
  framework: FrameworkVersionDetail;
  editable: boolean;
  onPatchSection: (id: string, patch: Partial<Section>) => void;
  onPatchSubsection: (id: string, patch: Partial<Subsection>) => void;
  onPatchCriterion: (id: string, patch: Partial<Criterion>) => void;
  onOpenCriterion: (c: Criterion, subsectionTotal: number) => void;
  onDeleteSection: (s: Section) => void;
  onDeleteSubsection: (s: Subsection) => void;
}) {
  const [collapsed, setCollapsed] = useState<Set<string>>(new Set());
  const toggle = (id: string) =>
    setCollapsed((prev) => {
      const next = new Set(prev);
      next.has(id) ? next.delete(id) : next.add(id);
      return next;
    });

  const sectionTotal = enabledTotal(framework.sections);

  return (
    <div className="space-y-2">
      <div className="flex items-center justify-between px-1 pb-1">
        <p className="text-2xs uppercase tracking-wide text-muted-foreground">
          Sections — weights must total 100%
        </p>
        <WeightSum total={sectionTotal} label="total" />
      </div>

      {framework.sections.map((section) => {
        const isCollapsed = collapsed.has(section.id);
        const subTotal = enabledTotal(section.subsections);

        return (
          <div
            key={section.id}
            className={cn(
              "rounded-lg border border-border bg-card",
              !section.is_enabled && "opacity-50",
            )}
          >
            {/* ── Section row ── */}
            <div className="flex items-center gap-2 border-l-[3px] border-l-chart-1 px-3 py-2.5">
              <button
                onClick={() => toggle(section.id)}
                className="shrink-0 text-muted-foreground focus-ring rounded"
                aria-label={isCollapsed ? "Expand" : "Collapse"}
              >
                <ChevronRight
                  className={cn("size-4 transition-transform", !isCollapsed && "rotate-90")}
                />
              </button>

              <div className="min-w-0 flex-1">
                <div className="flex items-center gap-2">
                  <span className="text-sm font-semibold">{section.name}</span>
                  <span className="font-mono text-2xs text-muted-foreground">{section.code}</span>
                  {!section.is_enabled && <Badge variant="muted">Disabled</Badge>}
                </div>
                <p className="text-2xs text-muted-foreground">
                  {section.subsections.length} sub-sections ·{" "}
                  {section.subsections.reduce((n, s) => n + s.criteria.length, 0)} criteria
                </p>
              </div>

              <WeightSum total={subTotal} />
              <WeightInput
                value={section.weight}
                disabled={!editable}
                onCommit={(w) => onPatchSection(section.id, { weight: w })}
              />
              <Tooltip content={section.is_enabled ? "Disable this section" : "Enable this section"}>
                <span>
                  <Switch
                    checked={section.is_enabled}
                    disabled={!editable}
                    onCheckedChange={(c) => onPatchSection(section.id, { is_enabled: c })}
                  />
                </span>
              </Tooltip>
              {editable && (
                <Button
                  variant="ghost"
                  size="icon-sm"
                  onClick={() => onDeleteSection(section)}
                  className="text-muted-foreground hover:text-danger-text"
                  aria-label="Delete section"
                >
                  <Trash2 />
                </Button>
              )}
            </div>

            {/* ── Sub-sections ── */}
            {!isCollapsed && (
              <div className="space-y-1.5 border-t border-border px-3 py-2">
                {section.subsections.map((sub) => {
                  const subCollapsed = collapsed.has(sub.id);
                  const critTotal = enabledTotal(sub.criteria);

                  return (
                    <div key={sub.id} className={cn(!sub.is_enabled && "opacity-50")}>
                      <div className="flex items-center gap-2 border-l-2 border-l-chart-2 py-1.5 pl-3">
                        <button
                          onClick={() => toggle(sub.id)}
                          className="shrink-0 text-muted-foreground focus-ring rounded"
                        >
                          <ChevronRight
                            className={cn(
                              "size-3.5 transition-transform",
                              !subCollapsed && "rotate-90",
                            )}
                          />
                        </button>
                        <div className="min-w-0 flex-1">
                          <span className="flex items-center gap-2">
                            <span className="text-[13px] font-medium">{sub.name}</span>
                            <span className="font-mono text-2xs text-muted-foreground">
                              {sub.code}
                            </span>
                          </span>
                          <p className="text-2xs text-muted-foreground">
                            {sub.criteria.length} criteria
                          </p>
                        </div>
                        <WeightSum total={critTotal} />
                        <WeightInput
                          value={sub.weight}
                          disabled={!editable}
                          onCommit={(w) => onPatchSubsection(sub.id, { weight: w })}
                        />
                        <Switch
                          checked={sub.is_enabled}
                          disabled={!editable}
                          onCheckedChange={(c) => onPatchSubsection(sub.id, { is_enabled: c })}
                        />
                        {editable && (
                          <Button
                            variant="ghost"
                            size="icon-sm"
                            onClick={() => onDeleteSubsection(sub)}
                            className="text-muted-foreground hover:text-danger-text"
                            aria-label="Delete sub-section"
                          >
                            <Trash2 />
                          </Button>
                        )}
                      </div>

                      {/* ── Criteria ── */}
                      {!subCollapsed && (
                        <div className="space-y-0.5 py-1 pl-9">
                          {sub.criteria.map((c) => (
                            <div
                              key={c.id}
                              className={cn(
                                "group flex items-center gap-2 rounded-md px-2 py-1.5 hover:bg-accent/60",
                                !c.is_enabled && "opacity-50",
                              )}
                            >
                              <button
                                onClick={() => onOpenCriterion(c, critTotal)}
                                className="flex min-w-0 flex-1 items-center gap-2 text-left focus-ring rounded"
                              >
                                <span className="truncate text-[13px]">{c.name}</span>
                                {c.is_critical && <Badge variant="solid-danger">CRITICAL</Badge>}
                                {c.allow_na && (
                                  <Tooltip content="The AI may mark this not applicable">
                                    <Badge variant="muted">N/A ok</Badge>
                                  </Tooltip>
                                )}
                              </button>
                              <Badge variant="outline" className="shrink-0">
                                {SCORING_CHIP[c.scoring_type]}
                              </Badge>
                              <WeightInput
                                value={c.weight}
                                disabled={!editable}
                                onCommit={(w) => onPatchCriterion(c.id, { weight: w })}
                              />
                              <Switch
                                checked={c.is_enabled}
                                disabled={!editable}
                                onCheckedChange={(x) => onPatchCriterion(c.id, { is_enabled: x })}
                              />
                            </div>
                          ))}
                        </div>
                      )}
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        );
      })}
    </div>
  );
}
