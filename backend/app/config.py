"""Application settings, loaded once from the repo-root .env.

Every tunable lives here rather than being read from os.environ at the point of
use, so the whole configuration surface is visible in one file and typos fail at
startup instead of at 2am inside a worker.
"""

from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

# .env sits at the repository root, one level above backend/.
ENV_FILE = Path(__file__).resolve().parents[2] / ".env"


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=ENV_FILE, env_file_encoding="utf-8", extra="ignore"
    )

    # ── Database ────────────────────────────────────────────────────────────
    database_url: str = "postgresql://postgres:postgres@127.0.0.1:54422/postgres"
    db_pool_min_size: int = 2
    db_pool_max_size: int = 10

    # ── Supabase ────────────────────────────────────────────────────────────
    supabase_url: str = "http://127.0.0.1:54421"
    supabase_anon_key: str = ""
    supabase_service_role_key: str = ""
    # Used to verify the HS256 JWTs Supabase Auth issues to the React client.
    supabase_jwt_secret: str = ""

    # ── Auth ────────────────────────────────────────────────────────────────
    # When true, unauthenticated requests are treated as an admin. Convenience
    # for local development and the Lovable frontend before auth is wired up.
    # main.py refuses to start if this is ever true alongside a non-local
    # database URL, so it cannot reach production by accident.
    auth_dev_bypass: bool = False

    # ── LLM (consumed in Phase 3; declared here so config stays in one place) ─
    llm_provider: str = "gemini"
    gemini_api_key: str = ""
    gemini_scoring_model: str = "gemini-3.6-flash"
    gemini_summary_model: str = "gemini-3.6-flash"
    gemini_chat_model: str = "gemini-3.6-flash"
    gemini_transcribe_model: str = "gemini-3.5-transcribe"
    gemini_embedding_model: str = "gemini-embedding-2"
    llm_fallback_models: str = "gemini-3.6-flash,gemini-3.1-flash-lite"
    embedding_dimensions: int = 768
    mock_llm: bool = False
    llm_max_retries: int = 4
    llm_timeout_seconds: int = 120
    llm_backoff_base_seconds: int = 2
    debug_capture_io: bool = True

    # ── Worker ──────────────────────────────────────────────────────────────
    worker_id: str = "worker-local-1"
    worker_poll_interval_seconds: int = 5
    worker_job_timeout_minutes: int = 15

    # ── API ─────────────────────────────────────────────────────────────────
    api_host: str = "0.0.0.0"
    api_port: int = 8000
    api_cors_origins: str = "http://localhost:5173,http://localhost:3000"
    log_level: str = "INFO"

    # ── Ingestion limits ────────────────────────────────────────────────────
    max_upload_bytes: int = 25 * 1024 * 1024     # 25 MB
    max_batch_rows: int = 5000

    @property
    def cors_origin_list(self) -> list[str]:
        return [o.strip() for o in self.api_cors_origins.split(",") if o.strip()]

    @property
    def fallback_model_list(self) -> list[str]:
        return [m.strip() for m in self.llm_fallback_models.split(",") if m.strip()]

    @property
    def is_local_database(self) -> bool:
        return any(h in self.database_url for h in ("127.0.0.1", "localhost", "@db:"))


@lru_cache
def get_settings() -> Settings:
    return Settings()
