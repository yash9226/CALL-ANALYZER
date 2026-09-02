/**
 * CALL-ANALYZER — API client and type contract.
 *
 * THIS FILE IS THE SEAM between the backend and the UI. It is hand-written to
 * match the live FastAPI schema exactly (see http://localhost:8000/docs).
 *
 * RULES FOR THE FRONTEND
 * ----------------------
 * 1. Never call `fetch` anywhere else. Every network call goes through here.
 * 2. Never invent a field. If a value is not in these types, the backend does
 *    not return it — ask for it rather than faking it.
 * 3. Never talk to Supabase directly. Scoring, weighting and access control all
 *    live behind this API; bypassing it produces numbers that disagree with the
 *    rest of the product.
 *
 * With MOCK=true the module serves fixtures with the same shapes, so the UI can
 * be built and demoed before the backend is running.
 */

// ─── Configuration ──────────────────────────────────────────────────────────

const BASE_URL =
  (typeof import.meta !== "undefined" && (import.meta as any).env?.VITE_API_URL) ||
  "http://localhost:8000";

/** Flip to true to run entirely on fixtures, with no backend. */
export const MOCK = false;

let authToken: string | null = null;

/** Set the Supabase access token. Call after login; pass null on logout. */
export function setAuthToken(token: string | null): void {
  authToken = token;
}

export class ApiError extends Error {
  constructor(
    public status: number,
    public code: string,
    message: string,
    public details: Record<string, unknown> = {},
  ) {
    super(message);
    this.name = "ApiError";
  }

  /** 409 means a business rule refused the request — show the message verbatim.
   *  The backend writes these for humans ("Framework version is 'published' and
   *  cannot be edited"), so paraphrasing them loses the actionable part. */
  get isConflict(): boolean {
    return this.status === 409;
  }
}

async function request<T>(
  path: string,
  init: RequestInit = {},
  params?: Record<string, unknown>,
): Promise<T> {
  const url = new URL(path, BASE_URL);
  if (params) {
    for (const [key, value] of Object.entries(params)) {
      if (value !== undefined && value !== null && value !== "") {
        url.searchParams.set(key, String(value));
      }
    }
  }

  const headers: Record<string, string> = { ...(init.headers as any) };
  if (!(init.body instanceof FormData)) headers["Content-Type"] = "application/json";
  if (authToken) headers["Authorization"] = `Bearer ${authToken}`;

  const response = await fetch(url.toString(), { ...init, headers });

  if (response.status === 204) return undefined as T;

  const text = await response.text();
  const body = text ? JSON.parse(text) : null;

  if (!response.ok) {
    const err = body?.error ?? {};
    throw new ApiError(
      response.status,
      err.code ?? "unknown",
      err.message ?? response.statusText,
      err.details ?? {},
    );
  }
  return body as T;
}

// ─── Enums (mirror the Postgres types) ──────────────────────────────────────

export type UserRole = "admin" | "manager" | "agent";
export type FrameworkStatus = "draft" | "published" | "archived";
export type ScoringType = "binary" | "scale_5" | "scale_10" | "numeric";
export type CallStatus =
  | "pending" | "transcribing" | "transcribed" | "evaluating" | "evaluated" | "failed";
export type CallChannel = "phone" | "voip" | "chat" | "email";
export type CallDirection = "inbound" | "outbound";
export type SpeakerRole = "agent" | "customer" | "system" | "unknown";
export type EvaluationStatus = "queued" | "running" | "completed" | "failed" | "cancelled";
export type AgentRunStatus = "pending" | "running" | "completed" | "failed" | "skipped";
export type SentimentLabel =
  | "very_negative" | "negative" | "neutral" | "positive" | "very_positive";
export type RiskSeverity = "low" | "medium" | "high" | "critical";
export type Grade = "A" | "B" | "C" | "D" | "F";
export type ResolutionStatus =
  | "resolved" | "partially_resolved" | "unresolved" | "escalated" | "follow_up_scheduled";
export type SentimentTrajectory =
  | "improving" | "declining" | "stable" | "volatile" | "recovered";

