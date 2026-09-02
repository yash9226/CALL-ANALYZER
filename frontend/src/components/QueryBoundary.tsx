import { AlertTriangle, RefreshCw } from "lucide-react";
import { ApiError } from "@/lib/api";
import { Button } from "@/components/ui/button";

/**
 * One place that decides how a failed query looks.
 *
 * A 409 from this backend is a business rule refusing the request, and the
 * message is written for a human ("Framework version is 'published' and cannot
 * be edited. Clone it to a draft first."). Those are shown VERBATIM — replacing
 * them with "Something went wrong" throws away the only actionable part.
 */
export function QueryBoundary({
  isLoading,
  error,
  onRetry,
  skeleton,
  children,
}: {
  isLoading: boolean;
  error: unknown;
  onRetry?: () => void;
  skeleton: React.ReactNode;
  children: React.ReactNode;
}) {
  if (isLoading) return <>{skeleton}</>;

  if (error) {
    const isApi = error instanceof ApiError;
    const conflict = isApi && error.isConflict;
    return (
      <div className="flex flex-col items-center gap-3 rounded-lg border border-danger/30 bg-danger-soft px-6 py-8 text-center">
        <AlertTriangle className="size-5 text-danger-text" />
        <div>
          <p className="text-sm font-medium text-danger-text">
            {conflict ? "Cannot complete this action" : "Could not load this data"}
          </p>
          <p className="mt-1 max-w-md text-xs text-danger-text/80">
            {isApi ? error.message : "The API did not respond. Is the backend running?"}
          </p>
        </div>
        {onRetry && !conflict && (
          <Button variant="outline" size="sm" onClick={onRetry}>
            <RefreshCw />
            Retry
          </Button>
        )}
      </div>
    );
  }

  return <>{children}</>;
}
