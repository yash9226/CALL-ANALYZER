import { useEffect, useState } from "react";
import { cn } from "@/lib/utils";

/**
 * Locally-controlled so typing feels immediate, committed on blur or Enter.
 *
 * Committing on every keystroke would fire a PATCH per character and make the
 * live weight validation flicker between invalid states while the user is
 * mid-number.
 */
export function WeightInput({
  value,
  disabled,
  onCommit,
}: {
  value: number;
  disabled?: boolean;
  onCommit: (next: number) => void;
}) {
  const [local, setLocal] = useState(String(value));

  useEffect(() => setLocal(String(value)), [value]);

  const commit = () => {
    const parsed = Number(local);
    if (!Number.isFinite(parsed) || parsed < 0) {
      setLocal(String(value));
      return;
    }
    if (parsed !== value) onCommit(parsed);
  };

  return (
    <div className="relative w-[68px] shrink-0">
      <input
        type="number"
        min={0}
        step="0.1"
        value={local}
        disabled={disabled}
        onChange={(e) => setLocal(e.target.value)}
        onBlur={commit}
        onKeyDown={(e) => {
          if (e.key === "Enter") (e.target as HTMLInputElement).blur();
          if (e.key === "Escape") setLocal(String(value));
        }}
        className={cn(
          "tabular h-7 w-full rounded-md border border-border bg-background pl-2 pr-5 text-right text-xs",
          "focus-ring disabled:opacity-50 [appearance:textfield]",
          "[&::-webkit-outer-spin-button]:appearance-none [&::-webkit-inner-spin-button]:appearance-none",
        )}
      />
      <span className="pointer-events-none absolute right-1.5 top-1/2 -translate-y-1/2 text-2xs text-muted-foreground">
        %
      </span>
    </div>
  );
}

/**
 * The sum of a level's enabled children, coloured by whether it totals 100.
 *
 * This is the single most useful affordance on the page: without it, an
 * unbalanced tree is only discovered at publish time, and the user has to hunt
 * for which level is wrong.
 */
export function WeightSum({ total, label }: { total: number; label?: string }) {
  const balanced = Math.abs(total - 100) < 0.01;
  return (
    <span
      className={cn(
        "tabular inline-flex shrink-0 items-center gap-1 rounded px-1.5 py-0.5 text-2xs font-medium",
        balanced ? "bg-success-soft text-success-text" : "bg-danger-soft text-danger-text",
      )}
      title={
        balanced
          ? "Enabled children total 100%"
          : `Enabled children total ${total.toFixed(1)}%, expected 100%`
      }
    >
      {label && <span className="opacity-70">{label}</span>}
      {total.toFixed(total % 1 === 0 ? 0 : 1)}%{!balanced && " ⚠"}
    </span>
  );
}
