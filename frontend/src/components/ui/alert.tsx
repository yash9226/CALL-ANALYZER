import { AlertTriangle } from "lucide-react";
import { cn } from "@/lib/utils";

export function Alert({
  variant = "danger",
  title,
  children,
  className,
}: {
  variant?: "danger" | "warning" | "info";
  title?: string;
  children?: React.ReactNode;
  className?: string;
}) {
  const styles = {
    danger: "border-danger/30 bg-danger-soft text-danger-text",
    warning: "border-warning/30 bg-warning-soft text-warning-text",
    info: "border-primary/30 bg-primary/5 text-foreground",
  }[variant];

  return (
    <div className={cn("flex items-start gap-2.5 rounded-lg border px-4 py-3", styles, className)}>
      <AlertTriangle className="mt-0.5 size-4 shrink-0" />
      <div className="min-w-0 space-y-0.5">
        {title && <p className="text-sm font-semibold">{title}</p>}
        {children && <div className="text-xs leading-relaxed">{children}</div>}
      </div>
    </div>
  );
}
