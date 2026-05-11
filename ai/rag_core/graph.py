"""Corrective RAG graph built with LangGraph.

Flow: Retrieve -> Grade Documents -> (Conditional: Web Search) -> Generate
"""

from langgraph.graph import StateGraph, END

from .state import GraphState
from .nodes import retrieve, grade_documents, web_search, generate, decide_to_search


def build_graph() -> StateGraph:
    """Build and compile the CRAG state graph."""
    workflow = StateGraph(GraphState)

    # Add nodes
    workflow.add_node("retrieve", retrieve)
    workflow.add_node("grade_documents", grade_documents)
    workflow.add_node("web_search", web_search)
    workflow.add_node("generate", generate)

    # Define edges
    workflow.set_entry_point("retrieve")
    workflow.add_edge("retrieve", "grade_documents")
    workflow.add_conditional_edges(
        "grade_documents",
        decide_to_search,
        {
            "web_search": "web_search",
            "generate": "generate",
        },
    )
    workflow.add_edge("web_search", "generate")
    workflow.add_edge("generate", END)

    return workflow.compile()


def query(question: str) -> str:
    """Run a single question through the CRAG pipeline."""
    app = build_graph()
    result = app.invoke(
        {
            "question": question,
            "documents": [],
            "generation": "",
            "web_search_needed": False,
        }
    )
    return result.get("generation", "No answer generated.")


if __name__ == "__main__":
    import sys

    if len(sys.argv) < 2:
        print("Usage: python -m ai.rag_core.graph <question>")
        sys.exit(1)

    answer = query(" ".join(sys.argv[1:]))
    print("\n=== ANSWER ===")
    print(answer)