// ─── Quality framework ──────────────────────────────────────────────────────

export interface Criterion {
  id: string;
  subsection_id: string;
  code: string;
  name: string;
  description: string | null;
  /** Percentage share within its sub-section. Siblings should total 100. */
  weight: number;
  scoring_type: ScoringType;
  max_score: number;
  min_score: number;
  /** Injected verbatim into the scoring prompt. Editing this changes how calls
   *  are scored with no code deploy — treat it as a first-class field, give it a
   *  large textarea, and never hide it behind an "advanced" toggle. */
  guidance: string | null;
  examples: Array<{ score?: number; example?: string; why?: string }>;
  /** Auto-fail. Failing this zeroes the whole call score. Mark it visibly. */
  is_critical: boolean;
  /** Whether the scoring agent may return "not applicable" for this criterion. */
  allow_na: boolean;
  display_order: number;
  is_enabled: boolean;
  created_at: string;
  updated_at: string;
}

export interface Subsection {
  id: string;
  section_id: string;
  code: string;
  name: string;
  description: string | null;
  weight: number;
  display_order: number;
  is_enabled: boolean;
  criteria: Criterion[];
}

export interface Section {
  id: string;
  framework_version_id: string;
  code: string;
  name: string;
  description: string | null;
  weight: number;
  display_order: number;
  is_enabled: boolean;
  subsections: Subsection[];
}

export interface FrameworkVersionSummary {
  id: string;
  version_no: number;
  name: string;
  description: string | null;
  status: FrameworkStatus;
  notes: string | null;
  cloned_from: string | null;
  published_at: string | null;
  archived_at: string | null;
  created_at: string;
  section_count: number;
  subsection_count: number;
  criterion_count: number;
  /** How many evaluations were scored under this version. Warn before archiving
   *  a version with a non-zero count — those scores reference it. */
  evaluation_count: number;
}

export interface FrameworkVersionDetail extends FrameworkVersionSummary {
  sections: Section[];
}

export interface WeightIssue {
  level: "section" | "subsection" | "criterion" | "structure";
  node_path: string;
  node_id: string | null;
  issue: string;
  actual_sum: number;
}

export interface ValidationResult {
  is_valid: boolean;
  issues: WeightIssue[];
}

export interface PublishResult {
  published_version_id: string;
  archived_version_id: string | null;
  message: string;
}

export interface ReprojectResult {
  framework_version_id: string;
  /** Recomputed with pure arithmetic — no LLM calls, no cost. */
  recomputed_instantly: number;
  /** Needed the scoring agent, because this version added criteria that have
   *  never been scored on those calls. */
  queued_for_rescoring: number;
  message: string;
}

// ─── Calls ──────────────────────────────────────────────────────────────────

export interface CallOverview {
  call_id: string;
  call_code: string;
  started_at: string;
  duration_seconds: number | null;
  status: CallStatus;
  channel: CallChannel;
  direction: CallDirection;
  support_agent_id: string | null;
  agent_code: string | null;
  agent_name: string | null;
  team_id: string | null;
  team_name: string | null;
  evaluation_id: string | null;
  score_percentage: number | null;
  grade: Grade | null;
  auto_fail_triggered: boolean | null;
  framework_version_id: string | null;
  headline: string | null;
  resolution_status: ResolutionStatus | null;
  topics: string[] | null;
  sentiment_label: SentimentLabel | null;
  sentiment_score: number | null;
  /** Closing minus opening sentiment. Positive means the agent turned the call
   *  around — the single most useful coaching signal, so surface it. */
  sentiment_delta: number | null;
  sentiment_trajectory: SentimentTrajectory | null;
  flag_count: number;
  critical_flag_count: number;
}

export interface Paginated<T> {
  items: T[];
  total: number;
  limit: number;
  offset: number;
}

export interface TranscriptTurn {
  id: string;
  turn_index: number;
  speaker: SpeakerRole;
  speaker_label: string;
  text: string;
  start_ms: number | null;
  end_ms: number | null;
  /** Offsets into Transcript.full_text. Highlight with a literal slice —
   *  never search for the quoted text, which may be a paraphrase. */
  char_start: number;
  char_end: number;
}

