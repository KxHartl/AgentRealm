"""Node functions for the Corrective RAG graph."""

import os
from typing import Any, Dict

from langchain_community.vectorstores import Chroma
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser

from langchain_core.documents import Document
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

def _generate_queries(question: str) -> list[str]:
    """Generate multiple versions of the question for RAG-fusion."""
    # In a production setting, use an LLM. Here's the logic for it.
    print(f"  Generating variations for: {question}")
    try:
        from langchain_google_genai import ChatGoogleGenerativeAI
        llm = ChatGoogleGenerativeAI(model="gemini-1.5-flash", temperature=0)
        prompt = ChatPromptTemplate.from_messages([
            ("system", "You are an AI assistant that generates three different versions of a user question to retrieve relevant documents from a vector database. \n"
                       "By generating multiple perspectives on the user query, your goal is to help the user overcome some of the limitations of distance-based similarity search. \n"
                       "Provide these alternative questions separated by newlines. No intro/outro."),
            ("human", "{question}")
        ])
        chain = prompt | llm | StrOutputParser()
        response = chain.invoke({"question": question})
        queries = [q.strip() for q in response.split("\n") if q.strip()]
        return queries[:3] + [question]
    except Exception as e:
        print(f"  Query generation failed, using original: {e}")
        return [question]

def _fuse_documents(all_docs: list[Document]) -> list[Document]:
    """Simple deduplication and fusion of documents."""
    # For a more advanced version, implement Reciprocal Rank Fusion (RRF)
    seen_contents = set()
    unique_docs = []
    for doc in all_docs:
        if doc.page_content not in seen_contents:
            unique_docs.append(doc)
            seen_contents.add(doc.page_content)
    return unique_docs

def _rerank_documents(question: str, documents: list[Document]) -> list[Document]:
    """Re-rank documents based on keyword overlap (lightweight Cross-Encoder alternative)."""
    # In production, use FlashRank or sentence-transformers cross-encoder.
    print(f"  Re-ranking {len(documents)} documents...")
    scored_docs = []
    keywords = set(question.lower().split())
    
    for doc in documents:
        content_lower = doc.page_content.lower()
        score = sum(2 for kw in keywords if kw in content_lower) # Keyword match
        # Boost if keyword is in the first 200 characters
        score += sum(1 for kw in keywords if kw in content_lower[:200])
        scored_docs.append((score, doc))
        
    # Sort by score descending
    scored_docs.sort(key=lambda x: x[0], reverse=True)
    return [doc for score, doc in scored_docs]

def retrieve(state: GraphState) -> Dict[str, Any]:
    """Retrieve documents from the local vector store with RAG-Fusion and Re-ranking."""
    print("--- RETRIEVE (FUSION & RERANK) ---")
    question = state["question"]
    db = _get_vector_store()
    
    # 1. RAG-Fusion
    queries = _generate_queries(question)
    
    all_docs = []
    for q in queries:
        docs = db.similarity_search(q, k=3)
        all_docs.extend(docs)
        
    # 2. Fusion
    unique_docs = _fuse_documents(all_docs)
    
    # 3. Re-ranking
    reranked_docs = _rerank_documents(question, unique_docs)
    
    return {"documents": reranked_docs, "question": question}


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
