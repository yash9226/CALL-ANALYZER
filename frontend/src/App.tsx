import { TooltipProvider } from "@radix-ui/react-tooltip";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Route, Routes } from "react-router-dom";
import { AppLayout } from "@/components/layout/AppLayout";
import Admin from "@/pages/Admin";
import CallDetail from "@/pages/CallDetail";
import Calls from "@/pages/Calls";
import Dashboard from "@/pages/Dashboard";
import Placeholder from "@/pages/Placeholder";
import { ToastProvider } from "@/components/ui/toast";

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 30_000,
      refetchOnWindowFocus: false,
      // A 409 is a business rule refusing the request; it will refuse again.
      retry: (count, error: any) => (error?.status === 409 ? false : count < 1),
    },
  },
});

export default function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <TooltipProvider delayDuration={200}>
        <ToastProvider>
          <BrowserRouter>
          <Routes>
            <Route element={<AppLayout />}>
              <Route index element={<Dashboard />} />
              <Route path="calls" element={<Calls />} />
              <Route path="calls/:callId" element={<CallDetail />} />
              <Route path="admin" element={<Admin />} />
              <Route path="chat" element={<Placeholder title="Assistant" phase="Phase 7" />} />
            </Route>
          </Routes>
          </BrowserRouter>
        </ToastProvider>
      </TooltipProvider>
    </QueryClientProvider>
  );
}
