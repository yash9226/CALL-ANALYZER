import { cn } from "@/lib/utils";

/** A bar, not a ring. Bars read faster in dense tables and compare across rows,
 *  which is exactly what a manager scanning a leaderboard is doing. */
export function Progress({
  value,
  className,
  barClassName,
}: {
  value: number | null | undefined;
  className?: string;
  barClassName?: string;
}) {
  const pct = Math.max(0, Math.min(100, value ?? 0));
  return (
    <div className={cn("h-1.5 w-full overflow-hidden rounded-full bg-muted", className)}>
      <div
        className={cn("h-full rounded-full transition-[width] duration-300", barClassName)}
        style={{ width: `${pct}%` }}
      />
    </div>
  );
}
