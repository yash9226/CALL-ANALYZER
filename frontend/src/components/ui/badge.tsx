import { cva, type VariantProps } from "class-variance-authority";
import * as React from "react";
import { cn } from "@/lib/utils";

/**
 * Solid success and warning badges use DARK foreground text, not white.
 * White on emerald measures 2.6:1 and on amber 2.1:1 — both unreadable. Only
 * the danger fill is dark enough to carry white text (4.8:1).
 */
const badgeVariants = cva(
  "inline-flex items-center gap-1 rounded-full border px-2 py-0.5 text-2xs font-medium whitespace-nowrap",
  {
    variants: {
      variant: {
        default: "border-transparent bg-secondary text-secondary-foreground",
        outline: "border-border text-foreground",
        primary: "border-transparent bg-primary/10 text-primary",
        success: "border-transparent bg-success-soft text-success-text",
        warning: "border-transparent bg-warning-soft text-warning-text",
        danger: "border-transparent bg-danger-soft text-danger-text",
        "solid-danger": "border-transparent bg-danger text-white",
        "solid-success": "border-transparent bg-success text-background dark:text-background",
        muted: "border-transparent bg-muted text-muted-foreground",
      },
    },
    defaultVariants: { variant: "default" },
  },
);

export interface BadgeProps
  extends React.HTMLAttributes<HTMLSpanElement>,
    VariantProps<typeof badgeVariants> {}

// forwardRef because Badge is used as a Tooltip trigger, and Radix's `asChild`
// attaches a ref to whatever child it is given.
export const Badge = React.forwardRef<HTMLSpanElement, BadgeProps>(
  ({ className, variant, ...props }, ref) => (
    <span ref={ref} className={cn(badgeVariants({ variant }), className)} {...props} />
  ),
);
Badge.displayName = "Badge";
