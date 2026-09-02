import { useQuery } from "@tanstack/react-query";
import { useState } from "react";
import { PageHeader } from "@/components/layout/AppLayout";
import { FilterBar } from "@/components/layout/FilterBar";
import { QueryBoundary } from "@/components/QueryBoundary";
import { AgentLeaderboard } from "@/components/dashboard/AgentLeaderboard";
import { CoachingPriorities } from "@/components/dashboard/CoachingPriorities";
import { KpiCard, KpiSkeleton } from "@/components/dashboard/KpiCard";
import { RiskFlagsCard } from "@/components/dashboard/RiskFlags";
import { ScoreDistributionCard } from "@/components/dashboard/ScoreDistribution";
import { SectionPerformanceCard } from "@/components/dashboard/SectionPerformance";
import { TopicsCard } from "@/components/dashboard/TopicsCard";
import { TrendChart, type Granularity } from "@/components/dashboard/TrendChart";
import { Skeleton } from "@/components/ui/skeleton";
import { useFilters } from "@/hooks/useFilters";
import { api } from "@/lib/api";
import { formatDuration, formatPercent, formatSigned } from "@/lib/format";

export default function Dashboard() {
  const { filters } = useFilters();
  const [granularity, setGranularity] = useState<Granularity>("week");

  const overview = useQuery({
    queryKey: ["overview", filters],
    queryFn: () => api.analytics.overview(filters),
  });
  const trend = useQuery({
    queryKey: ["trend", filters, granularity],
    queryFn: () => api.analytics.trend({ ...filters, granularity }),
  });
  const sections = useQuery({
    queryKey: ["sections", filters],
    queryFn: () => api.analytics.sections(filters),
  });
  const distribution = useQuery({
    queryKey: ["distribution", filters],
    queryFn: () => api.analytics.distribution(filters),
  });
  const agents = useQuery({
    queryKey: ["agents", filters],
    queryFn: () => api.analytics.agents({ ...filters, support_agent_id: undefined }),
  });
  const criteria = useQuery({
    queryKey: ["criteria", filters],
    queryFn: () => api.analytics.criteria({ ...filters, limit: 8 }),
  });
  const flags = useQuery({
    queryKey: ["flags", filters],
    queryFn: () => api.analytics.flags({ ...filters, limit: 8 }),
  });
  const topics = useQuery({
    queryKey: ["topics", filters],
    queryFn: () => api.analytics.topics(filters),
  });

  const o = overview.data;

  return (
    <>
      <PageHeader
        title="Dashboard"
        description="Call quality across your teams"
        actions={<FilterBar />}
      />

      <div className="space-y-4 p-6">
        {/* Row 1 — KPIs */}
        <div className="grid grid-cols-2 gap-4 md:grid-cols-3 xl:grid-cols-6">
          {overview.isLoading || !o ? (
            Array.from({ length: 6 }, (_, i) => <KpiSkeleton key={i} />)
          ) : (
            <>
              <KpiCard
                label="Average score"
                value={formatPercent(o.current.avg_score)}
                sub={`${o.current.evaluated_calls} evaluated calls`}
                change={o.change_pct.avg_score}
              />
              <KpiCard
                label="Calls evaluated"
                value={o.current.evaluated_calls}
                sub={`${o.evaluation_coverage_pct}% of ${o.current.total_calls} calls`}
                change={o.change_pct.total_calls}
              />
              <KpiCard
                label="Auto-fail rate"
                value={formatPercent(o.auto_fail_rate)}
                sub={`${o.current.auto_fails} calls auto-failed`}
                change={o.change_pct.auto_fails}
                invertTrend
                alert={o.auto_fail_rate > 10}
                tooltip="A failed critical criterion forces the whole call to 0%."
              />
              <KpiCard
                label="Critical flags"
                value={o.current.critical_flags}
                sub={`${o.current.total_flags} flags total`}
                change={o.change_pct.critical_flags}
                invertTrend
              />
              <KpiCard
                label="Sentiment recovery"
                value={formatSigned(o.current.avg_sentiment_delta)}
                sub="closing minus opening"
                change={o.change_pct.avg_sentiment}
                tooltip="Positive means agents are turning calls around. The strongest coaching signal in the data."
              />
              <KpiCard
                label="Active agents"
                value={o.current.active_agents}
                sub={`${formatDuration(o.current.avg_duration_seconds)} avg call`}
              />
            </>
          )}
        </div>

        {/* Row 2 — trend */}
        <QueryBoundary
          isLoading={trend.isLoading}
          error={trend.error}
          onRetry={trend.refetch}
          skeleton={<Skeleton className="h-[340px] w-full" />}
        >
          {trend.data && (
            <TrendChart
              data={trend.data}
              granularity={granularity}
              onGranularityChange={setGranularity}
            />
          )}
        </QueryBoundary>

        {/* Row 3 */}
        <div className="grid gap-4 lg:grid-cols-2">
          <QueryBoundary
            isLoading={sections.isLoading}
            error={sections.error}
            onRetry={sections.refetch}
            skeleton={<Skeleton className="h-[300px]" />}
          >
            {sections.data && <SectionPerformanceCard data={sections.data} />}
          </QueryBoundary>

          <QueryBoundary
            isLoading={distribution.isLoading}
            error={distribution.error}
            onRetry={distribution.refetch}
            skeleton={<Skeleton className="h-[300px]" />}
          >
            {distribution.data && <ScoreDistributionCard data={distribution.data} />}
          </QueryBoundary>
        </div>

        {/* Row 4 */}
        <div className="grid gap-4 lg:grid-cols-5">
          <div className="lg:col-span-3">
            <QueryBoundary
              isLoading={agents.isLoading}
              error={agents.error}
              onRetry={agents.refetch}
              skeleton={<Skeleton className="h-[380px]" />}
            >
              {agents.data && <AgentLeaderboard data={agents.data} />}
            </QueryBoundary>
          </div>
          <div className="lg:col-span-2">
            <QueryBoundary
              isLoading={criteria.isLoading}
              error={criteria.error}
              onRetry={criteria.refetch}
              skeleton={<Skeleton className="h-[380px]" />}
            >
              {criteria.data && <CoachingPriorities data={criteria.data} />}
            </QueryBoundary>
          </div>
        </div>

        {/* Row 5 */}
        <div className="grid gap-4 lg:grid-cols-2">
          <QueryBoundary
            isLoading={flags.isLoading}
            error={flags.error}
            onRetry={flags.refetch}
            skeleton={<Skeleton className="h-[300px]" />}
          >
            {flags.data && <RiskFlagsCard data={flags.data} />}
          </QueryBoundary>

          <QueryBoundary
            isLoading={topics.isLoading}
            error={topics.error}
            onRetry={topics.refetch}
            skeleton={<Skeleton className="h-[300px]" />}
          >
            {topics.data && <TopicsCard data={topics.data} />}
          </QueryBoundary>
        </div>
      </div>
    </>
  );
}