export interface Transcript {
  id: string;
  full_text: string;
  word_count: number;
  turn_count: number;
  language: string;
  transcription_provider: string | null;
  transcription_model: string | null;
  transcription_confidence: number | null;
}

export interface ScoreCitation {
  id: string;
  turn_index: number | null;
  quoted_text: string;
  char_start: number | null;
  char_end: number | null;
  /** supporting = evidence of good practice (green);
   *  detracting = evidence of a failure (red). */
  polarity: "supporting" | "detracting" | "neutral";
  relevance: number | null;
}

export interface CriterionScore {
  id: string;
  criterion_code: string;
  criterion_name: string;
  subsection_code: string;
  section_code: string;
  scoring_type: ScoringType;
  weight_snapshot: number;
  is_critical_snapshot: boolean;
  raw_score: number | null;
  max_score: number;
  /** 0..1. Use this for bars and colours; raw_score for the displayed number. */
  normalized: number | null;
  confidence: number | null;
  reasoning: string | null;
  /** false means not applicable: show "N/A", never 0. Scoring it zero would
   *  unfairly penalise the agent, and the backend excludes it from the total. */
  is_applicable: boolean;
  na_reason: string | null;
  citations: ScoreCitation[];
}

export interface SectionScore {
  section_code: string;
  section_name: string;
  weight_snapshot: number;
  normalized: number | null;
  subsections_total: number;
  subsections_scored: number;
}

export interface SubsectionScore {
  subsection_code: string;
  subsection_name: string;
  section_code: string;
  weight_snapshot: number;
  normalized: number | null;
  criteria_total: number;
  criteria_scored: number;
}

export interface CallSummary {
  headline: string | null;
  summary: string;
  customer_intent: string | null;
  resolution_status: ResolutionStatus | null;
  outcome: string | null;
  key_issues: string[];
  topics: string[];
  next_actions: Array<{ action: string; owner?: string; due?: string }>;
}

export interface SentimentPoint {
  turn_index: number;
  speaker: SpeakerRole;
  score: number;
  label: SentimentLabel;
  emotions: Record<string, number>;
}

export interface RiskFlag {
  id: string;
  flag_type: string;
  severity: RiskSeverity;
  title: string;
  description: string;
  confidence: number | null;
  turn_index: number | null;
  quoted_text: string | null;
  char_start: number | null;
  char_end: number | null;
  is_acknowledged: boolean;
  is_false_positive: boolean;
  reviewer_notes: string | null;
}

export interface CallStatistics {
  agent_turn_count: number;
  customer_turn_count: number;
  agent_word_count: number;
  customer_word_count: number;
  /** Agent share of words spoken. Above ~0.75 is a listening red flag. */
  agent_talk_ratio: number | null;
  longest_agent_turn_words: number | null;
  interruption_count: number;
  question_count_agent: number;
  filler_word_count: number;
  detected_language: string | null;
}

export interface AgentRun {
  agent_name: string;
  step_order: number;
  status: AgentRunStatus;
  model: string | null;
  prompt_version: string | null;
  input_tokens: number;
  output_tokens: number;
  latency_ms: number | null;
  /** Greater than 1 means the provider retried — the model was rate-limited or
   *  timed out. Worth surfacing in the pipeline trace. */
  attempt_count: number;
  error_message: string | null;
  started_at: string | null;
  completed_at: string | null;
}

export interface EvaluationHistoryItem {
  id: string;
  framework_version_id: string;
  status: EvaluationStatus;
  score_percentage: number | null;
  grade: Grade | null;
  auto_fail_triggered: boolean;
  is_current: boolean;
  /** initial | framework_change | manual_rerun | model_upgrade */
  trigger_reason: string;
  model_used: string | null;
  created_at: string;
  completed_at: string | null;
}

