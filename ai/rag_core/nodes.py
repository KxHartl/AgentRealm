"""Node functions for the Corrective RAG graph."""

import os
from typing import Any, Dict

from langchain_community.vectorstores import Chroma
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser

from .state import GraphState
from .embeddings import get_embeddings

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
_WORKSPACE_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
_VECTOR_STORE_PATH = os.path.join(_WORKSPACE_ROOT, "data", "rag", "vector_store")


def _get_vector_store() -> Chroma:
    """Load or connect to the persisted Chroma vector store."""
    embeddings = get_embeddings()
    return Chroma(
        persist_directory=_VECTOR_STORE_PATH,
        embedding_function=embeddings,
    )


# ---------------------------------------------------------------------------
# Graph Nodes
# ---------------------------------------------------------------------------

def retrieve(state: GraphState) -> Dict[str, Any]:
    """Retrieve documents from the local vector store."""
    print("--- RETRIEVE ---")
    question = state["question"]
    db = _get_vector_store()
    documents = db.similarity_search(question, k=5)
    return {"documents": documents, "question": question}


def grade_documents(state: GraphState) -> Dict[str, Any]:
    """Grade retrieved documents for relevance using a simple heuristic.

    If fewer than 2 documents contain query keywords, flag for web search.
    A production system would use an LLM grader here.
    """
    print("--- GRADE DOCUMENTS ---")
    question = state["question"]
    documents = state["documents"]

    keywords = set(question.lower().split())
    relevant_docs = []
    for doc in documents:
        content_lower = doc.page_content.lower()
        overlap = sum(1 for kw in keywords if kw in content_lower)
        if overlap >= max(1, len(keywords) // 3):
            relevant_docs.append(doc)

    web_search_needed = len(relevant_docs) < 2
    if web_search_needed:
        print(f"  Only {len(relevant_docs)} relevant docs found. Web search flagged.")
    else:
        print(f"  {len(relevant_docs)} relevant docs found. No web search needed.")

    return {
        "documents": relevant_docs,
        "question": question,
        "web_search_needed": web_search_needed,
    }


def web_search(state: GraphState) -> Dict[str, Any]:
    """Perform a web search to supplement local documents.

    Uses Tavily if available, otherwise returns a placeholder.
    """
    print("--- WEB SEARCH ---")
    question = state["question"]
    documents = state["documents"]

    try:
        from langchain_community.tools.tavily_search import TavilySearchResults

        tool = TavilySearchResults(max_results=3)
        results = tool.invoke({"query": question})
        from langchain_core.documents import Document

        for result in results:
            documents.append(
                Document(
                    page_content=result.get("content", ""),
                    metadata={"source": result.get("url", "web")},
                )
            )
        print(f"  Added {len(results)} web results.")
    except Exception as e:
        print(f"  Web search skipped: {e}")

    return {"documents": documents, "question": question}


def generate(state: GraphState) -> Dict[str, Any]:
    """Generate an answer using the filtered documents as context."""
    print("--- GENERATE ---")
    question = state["question"]
    documents = state["documents"]

    context = "\n\n---\n\n".join(doc.page_content for doc in documents)

    prompt = ChatPromptTemplate.from_messages(
        [
            (
                "system",
                "You are a helpful research assistant. Answer the question based "
                "ONLY on the following context. If the context is insufficient, "
                "say so. Cite sources when possible.\n\nContext:\n{context}",
            ),
            ("human", "{question}"),
        ]
    )

    # Try Google GenAI first, fall back to a simple chain
    try:
        from langchain_google_genai import ChatGoogleGenerativeAI

        llm = ChatGoogleGenerativeAI(model="gemini-2.5-flash", temperature=0)
    except Exception:
        # Fallback: return context summary without LLM
        return {
            "generation": f"[No LLM configured] Top context:\n{context[:500]}",
            "documents": documents,
            "question": question,
        }

    chain = prompt | llm | StrOutputParser()
    generation = chain.invoke({"context": context, "question": question})

    return {"generation": generation, "documents": documents, "question": question}


# ---------------------------------------------------------------------------
# Conditional Edge
# ---------------------------------------------------------------------------

def decide_to_search(state: GraphState) -> str:
    """Decide whether to perform a web search or go directly to generation."""
    if state.get("web_search_needed", False):
        return "web_search"
    return "generate"
