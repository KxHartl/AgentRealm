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
    """Run a single question through the CRAG pipeline with Semantic Caching."""
    try:
        # Resolve imports dynamically to avoid circular dependencies
        import sys
        import os
        sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..")))
        from data.rag.cache import get_cached_response
        cached = get_cached_response(question)
        if cached:
            return cached
    except Exception as e:
        print(f"[Cache] Error checking cache: {e}")

    app = build_graph()
    result = app.invoke(
        {
            "question": question,
            "documents": [],
            "generation": "",
            "web_search_needed": False,
        }
    )
    answer = result.get("generation", "No answer generated.")
    
    if answer and "No LLM configured" not in answer:
        try:
            from data.rag.cache import cache_response
            cache_response(question, answer)
        except Exception as e:
            print(f"[Cache] Error storing in cache: {e}")

    return answer


if __name__ == "__main__":
    import sys

    if len(sys.argv) < 2:
        print("Usage: python -m ai.rag_core.graph <question>")
        sys.exit(1)

    answer = query(" ".join(sys.argv[1:]))
    print("\n=== ANSWER ===")
    print(answer)
