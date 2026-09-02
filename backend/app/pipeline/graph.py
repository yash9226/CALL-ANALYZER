"""LangGraph orchestration of the evaluation pipeline.

THE SHAPE
---------
                        ┌──────────────┐
                        │ preprocessing│  deterministic, no LLM
                        └──────┬───────┘
              ┌────────────┬───┴────┬────────────┐
              ▼            ▼        ▼            ▼
         ┌────────┐  ┌─────────┐ ┌──────┐  ┌─────────┐
         │scoring │  │sentiment│ │ risk │  │ summary │   concurrent
         └────┬───┘  └────┬────┘ └───┬──┘  └────┬────┘
              └───────────┴──────┬───┴──────────┘
                                 ▼
                          ┌─────────────┐
                          │ aggregation │  pure SQL, no LLM
                          └─────────────┘

WHY THE FAN-OUT MATTERS
-----------------------
Those four agents are genuinely independent: none reads another's output. Running
them concurrently makes an evaluation take about as long as its slowest agent
rather than the sum of all four. Preprocessing must come first because it
computes the conversation statistics the scoring prompt uses as evidence, and
aggregation must come last because it rolls up whatever scoring produced.

WHY LANGGRAPH RATHER THAN asyncio.gather
----------------------------------------
The concurrency itself is four lines of asyncio. What the graph buys is that the
pipeline's STRUCTURE is declared as data rather than buried in control flow: it
can be rendered as a diagram (see `render_mermaid()`), a node can be added
without touching the ones around it, and the fan-out/fan-in is explicit rather
than implied by where the awaits happen to sit.
"""

import logging
import operator
from typing import Annotated, Any, TypedDict

from langgraph.graph import END, START, StateGraph

from app.agents import (
    PipelineContext,
    PreprocessingAgent,
    RiskAgent,
    ScoringAgent,
    SentimentAgent,
    SummaryAgent,
)
from app.pipeline.aggregator import aggregate

log = logging.getLogger(__name__)


class PipelineState(TypedDict):
    """Graph state.

    `ctx` is a single mutable PipelineContext shared by every node — the agents
    also persist their own output, so the graph state stays small.

    `completed` and `failed` use operator.add reducers because the four parallel
    branches all write to them at once; without a reducer LangGraph raises a
    concurrent-update error.
    """

    ctx: PipelineContext
    completed: Annotated[list[str], operator.add]
    failed: Annotated[list[str], operator.add]


def _node(agent_cls):
    """Wrap an Agent class as a graph node."""
    agent = agent_cls()

    async def run_node(state: PipelineState) -> dict[str, Any]:
        result = await agent.run(state["ctx"])
        if result is None:
            # run() returns None when a NON-critical agent failed; it re-raises
            # for critical ones, so reaching here means a tolerable failure.
            return {"failed": [agent.name]}
        return {"completed": [agent.name]}

    run_node.__name__ = f"{agent.name}_node"
    return run_node


async def _aggregate_node(state: PipelineState) -> dict[str, Any]:
    await aggregate(state["ctx"])
    return {"completed": ["aggregation"]}


def build_graph():
    """Assemble and compile the pipeline graph."""
    graph = StateGraph(PipelineState)

    graph.add_node("preprocessing", _node(PreprocessingAgent))
    graph.add_node("scoring", _node(ScoringAgent))
    graph.add_node("sentiment", _node(SentimentAgent))
    graph.add_node("risk", _node(RiskAgent))
    graph.add_node("summary", _node(SummaryAgent))
    graph.add_node("aggregation", _aggregate_node)

    graph.add_edge(START, "preprocessing")

    # Fan out. Four edges from one node is how LangGraph expresses concurrency.
    for parallel in ("scoring", "sentiment", "risk", "summary"):
        graph.add_edge("preprocessing", parallel)
        graph.add_edge(parallel, "aggregation")

    graph.add_edge("aggregation", END)
    return graph.compile()


_compiled = None


def get_graph():
    """Compile once and reuse. Compilation is not free and the graph is static."""
    global _compiled
    if _compiled is None:
        _compiled = build_graph()
        log.info("evaluation pipeline graph compiled")
    return _compiled


def render_mermaid() -> str:
    """Mermaid source for the compiled graph.

    Exposed at GET /api/evaluations/pipeline/graph so the architecture diagram in
    the report is generated from the code that actually runs, rather than drawn
    by hand and left to drift.
    """
    return get_graph().get_graph().draw_mermaid()
