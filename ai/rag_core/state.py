"""State definition for the Corrective RAG (CRAG) graph."""

from typing import List, TypedDict
from langchain_core.documents import Document


class GraphState(TypedDict):
    """Represents the state of the CRAG graph.

    Attributes:
        question: The user's input question.
        documents: List of retrieved documents from the vector store.
        generation: The LLM-generated answer.
        web_search_needed: Flag indicating if web search should be performed.
    """

    question: str
    documents: List[Document]
    generation: str
    web_search_needed: bool