/** Everything the drill-down page needs, in one response. */
export interface CallDetail {
  call: CallOverview;
  transcript: Transcript | null;
  turns: TranscriptTurn[];
  evaluation_id: string | null;
  criterion_scores: CriterionScore[];
  section_scores: SectionScore[];
  subsection_scores: SubsectionScore[];
  summary: CallSummary | null;
  sentiment_timeline: SentimentPoint[];
  risk_flags: RiskFlag[];
  statistics: CallStatistics | null;
  agent_runs: AgentRun[];
  evaluation_history: EvaluationHistoryItem[];
}

export interface CallFilters {
  limit?: number;
  offset?: number;
  team_id?: string;
  support_agent_id?: string;
  status?: CallStatus;
  grade?: Grade;
  date_from?: string;
  date_to?: string;
  min_score?: number;
  max_score?: number;
  has_flags?: boolean;
  auto_failed?: boolean;
  topic?: string;
  /** Matches call code, agent name, and transcript full text. */
  search?: string;
  sort_by?: "started_at" | "score" | "duration" | "agent" | "sentiment";
  sort_dir?: "asc" | "desc";
}

// ─── Analytics ──────────────────────────────────────────────────────────────

export interface AnalyticsFilters {
  date_from?: string;
  date_to?: string;
  team_id?: string;
  support_agent_id?: string;
}

export interface OverviewMetrics {
  total_calls: number;
  evaluated_calls: number;
  avg_score: number | null;
  avg_sentiment: number | null;
  avg_sentiment_delta: number | null;
  auto_fails: number;
  critical_flags: number;
  total_flags: number;
  avg_duration_seconds: number | null;
  active_agents: number;
}

export interface AnalyticsOverview {
  period: { from: string; to: string };
  current: OverviewMetrics;
  previous: OverviewMetrics;
  /** Percentage change against the preceding window of equal length.
   *  null when there is no comparable prior data — render "—", not "0%". */
  change_pct: {
    avg_score: number | null;
    total_calls: number | null;
    auto_fails: number | null;
    avg_sentiment: number | null;
    critical_flags: number | null;
  };
  auto_fail_rate: number;
  evaluation_coverage_pct: number;
}

export interface TrendPoint {
  bucket: string;
  calls: number;
  evaluated: number;
  avg_score: number | null;
  avg_sentiment: number | null;
  auto_fails: number;
  critical_flags: number;
}

export interface SectionPerformance {
  section_code: string;
  section_name: string;
  weight: number;
  avg_score: number | null;
  sample_size: number;
}

export interface CriterionPerformance {
  section_code: string;
  subsection_code: string;
  criterion_code: string;
  criterion_name: string;
  is_critical: boolean;
  scored: number;
  not_applicable: number;
  avg_score: number | null;
  avg_confidence: number | null;
  /** Share of APPLICABLE scores below half marks. N/A is excluded from both
   *  numerator and denominator. */
  fail_rate_pct: number | null;
}

export interface AgentScorecard {
  support_agent_id: string;
  agent_code: string;
  agent_name: string;
  team_id: string | null;
  team_name: string | null;
  calls: number;
  evaluated: number;
  avg_score: number | null;
  min_score: number | null;
  max_score: number | null;
  /** Consistency. A steady 78 and an erratic 60-95 average the same but are
   *  different coaching problems, so show this next to the average. */
  score_stddev: number | null;
  auto_fails: number;
  avg_sentiment_delta: number | null;
  critical_flags: number;
  avg_duration_seconds: number | null;
  last_call_at: string | null;
}

export interface ScoreDistribution {
  /** All ten bands are always present, including empty ones, so the x-axis is
   *  stable. Do not filter them out. */
  bands: Array<{ band: number; label: string; calls: number }>;
  grades: Partial<Record<Grade, number>>;
}

export interface FlagSummary {
  by_type: Array<{ flag_type: string; severity: RiskSeverity; count: number }>;
  by_severity: Partial<Record<RiskSeverity, number>>;
  total: number;
  recent_open: Array<
    RiskFlag & { call_id: string; call_code: string; agent_name: string | null;
                 team_name: string | null; created_at: string }
  >;
}

export interface TopicBreakdown {
  topic: string;
  calls: number;
  avg_score: number | null;
  avg_sentiment: number | null;
}

