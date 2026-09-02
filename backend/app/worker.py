"""Background job worker.

Run:  python -m app.worker

Consumes the `jobs` table using `claim_next_job()`, which dequeues atomically
with FOR UPDATE SKIP LOCKED. Several workers can run concurrently and will each
claim different rows rather than contending for the same one.

WHY A POSTGRES QUEUE AND NOT CELERY/REDIS
-----------------------------------------
The project already runs Postgres. A jobs table adds no new service to deploy,
survives restarts, and is inspectable with SQL — which also means the ingestion
UI can show queue depth without a separate broker API. For a workload measured
in tens of jobs per minute, the throughput argument for Redis does not apply.

Crashed workers are handled by `reclaim_stale_jobs()`, called on startup and
periodically: a job locked longer than the visibility timeout is requeued with
exponential backoff, or marked dead once it exhausts its attempts.
"""

import asyncio
import logging
import signal
import sys

from app import db
from app.config import get_settings
from app.llm import close_provider
from app.services import evaluation_service

settings = get_settings()

logging.basicConfig(
    level=settings.log_level,
    format="%(asctime)s %(levelname)-8s %(name)s: %(message)s",
)
log = logging.getLogger("worker")

_shutdown = asyncio.Event()


async def handle_job(job: dict) -> dict:
    job_type = job["job_type"]

    if job_type in ("evaluate", "reevaluate"):
        payload = job["payload"] or {}
        return await evaluation_service.run_evaluation(
            call_id=job["call_id"],
            evaluation_id=job["evaluation_id"],
            trigger_reason=payload.get("reason") or payload.get("trigger_reason") or job_type,
        )

    raise NotImplementedError(f"Job type '{job_type}' is not handled yet.")


async def process_one() -> bool:
    """Claim and run one job. Returns False when the queue is empty."""
    row = await db.fetchrow(
        "select * from claim_next_job($1, $2::job_type[])",
        settings.worker_id, ["evaluate", "reevaluate"],
    )
    if not row or not row.get("id"):
        return False

    job_id = row["id"]
    log.info("claimed job %s (%s, attempt %s)", job_id, row["job_type"], row["attempts"])

    try:
        result = await handle_job(row)
    except Exception as exc:  # noqa: BLE001
        # Retry with backoff until max_attempts, then mark dead. Recording the
        # error on every attempt means a job that eventually succeeds still shows
        # what went wrong on the way.
        exhausted = row["attempts"] >= row["max_attempts"]
        await db.execute(
            """
            update jobs
               set status = case when $2 then 'dead'::job_status else 'queued'::job_status end,
                   error_message = $3,
                   locked_at = null, locked_by = null,
                   scheduled_at = now() + (interval '1 minute' * power(2, attempts)),
                   completed_at = case when $2 then now() else null end
             where id = $1
            """,
            job_id, exhausted, str(exc)[:2000],
        )
        log.error("job %s failed (%s): %s", job_id, "dead" if exhausted else "requeued", exc)
        return True

    await db.execute(
        """
        update jobs set status = 'completed', result = $2::jsonb, completed_at = now()
         where id = $1
        """,
        job_id, result,
    )
    log.info("job %s completed", job_id)
    return True


async def run() -> None:
    await db.connect()
    reclaimed = await db.fetchval(
        "select reclaim_stale_jobs($1)", settings.worker_job_timeout_minutes
    )
    if reclaimed:
        log.warning("reclaimed %s stale job(s) from a previous run", reclaimed)

    log.info(
        "worker %s started (mock_llm=%s, poll=%ss)",
        settings.worker_id, settings.mock_llm, settings.worker_poll_interval_seconds,
    )

    idle_cycles = 0
    try:
        while not _shutdown.is_set():
            try:
                did_work = await process_one()
            except Exception:  # noqa: BLE001 - the loop must survive anything
                log.exception("worker loop error")
                did_work = False

            if did_work:
                idle_cycles = 0
                continue

            idle_cycles += 1
            # Reclaim periodically rather than every cycle: it is a table scan,
            # and once a minute of idling is often enough.
            if idle_cycles % 12 == 0:
                await db.fetchval(
                    "select reclaim_stale_jobs($1)", settings.worker_job_timeout_minutes
                )

            try:
                await asyncio.wait_for(
                    _shutdown.wait(), timeout=settings.worker_poll_interval_seconds
                )
            except asyncio.TimeoutError:
                pass
    finally:
        await close_provider()
        await db.disconnect()
        log.info("worker stopped")


def main() -> None:
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)

    def request_shutdown(*_):
        log.info("shutdown signal received — finishing current job")
        loop.call_soon_threadsafe(_shutdown.set)

    for sig in (signal.SIGINT, signal.SIGTERM):
        signal.signal(sig, request_shutdown)

    try:
        loop.run_until_complete(run())
    finally:
        loop.close()


if __name__ == "__main__":
    sys.exit(main())
