import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import { CriterionEditor } from "@/components/framework/CriterionEditor";
import { FrameworkTree } from "@/components/framework/FrameworkTree";
import { ApplyDialog, PublishDialog } from "@/components/framework/PublishDialog";
import { VersionBar } from "@/components/framework/VersionBar";
import { QueryBoundary } from "@/components/QueryBoundary";
import { Alert } from "@/components/ui/alert";
import { Skeleton } from "@/components/ui/skeleton";
import { useToast } from "@/components/ui/toast";
import {
  ApiError,
  api,
  type Criterion,
  type ReprojectResult,
  type Section,
  type Subsection,
} from "@/lib/api";

export default function Admin() {
  const qc = useQueryClient();
  const toast = useToast();

  // null means "whatever is published"; set when the user opens a specific
  // version from the history dropdown.
  const [versionId, setVersionId] = useState<string | null>(null);
  const [editing, setEditing] = useState<{ criterion: Criterion; subsectionTotal: number } | null>(null);
  const [publishOpen, setPublishOpen] = useState(false);
  const [applyOpen, setApplyOpen] = useState(false);
  const [applyResult, setApplyResult] = useState<ReprojectResult | null>(null);

  const framework = useQuery({
    queryKey: ["framework", versionId],
    queryFn: () => (versionId ? api.framework.get(versionId) : api.framework.active()),
  });

  const versions = useQuery({
    queryKey: ["framework-versions"],
    queryFn: () => api.framework.versions(),
  });

  const current = framework.data;
  const isDraft = current?.status === "draft";

  // A draft can already exist from an earlier session. Without surfacing it,
  // the user sees the published version, clicks "Edit framework", and is
  // silently dropped into someone else's half-finished draft. Naming it up
  // front makes that explicit.
  const existingDraft = versions.data?.find((v) => v.status === "draft");
  const draftAwaitingAttention = !isDraft && existingDraft;

  // Validation is only meaningful while editing, and it is re-fetched after
  // every mutation so imbalance shows the moment it is introduced rather than
  // being discovered at publish time.
  const validation = useQuery({
    queryKey: ["framework-validate", current?.id],
    queryFn: () => api.framework.validate(current!.id),
    enabled: !!current?.id,
  });

  const refresh = async () => {
    await qc.invalidateQueries({ queryKey: ["framework"] });
    await qc.invalidateQueries({ queryKey: ["framework-validate"] });
    await qc.invalidateQueries({ queryKey: ["framework-versions"] });
  };

  /** Surfaces a 409 verbatim: the backend writes those sentences for humans,
   *  and they name the exact rule that refused the request. */
  const onError = (e: unknown) =>
    toast({
      variant: "danger",
      title: e instanceof ApiError && e.isConflict ? "Cannot make this change" : "Something failed",
      body: e instanceof ApiError ? e.message : String(e),
    });

  // Every mutation shares the same success/error handling. It is written out
  // rather than produced by a helper that calls useMutation: hooks must be
  // called unconditionally and in a stable order, and a factory hides that
  // requirement behind a function call where it is easy to break later.
  const mutationOptions = (success?: string) => ({
    onSuccess: async () => {
      await refresh();
      if (success) toast({ variant: "success", title: success });
    },
    onError,
  });

  const patchSection = useMutation({
    mutationFn: (v: { id: string; patch: Partial<Section> }) =>
      api.framework.updateSection(v.id, v.patch),
    ...mutationOptions(),
  });
  const patchSubsection = useMutation({
    mutationFn: (v: { id: string; patch: Partial<Subsection> }) =>
      api.framework.updateSubsection(v.id, v.patch),
    ...mutationOptions(),
  });
  const patchCriterion = useMutation({
    mutationFn: (v: { id: string; patch: Partial<Criterion> }) =>
      api.framework.updateCriterion(v.id, v.patch),
    ...mutationOptions(),
  });
  const deleteSection = useMutation({
    mutationFn: (id: string) => api.framework.deleteSection(id),
    ...mutationOptions("Section deleted"),
  });
  const deleteSubsection = useMutation({
    mutationFn: (id: string) => api.framework.deleteSubsection(id),
    ...mutationOptions("Sub-section deleted"),
  });
  const deleteCriterion = useMutation({
    mutationFn: (id: string) => api.framework.deleteCriterion(id),
    ...mutationOptions("Criterion deleted"),
  });

  const startEditing = useMutation({
    mutationFn: () => api.framework.draft(),
    onSuccess: async (draft) => {
      setVersionId(draft.id);
      await refresh();
      toast({
        variant: "info",
        title: `Editing draft v${draft.version_no}`,
        body: "The published version is untouched until you publish this draft.",
      });
    },
    onError,
  });

  const normalize = useMutation({
    mutationFn: () => api.framework.normalize(current!.id),
    onSuccess: async () => {
      await refresh();
      toast({
        variant: "success",
        title: "Weights rebalanced",
        body: "Enabled siblings now total 100% at every level, keeping their proportions.",
      });
    },
    onError,
  });

  const publish = useMutation({
    mutationFn: () => api.framework.publish(current!.id),
    onSuccess: async (res) => {
      setPublishOpen(false);
      await refresh();
      toast({ variant: "success", title: "Published", body: res.message });
      // The apply step is offered immediately, because a newly published rubric
      // that has not been applied leaves the dashboard showing old weights.
      setApplyResult(null);
      setApplyOpen(true);
    },
    onError: (e) => {
      setPublishOpen(false);
      onError(e);
    },
  });

  const applyToHistory = useMutation({
    mutationFn: () => api.framework.apply(current!.id),
    onSuccess: async (res) => {
      setApplyResult(res);
      await qc.invalidateQueries();
    },
    onError,
  });

  const busy =
    patchSection.isPending ||
    patchSubsection.isPending ||
    patchCriterion.isPending ||
    normalize.isPending ||
    publish.isPending ||
    startEditing.isPending;

  return (
    <>
      {current && (
        <VersionBar
          version={current}
          validation={validation.data}
          versions={versions.data}
          isDraft={!!isDraft}
          busy={busy}
          onEdit={() => startEditing.mutate()}
          onNormalize={() => normalize.mutate()}
          onPublish={() => setPublishOpen(true)}
          onSelectVersion={(id) => setVersionId(id)}
        />
      )}

      <div className="space-y-4 p-6">
        {draftAwaitingAttention && (
          <Alert variant="warning" title={`Draft v${existingDraft.version_no} is in progress`}>
            <span className="flex flex-wrap items-center gap-2">
              <span>
                Someone has already started editing. Continue that draft rather than starting
                another — only one draft exists at a time.
              </span>
              <button
                onClick={() => setVersionId(existingDraft.id)}
                className="font-medium underline underline-offset-2 focus-ring rounded"
              >
                Open draft v{existingDraft.version_no}
              </button>
            </span>
          </Alert>
        )}

        {!isDraft && current && (
          <Alert variant="info">
            This version is <strong>{current.status}</strong> and cannot be edited. The database
            enforces that, not just the interface — published rubrics are immutable so every
            historical score stays interpretable. Choose <strong>Edit framework</strong> to work on
            a draft copy.
          </Alert>
        )}

        <QueryBoundary
          isLoading={framework.isLoading}
          error={framework.error}
          onRetry={framework.refetch}
          skeleton={
            <div className="space-y-2">
              {Array.from({ length: 5 }, (_, i) => (
                <Skeleton key={i} className="h-20 w-full" />
              ))}
            </div>
          }
        >
          {current && (
            <FrameworkTree
              framework={current}
              editable={!!isDraft}
              onPatchSection={(id, patch) => patchSection.mutate({ id, patch })}
              onPatchSubsection={(id, patch) => patchSubsection.mutate({ id, patch })}
              onPatchCriterion={(id, patch) => patchCriterion.mutate({ id, patch })}
              onOpenCriterion={(criterion, subsectionTotal) =>
                setEditing({ criterion, subsectionTotal })
              }
              onDeleteSection={(s) =>
                confirm(`Delete section "${s.name}" and everything beneath it?`) &&
                deleteSection.mutate(s.id)
              }
              onDeleteSubsection={(s) =>
                confirm(`Delete sub-section "${s.name}" and its criteria?`) &&
                deleteSubsection.mutate(s.id)
              }
            />
          )}
        </QueryBoundary>
      </div>

      <CriterionEditor
        criterion={editing?.criterion ?? null}
        subsectionTotal={editing?.subsectionTotal ?? 0}
        editable={!!isDraft}
        onClose={() => setEditing(null)}
        onSave={(patch) => {
          patchCriterion.mutate({ id: editing!.criterion.id, patch });
          setEditing(null);
        }}
        onDelete={() => {
          if (confirm(`Delete criterion "${editing!.criterion.name}"?`)) {
            deleteCriterion.mutate(editing!.criterion.id);
            setEditing(null);
          }
        }}
      />

      {current && (
        <>
          <PublishDialog
            open={publishOpen}
            version={current}
            validation={validation.data}
            busy={publish.isPending}
            onConfirm={() => publish.mutate()}
            onCancel={() => setPublishOpen(false)}
          />
          <ApplyDialog
            open={applyOpen}
            result={applyResult}
            busy={applyToHistory.isPending}
            onApply={() => applyToHistory.mutate()}
            onClose={() => {
              setApplyOpen(false);
              setApplyResult(null);
            }}
          />
        </>
      )}
    </>
  );
}