// ─── Ingestion, evaluations, meta ───────────────────────────────────────────

export interface IngestResult {
  call_id: string;
  call_code: string;
  transcript_id: string;
  turn_count: number;
  word_count: number;
  created: boolean;
  agent_resolved: boolean;
}

export interface BatchResult {
  batch_id: string;
  filename: string;
  total_rows: number;
  succeeded: number;
  failed: number;
  created: number;
  updated: number;
  /** Per-row failures. A partial import is normal and expected — show these
   *  rather than treating the whole upload as failed. */
  errors: Array<{ row: number; call_code: string; error: string }>;
}

export interface IngestionBatch {
  id: string;
  filename: string | null;
  total_rows: number;
  succeeded: number;
  failed: number;
  status: string;
  error_log: Array<{ row: number; call_code: string; error: string }>;
  created_at: string;
  completed_at: string | null;
}

export interface EvaluationResult {
  evaluation_id: string;
  call_id: string;
  framework_version_id: string;
  agents_completed: string[];
  agents_failed: string[];
  score_percentage: number | null;
  grade: Grade | null;
  auto_fail_triggered: boolean;
  auto_fail_reason: string | null;
  input_tokens: number;
  output_tokens: number;
  cost_usd: number;
  model_used: string | null;
  duration_ms: number | null;
}

export interface QueuedEvaluation {
  job_id: string;
  evaluation_id: string;
  status: string;
}

export interface PipelineGraph {
  /** Mermaid source, generated from the graph that actually runs. */
  mermaid: string;
  agents: Array<{ name: string; step: number; uses_llm: boolean; output: string }>;
  provider: string;
  model: string;
}

export interface JobQueue {
  jobs: Array<{
    id: string; job_type: string; status: string; priority: number;
    attempts: number; max_attempts: number; error_message: string | null;
    created_at: string; started_at: string | null; completed_at: string | null;
    call_code: string | null;
  }>;
  counts: Record<string, number>;
}

export interface Team {
  id: string;
  code: string;
  name: string;
  description: string | null;
  is_active: boolean;
  agent_count: number;
  call_count: number;
}

export interface Health {
  status: "ok" | "degraded";
  database: string;
  auth_dev_bypass: boolean;
  mock_llm: boolean;
  calls?: number;
  evaluations?: number;
  active_criteria?: number;
  framework_version?: number;
}

// ─── API surface ────────────────────────────────────────────────────────────

