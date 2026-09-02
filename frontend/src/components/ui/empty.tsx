import type { LucideIcon } from "lucide-react";

/**
 * Empty states always say WHAT is missing, never just "No data".
 * "No calls match these filters" and "No calls have been ingested yet" call for
 * completely different actions from the user.
 */
export function EmptyState({
  icon: Icon,
  title,
  description,
  action,
}: {
  icon?: LucideIcon;
  title: string;
  description?: string;
  action?: React.ReactNode;
}) {
  return (
    <div className="flex flex-col items-center justify-center gap-2 px-6 py-10 text-center">
      {Icon && <Icon className="size-6 text-muted-foreground/50" />}
      <p className="text-sm font-medium">{title}</p>
      {description && <p className="max-w-sm text-xs text-muted-foreground">{description}</p>}
      {action && <div className="mt-2">{action}</div>}
    </div>
  );
}
