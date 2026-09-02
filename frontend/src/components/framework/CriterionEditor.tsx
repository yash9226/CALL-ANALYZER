import { Plus, Trash2 } from "lucide-react";
import { useEffect, useState } from "react";
import type { Criterion, ScoringType } from "@/lib/api";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Sheet, SheetContent } from "@/components/ui/dialog";
import { Switch } from "@/components/ui/switch";
import { Textarea } from "@/components/ui/textarea";
import { cn } from "@/lib/utils";

const SCORING_LABEL: Record<ScoringType, string> = {
  binary: "Met / Not met",
  scale_5: "0 – 5",
  scale_10: "0 – 10",
  numeric: "Numeric range",
};

const Field = ({
  label,
  hint,
  children,
  className,
}: {
  label: string;
  hint?: React.ReactNode;
  children: React.ReactNode;
  className?: string;
}) => (
  <div className={cn("space-y-1.5", className)}>
    <label className="block text-xs font-medium">{label}</label>
    {children}
    {hint && <p className="text-2xs leading-relaxed text-muted-foreground">{hint}</p>}
  </div>
);

export function CriterionEditor({
  criterion,
  subsectionTotal,
  editable,
  onSave,
  onDelete,
  onClose,
}: {
  criterion: Criterion | null;
  subsectionTotal: number;
  editable: boolean;
  onSave: (patch: Partial<Criterion>) => void;
  onDelete: () => void;
  onClose: () => void;
}) {
  const [draft, setDraft] = useState<Partial<Criterion>>({});

  useEffect(() => setDraft({}), [criterion?.id]);

  if (!criterion) return null;
  const v = <K extends keyof Criterion>(key: K): Criterion[K] =>
    (draft[key] !== undefined ? draft[key] : criterion[key]) as Criterion[K];
  const set = <K extends keyof Criterion>(key: K, value: Criterion[K]) =>
    setDraft((d) => ({ ...d, [key]: value }));

  const dirty = Object.keys(draft).length > 0;

  return (
    <Sheet open={!!criterion} onOpenChange={(o) => !o && onClose()}>
      <SheetContent>
        <div className="border-b border-border px-5 py-4">
          <p className="font-mono text-2xs text-muted-foreground">{criterion.code}</p>
          <h2 className="mt-0.5 pr-8 text-base font-semibold">{criterion.name}</h2>
          {!editable && (
            <Badge variant="muted" className="mt-2">
              Read-only — this version is published
            </Badge>
          )}
        </div>

        <div className="flex-1 space-y-5 overflow-y-auto px-5 py-4">
          <Field label="Name">
            <Input
              value={v("name")}
              disabled={!editable}
              onChange={(e) => set("name", e.target.value)}
            />
          </Field>

          <Field
            label="Code"
            hint="Fixed after creation. Scores are matched across framework versions by code, so changing it would orphan every historical score for this criterion."
          >
            <Input value={criterion.code} disabled className="font-mono" />
          </Field>

          <Field label="Description" hint="What this measures, in plain language, for humans.">
            <Textarea
              rows={2}
              value={v("description") ?? ""}
              disabled={!editable}
              onChange={(e) => set("description", e.target.value)}
            />
          </Field>

          {/* The whole "configurable without code changes" claim lives in this
              one field, so it is presented as the primary control rather than
              hidden behind an advanced toggle. */}
          <Field
            label="Scoring guidance — sent to the AI"
            hint={
              <span className="text-primary">
                This text is passed to the model verbatim. Editing it changes how every
                future call is scored, with no code deployment.
              </span>
            }
          >
            <Textarea
              rows={10}
              value={v("guidance") ?? ""}
              disabled={!editable}
              onChange={(e) => set("guidance", e.target.value)}
              className="border-primary/30 bg-primary/[0.04] font-mono leading-relaxed"
              placeholder="Score 5 when… Score 3 when… Score 0 when…"
            />
            <p className="text-right text-2xs text-muted-foreground">
              {(v("guidance") ?? "").length} characters
            </p>
          </Field>

          <div className="grid grid-cols-2 gap-4">
            <Field label="Scoring type">
              <Select
                value={v("scoring_type")}
                disabled={!editable}
                onValueChange={(x) => set("scoring_type", x as ScoringType)}
              >
                <SelectTrigger className="w-full">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {(Object.keys(SCORING_LABEL) as ScoringType[]).map((k) => (
                    <SelectItem key={k} value={k}>
                      {SCORING_LABEL[k]}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </Field>

            <Field
              label="Weight"
              hint={`Sub-section currently totals ${subsectionTotal.toFixed(1)}%`}
            >
              <Input
                type="number"
                min={0}
                step="0.1"
                value={v("weight")}
                disabled={!editable}
                onChange={(e) => set("weight", Number(e.target.value))}
              />
            </Field>
          </div>

          {v("scoring_type") === "numeric" && (
            <div className="grid grid-cols-2 gap-4">
              <Field label="Minimum score">
                <Input
                  type="number"
                  value={v("min_score")}
                  disabled={!editable}
                  onChange={(e) => set("min_score", Number(e.target.value))}
                />
              </Field>
              <Field label="Maximum score">
                <Input
                  type="number"
                  value={v("max_score")}
                  disabled={!editable}
                  onChange={(e) => set("max_score", Number(e.target.value))}
                />
              </Field>
            </div>
          )}

          <div className="rounded-lg border border-danger/30 bg-danger-soft px-3.5 py-3">
            <div className="flex items-start justify-between gap-3">
              <div>
                <p className="text-xs font-semibold text-danger-text">Critical — auto-fail</p>
                <p className="mt-0.5 text-2xs leading-relaxed text-danger-text/80">
                  Failing this criterion forces the entire call score to 0%, regardless of
                  performance elsewhere. Reserve it for regulatory or policy requirements.
                </p>
              </div>
              <Switch
                checked={v("is_critical")}
                disabled={!editable}
                onCheckedChange={(c) => set("is_critical", c)}
              />
            </div>
          </div>

          <div className="rounded-lg border border-border px-3.5 py-3">
            <div className="flex items-start justify-between gap-3">
              <div>
                <p className="text-xs font-semibold">Allow "not applicable"</p>
                <p className="mt-0.5 text-2xs leading-relaxed text-muted-foreground">
                  Lets the AI mark this N/A when the situation never arose. N/A criteria are
                  removed from the weighted total rather than scored zero, so an agent is not
                  penalised for something that could not have happened.
                </p>
              </div>
              <Switch
                checked={v("allow_na")}
                disabled={!editable}
                onCheckedChange={(c) => set("allow_na", c)}
              />
            </div>
          </div>

          <div className="rounded-lg border border-border px-3.5 py-3">
            <div className="flex items-start justify-between gap-3">
              <div>
                <p className="text-xs font-semibold">Enabled</p>
                <p className="mt-0.5 text-2xs text-muted-foreground">
                  Disabled criteria are skipped entirely — never sent to the model, never billed.
                </p>
              </div>
              <Switch
                checked={v("is_enabled")}
                disabled={!editable}
                onCheckedChange={(c) => set("is_enabled", c)}
              />
            </div>
          </div>
        </div>

        {editable && (
          <div className="flex items-center justify-between gap-2 border-t border-border px-5 py-3">
            <Button variant="ghost" size="sm" onClick={onDelete} className="text-danger-text">
              <Trash2 />
              Delete
            </Button>
            <div className="flex gap-2">
              <Button variant="outline" size="sm" onClick={onClose}>
                Cancel
              </Button>
              <Button size="sm" disabled={!dirty} onClick={() => onSave(draft)}>
                Save changes
              </Button>
            </div>
          </div>
        )}
      </SheetContent>
    </Sheet>
  );
}