export const api = {
  health: () => request<Health>("/health"),

  teams: {
    list: () => request<Team[]>("/api/teams"),
  },

  calls: {
    list: (filters: CallFilters = {}) =>
      request<Paginated<CallOverview>>("/api/calls", {}, filters as any),
    get: (callId: string) => request<CallDetail>(`/api/calls/${callId}`),
    transcript: (callId: string) =>
      request<Transcript & { turns: TranscriptTurn[] }>(`/api/calls/${callId}/transcript`),
  },

  analytics: {
    overview: (f: AnalyticsFilters = {}) =>
      request<AnalyticsOverview>("/api/analytics/overview", {}, f as any),
    trend: (f: AnalyticsFilters & { granularity?: "day" | "week" | "month" } = {}) =>
      request<TrendPoint[]>("/api/analytics/trend", {}, f as any),
    sections: (f: AnalyticsFilters = {}) =>
      request<SectionPerformance[]>("/api/analytics/sections", {}, f as any),
    criteria: (f: AnalyticsFilters & { limit?: number; worst_first?: boolean } = {}) =>
      request<CriterionPerformance[]>("/api/analytics/criteria", {}, f as any),
    agents: (f: AnalyticsFilters & { limit?: number } = {}) =>
      request<AgentScorecard[]>("/api/analytics/agents", {}, f as any),
    distribution: (f: AnalyticsFilters = {}) =>
      request<ScoreDistribution>("/api/analytics/distribution", {}, f as any),
    flags: (f: AnalyticsFilters & { limit?: number } = {}) =>
      request<FlagSummary>("/api/analytics/flags", {}, f as any),
    topics: (f: AnalyticsFilters = {}) =>
      request<TopicBreakdown[]>("/api/analytics/topics", {}, f as any),
  },

  framework: {
    versions: () => request<FrameworkVersionSummary[]>("/api/framework/versions"),
    active: () => request<FrameworkVersionDetail>("/api/framework/active"),
    get: (versionId: string) =>
      request<FrameworkVersionDetail>(`/api/framework/versions/${versionId}`),

    /** Returns an editable draft, cloning the published version if none exists.
     *  Call this when the user clicks "Edit framework" — never attempt to PATCH
     *  a published version, which returns 409 by design. */
    draft: () => request<FrameworkVersionDetail>("/api/framework/draft", { method: "POST" }),

    clone: (versionId: string, name?: string) =>
      request<FrameworkVersionDetail>(
        `/api/framework/versions/${versionId}/clone`,
        { method: "POST", body: JSON.stringify({ name: name ?? null }) },
      ),

    /** Poll while the user edits so imbalance is visible immediately, rather
     *  than only being discovered at publish time. */
    validate: (versionId: string) =>
      request<ValidationResult>(`/api/framework/versions/${versionId}/validate`),

    /** Auto-balance: rescales enabled siblings to total 100, keeping ratios. */
    normalize: (versionId: string) =>
      request<FrameworkVersionDetail>(
        `/api/framework/versions/${versionId}/normalize`, { method: "POST" },
      ),

    /** Fails with 409 and the specific imbalance if weights do not total 100. */
    publish: (versionId: string) =>
      request<PublishResult>(
        `/api/framework/versions/${versionId}/publish`, { method: "POST" },
      ),

    /** Apply this version across historical evaluations. */
    apply: (versionId: string, onlyCurrent = true) =>
      request<ReprojectResult>(
        `/api/framework/versions/${versionId}/apply`,
        { method: "POST" }, { only_current: onlyCurrent },
      ),

    createSection: (body: Partial<Section> & { framework_version_id: string; code: string; name: string }) =>
      request<Section>("/api/framework/sections", { method: "POST", body: JSON.stringify(body) }),
    updateSection: (id: string, body: Partial<Section>) =>
      request<Section>(`/api/framework/sections/${id}`, { method: "PATCH", body: JSON.stringify(body) }),
    deleteSection: (id: string) =>
      request<void>(`/api/framework/sections/${id}`, { method: "DELETE" }),

    createSubsection: (body: Partial<Subsection> & { section_id: string; code: string; name: string }) =>
      request<Subsection>("/api/framework/subsections", { method: "POST", body: JSON.stringify(body) }),
    updateSubsection: (id: string, body: Partial<Subsection>) =>
      request<Subsection>(`/api/framework/subsections/${id}`, { method: "PATCH", body: JSON.stringify(body) }),
    deleteSubsection: (id: string) =>
      request<void>(`/api/framework/subsections/${id}`, { method: "DELETE" }),

    createCriterion: (body: Partial<Criterion> & { subsection_id: string; code: string; name: string }) =>
      request<Criterion>("/api/framework/criteria", { method: "POST", body: JSON.stringify(body) }),
    updateCriterion: (id: string, body: Partial<Criterion>) =>
      request<Criterion>(`/api/framework/criteria/${id}`, { method: "PATCH", body: JSON.stringify(body) }),
    deleteCriterion: (id: string) =>
      request<void>(`/api/framework/criteria/${id}`, { method: "DELETE" }),

    reorder: (level: "sections" | "subsections" | "criteria",
              items: Array<{ id: string; display_order: number }>) =>
      request<{ message: string }>(`/api/framework/${level}/reorder`,
        { method: "POST", body: JSON.stringify({ items }) }),
  },

  evaluations: {
    graph: () => request<PipelineGraph>("/api/evaluations/pipeline/graph"),
    get: (evaluationId: string) => request<any>(`/api/evaluations/${evaluationId}`),

    /** run_inline: true blocks until finished — fine for one call, never for a
     *  batch. Queued runs are picked up by the background worker. */
    run: (callId: string, opts: { run_inline?: boolean; trigger_reason?: string } = {}) =>
      request<EvaluationResult | QueuedEvaluation>(
        `/api/evaluations/calls/${callId}`,
        { method: "POST", body: JSON.stringify({ run_inline: false, ...opts }) },
      ),

    bulk: (body: { call_ids?: string[]; limit?: number; trigger_reason?: string } = {}) =>
      request<{ queued: number; jobs: QueuedEvaluation[] }>(
        "/api/evaluations/bulk", { method: "POST", body: JSON.stringify(body) },
      ),

    queue: (status?: string) =>
      request<JobQueue>("/api/evaluations/jobs/queue", {}, { status }),
  },

  ingestion: {
    single: (body: {
      call_code: string;
      transcript: string | Array<{ speaker: string; text: string; start_ms?: number }>;
      agent_code?: string; customer_ref?: string; started_at?: string;
      duration_seconds?: number; direction?: CallDirection; channel?: CallChannel;
      language?: string; metadata?: Record<string, unknown>;
    }) => request<IngestResult>("/api/ingestion/calls",
      { method: "POST", body: JSON.stringify(body) }),

    batch: (file: File) => {
      const form = new FormData();
      form.append("file", file);
      return request<BatchResult>("/api/ingestion/batch", { method: "POST", body: form });
    },

    batches: () => request<IngestionBatch[]>("/api/ingestion/batches"),
    batch_detail: (batchId: string) =>
      request<IngestionBatch>(`/api/ingestion/batches/${batchId}`),
  },
};

