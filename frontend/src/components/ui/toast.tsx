import { CheckCircle2, X, AlertTriangle } from "lucide-react";
import { createContext, useCallback, useContext, useState } from "react";
import { cn } from "@/lib/utils";

type Toast = { id: number; title: string; body?: string; variant: "success" | "danger" | "info" };
const ToastCtx = createContext<(t: Omit<Toast, "id">) => void>(() => {});

export const useToast = () => useContext(ToastCtx);

export function ToastProvider({ children }: { children: React.ReactNode }) {
  const [toasts, setToasts] = useState<Toast[]>([]);

  const push = useCallback((t: Omit<Toast, "id">) => {
    const id = Date.now() + Math.random();
    setToasts((prev) => [...prev, { ...t, id }]);
    // Long enough to read a two-line message without being in the way.
    setTimeout(() => setToasts((prev) => prev.filter((x) => x.id !== id)), 6000);
  }, []);

  return (
    <ToastCtx.Provider value={push}>
      {children}
      <div className="pointer-events-none fixed bottom-4 right-4 z-[100] flex w-full max-w-sm flex-col gap-2">
        {toasts.map((t) => (
          <div
            key={t.id}
            className={cn(
              "pointer-events-auto flex items-start gap-2.5 rounded-lg border bg-card px-3.5 py-3 shadow-lg",
              t.variant === "success" && "border-success/40",
              t.variant === "danger" && "border-danger/40",
              t.variant === "info" && "border-border",
            )}
          >
            {t.variant === "success" ? (
              <CheckCircle2 className="mt-0.5 size-4 shrink-0 text-success-text" />
            ) : t.variant === "danger" ? (
              <AlertTriangle className="mt-0.5 size-4 shrink-0 text-danger-text" />
            ) : null}
            <div className="min-w-0 flex-1">
              <p className="text-[13px] font-medium">{t.title}</p>
              {t.body && <p className="mt-0.5 text-xs leading-relaxed text-muted-foreground">{t.body}</p>}
            </div>
            <button
              onClick={() => setToasts((p) => p.filter((x) => x.id !== t.id))}
              className="shrink-0 text-muted-foreground hover:text-foreground focus-ring rounded"
            >
              <X className="size-3.5" />
            </button>
          </div>
        ))}
      </div>
    </ToastCtx.Provider>
  );
}
