import { Construction } from "lucide-react";
import { PageHeader } from "@/components/layout/AppLayout";
import { Card } from "@/components/ui/card";
import { EmptyState } from "@/components/ui/empty";

export default function Placeholder({ title, phase }: { title: string; phase: string }) {
  return (
    <>
      <PageHeader title={title} />
      <div className="p-6">
        <Card className="mx-auto max-w-md">
          <EmptyState
            icon={Construction}
            title={`${title} is coming in ${phase}`}
            description="The backend for this is already built and tested; the interface is next."
          />
        </Card>
      </div>
    </>
  );
}