// ─── Display helpers ────────────────────────────────────────────────────────
// Kept here so score formatting and colour banding cannot drift between pages.

export const GRADE_BANDS: Record<Grade, { min: number; label: string }> = {
  A: { min: 90, label: "Excellent" },
  B: { min: 80, label: "Good" },
  C: { min: 70, label: "Satisfactory" },
  D: { min: 60, label: "Needs improvement" },
  F: { min: 0, label: "Unsatisfactory" },
};

export function gradeFor(score: number | null): Grade | null {
  if (score === null || score === undefined) return null;
  if (score >= 90) return "A";
  if (score >= 80) return "B";
  if (score >= 70) return "C";
  if (score >= 60) return "D";
  return "F";
}

/** Renders "N/A" for an inapplicable criterion. Never render it as 0 — the
 *  backend excludes it from the total, and showing 0 misrepresents the agent. */
export function formatScore(score: CriterionScore): string {
  if (!score.is_applicable) return "N/A";
  if (score.raw_score === null) return "—";
  if (score.scoring_type === "binary") return score.raw_score >= 1 ? "Met" : "Not met";
  return `${score.raw_score} / ${score.max_score}`;
}

export function formatDuration(seconds: number | null): string {
  if (seconds === null || seconds === undefined) return "—";
  const m = Math.floor(seconds / 60);
  const s = seconds % 60;
  return `${m}m ${String(s).padStart(2, "0")}s`;
}

/** Splits full_text into segments so a cited range can be wrapped and
 *  highlighted. Uses stored offsets — never a text search. */
export function highlightSegments(
  fullText: string,
  ranges: Array<{ char_start: number; char_end: number; polarity?: string }>,
): Array<{ text: string; highlighted: boolean; polarity?: string }> {
  const sorted = [...ranges]
    .filter((r) => r.char_start != null && r.char_end != null)
    .sort((a, b) => a.char_start - b.char_start);

  const out: Array<{ text: string; highlighted: boolean; polarity?: string }> = [];
  let cursor = 0;
  for (const range of sorted) {
    if (range.char_start < cursor) continue; // skip overlaps
    if (range.char_start > cursor) {
      out.push({ text: fullText.slice(cursor, range.char_start), highlighted: false });
    }
    out.push({
      text: fullText.slice(range.char_start, range.char_end),
      highlighted: true,
      polarity: range.polarity,
    });
    cursor = range.char_end;
  }
  if (cursor < fullText.length) {
    out.push({ text: fullText.slice(cursor), highlighted: false });
  }
  return out;
}
