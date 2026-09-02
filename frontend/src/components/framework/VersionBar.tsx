import { AlertTriangle, Check, History, Pencil, Scale, Upload } from "lucide-react";
import type { FrameworkVersionDetail, FrameworkVersionSummary, ValidationResult } from "@/lib/api";
import { formatDate } from "@/lib/format";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { Tooltip } from "@/components/ui/tooltip";
import { cn } from "@/lib/utils";

const STATUS_VARIANT = {
  published: "solid-success",
  draft: "warning",
  archived: "muted",
} as const;

/**
 * The bar makes the copy-on-write model legible.
 *
 * A published rubric is immutable — the backend returns 409 on any write to it.
 * So when the user is looking at the published version there is exactly one
 * action available: "Edit framework", which clones it to a draft. They should
 * never discover that rule by hitting an error.
 */
export function VersionBar({
  version,
  validation,
  versions,
  isDraft,
  busy,
  onEdit,
  onNormalize,
  onPublish,
  onSelectVersion,
}: {
  version: FrameworkVersionDetail;
  validation: ValidationResult | undefined;
  versions: FrameworkVersionSummary[] | undefined;
  isDraft: boolean;
  busy: boolean;
  onEdit: () => void;
  onNormalize: () => void;
  onPublish: () => void;
  onSelectVersion: (id: string) => void;
}) {
  const issues = validation?.issues ?? [];
  const valid = validation?.is_valid ?? false;

  return (
    <div className="sticky top-0 z-30 border-b border-border bg-background/95 px-6 py-3 backdrop-blur">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div className="flex min-w-0 items-center gap-3">
          <div className="min-w-0">
            <div className="flex items-center gap-2">
              <span className="text-sm font-semibold">v{version.version_no}</span>
              <span className="truncate text-sm">{version.name}</span>
              <Badge variant={STATUS_VARIANT[version.status]}>{version.status}</Badge>
            </div>
            <p className="text-2xs text-muted-foreground">
              {version.section_count} sections · {version.subsection_count} sub-sections ·{" "}
              {version.criterion_count} criteria
              {version.published_at && ` · published ${formatDate(version.published_at)}`}
            </p>
          </div>

          {isDraft &&
            (valid ? (
              <Badge variant="success">
                <Check className="size-2.5" />
                Weights balanced
              </Badge>
            ) : (
              <Popover>
                <PopoverTrigger asChild>
                  <button className="focus-ring rounded-full">
                    <Badge variant="warning">
                      <AlertTriangle className="size-2.5" />
                      {issues.length} issue{issues.length === 1 ? "" : "s"}
                    </Badge>
                  </button>
                </PopoverTrigger>
                <PopoverContent className="w-96">
                  <p className="mb-2 text-xs font-semibold">Cannot publish yet</p>
                  <ul className="space-y-1.5">
                    {issues.map((i, n) => (
                      <li key={n} className="flex gap-2 text-2xs">
                        <Badge variant="muted" className="shrink-0">
                          {i.level}
                        </Badge>
                        <span className="text-muted-foreground">{i.issue}</span>
                      </li>
                    ))}
                  </ul>
                </PopoverContent>
              </Popover>
            ))}
        </div>

        <div className="flex items-center gap-2">
          <Popover>
            <PopoverTrigger asChild>
              <Button variant="outline" size="sm">
                <History />
                Versions
              </Button>
            </PopoverTrigger>
            <PopoverContent className="w-96 p-0">
              <div className="max-h-80 overflow-y-auto p-1">
                {versions?.map((v) => (
                  <button
                    key={v.id}
                    onClick={() => onSelectVersion(v.id)}
                    className={cn(
                      "flex w-full items-center justify-between gap-2 rounded px-2 py-2 text-left hover:bg-accent focus-ring",
                      v.id === version.id && "bg-accent",
                    )}
                  >
                    <span className="min-w-0">
                      <span className="flex items-center gap-1.5">
                        <span className="text-xs font-medium">v{v.version_no}</span>
                        <span className="truncate text-xs">{v.name}</span>
                      </span>
                      <span className="text-2xs text-muted-foreground">
                        {v.criterion_count} criteria
                        {v.evaluation_count > 0 &&
                          ` · ${v.evaluation_count} evaluation${v.evaluation_count === 1 ? "" : "s"} reference this`}
                      </span>
                    </span>
                    <Badge variant={STATUS_VARIANT[v.status]}>{v.status}</Badge>
                  </button>
                ))}
              </div>
            </PopoverContent>
          </Popover>

          {isDraft ? (
            <>
              <Tooltip content="Rescale enabled siblings so every level totals 100%, keeping their proportions.">
                <Button variant="outline" size="sm" onClick={onNormalize} disabled={busy}>
                  <Scale />
                  Auto-balance
                </Button>
              </Tooltip>
              <Tooltip
                content={
                  valid
                    ? "Make this the active rubric"
                    : "Weights must total 100% at every level before publishing"
                }
              >
                <span>
                  <Button size="sm" onClick={onPublish} disabled={!valid || busy}>
                    <Upload />
                    Publish
                  </Button>
                </span>
              </Tooltip>
            </>
          ) : (
            <Tooltip content="Published versions are immutable. This creates an editable draft copy.">
              <Button size="sm" onClick={onEdit} disabled={busy}>
                <Pencil />
                Edit framework
              </Button>
            </Tooltip>
          )}
        </div>
      </div>
    </div>
  );
}
