import { Check, Sparkles, Upload, Zap } from "lucide-react";
import type { FrameworkVersionDetail, ReprojectResult, ValidationResult } from "@/lib/api";
import { Alert } from "@/components/ui/alert";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogDescription, DialogTitle } from "@/components/ui/dialog";

export function PublishDialog({
  open,
  version,
  validation,
  busy,
  onConfirm,
  onCancel,
}: {
  open: boolean;
  version: FrameworkVersionDetail;
  validation: ValidationResult | undefined;
  busy: boolean;
  onConfirm: () => void;
  onCancel: () => void;
}) {
  const valid = validation?.is_valid ?? false;

  return (
    <Dialog open={open} onOpenChange={(o) => !o && onCancel()}>
      <DialogContent>
        <DialogTitle>Publish version {version.version_no}?</DialogTitle>
        <DialogDescription>
          This becomes the active rubric for all future evaluations. The currently published
          version is archived, not deleted — historical scores keep referencing the version they
          were computed under, so nothing already scored will change.
        </DialogDescription>

        <div className="my-4 rounded-lg border border-border p-3">
          {valid ? (
            <p className="flex items-center gap-2 text-xs text-success-text">
              <Check className="size-3.5" />
              Weights total 100% at every level.
            </p>
          ) : (
            <div className="space-y-1.5">
              {validation?.issues.map((i, n) => (
                <p key={n} className="flex gap-2 text-2xs">
                  <Badge variant="muted" className="shrink-0">
                    {i.level}
                  </Badge>
                  <span className="text-danger-text">{i.issue}</span>
                </p>
              ))}
            </div>
          )}
        </div>

        <div className="flex justify-end gap-2">
          <Button variant="outline" size="sm" onClick={onCancel}>
            Cancel
          </Button>
          <Button size="sm" onClick={onConfirm} disabled={!valid || busy}>
            <Upload />
            {busy ? "Publishing…" : "Publish"}
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}

/**
 * Shown after a successful publish.
 *
 * This dialog is where the project's central architectural claim becomes
 * visible to a user: re-weighting a rubric re-scores the entire call history
 * with ZERO AI calls, because the transcripts were already read. Only genuinely
 * new criteria need the model again. Presenting those two numbers side by side
 * is the whole point.
 */
export function ApplyDialog({
  open,
  result,
  busy,
  onApply,
  onClose,
}: {
  open: boolean;
  result: ReprojectResult | null;
  busy: boolean;
  onApply: () => void;
  onClose: () => void;
}) {
  return (
    <Dialog open={open} onOpenChange={(o) => !o && onClose()}>
      <DialogContent>
        {result ? (
          <>
            <DialogTitle>Applied to history</DialogTitle>
            <div className="my-4 space-y-2">
              <div className="flex items-start gap-3 rounded-lg border border-success/30 bg-success-soft px-4 py-3">
                <Zap className="mt-0.5 size-4 shrink-0 text-success-text" />
                <div>
                  <p className="text-sm font-semibold text-success-text">
                    {result.recomputed_instantly} evaluation
                    {result.recomputed_instantly === 1 ? "" : "s"} recomputed instantly
                  </p>
                  <p className="mt-0.5 text-xs text-success-text/80">
                    Zero AI calls, zero cost. The transcripts were already scored — only the
                    arithmetic changed.
                  </p>
                </div>
              </div>

              {result.queued_for_rescoring > 0 && (
                <div className="flex items-start gap-3 rounded-lg border border-warning/30 bg-warning-soft px-4 py-3">
                  <Sparkles className="mt-0.5 size-4 shrink-0 text-warning-text" />
                  <div>
                    <p className="text-sm font-semibold text-warning-text">
                      {result.queued_for_rescoring} queued for re-scoring
                    </p>
                    <p className="mt-0.5 text-xs text-warning-text/80">
                      This version added criteria that have never been scored on those calls, so
                      the AI must read the transcripts again. They will be processed by the worker.
                    </p>
                  </div>
                </div>
              )}
            </div>
            <div className="flex justify-end">
              <Button size="sm" onClick={onClose}>
                Done
              </Button>
            </div>
          </>
        ) : (
          <>
            <DialogTitle>Apply this rubric to existing calls?</DialogTitle>
            <DialogDescription>
              Re-weighting is instant and free — the calls have already been read, so only the
              weighted arithmetic is recomputed. Only genuinely new criteria require the AI to
              read a transcript again.
            </DialogDescription>
            <Alert variant="info" className="my-4">
              Existing evaluations will be re-projected onto this version's weights. Their
              criterion scores are not re-judged.
            </Alert>
            <div className="flex justify-end gap-2">
              <Button variant="outline" size="sm" onClick={onClose}>
                Not now
              </Button>
              <Button size="sm" onClick={onApply} disabled={busy}>
                <Zap />
                {busy ? "Applying…" : "Apply to history"}
              </Button>
            </div>
          </>
        )}
      </DialogContent>
    </Dialog>
  );
}
