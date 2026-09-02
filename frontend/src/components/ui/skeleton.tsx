import { cn } from "@/lib/utils";

/** Shaped like the content it replaces, so the layout does not jump when data
 *  arrives. A centred spinner would reflow the whole page. */
export const Skeleton = ({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) => (
  <div className={cn("animate-pulse rounded-md bg-muted", className)} {...props} />
);
