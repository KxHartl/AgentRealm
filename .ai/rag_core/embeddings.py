"""Embedding provider abstraction for the RAG system.

Reads `rag_mode` from .ai/config/project.yaml and returns the correct
embedding function. Supported modes:
  - "cloud"  → Google Generative AI Embeddings (requires API key)
  - "local"  → HuggingFace sentence-transformers (runs offline)
  - "none"   → RAG disabled, raises RuntimeError
"""

import os
from typing import Optional

_WORKSPACE_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
_CONFIG_PATH = os.path.join(_WORKSPACE_ROOT, "ai", "config", "project.yaml")


def _read_rag_mode() -> str:
    """Read rag_mode from project.yaml. Returns 'none' if not set."""
    try:
        with open(_CONFIG_PATH, "r", encoding="utf-8") as f:
            for line in f:
                if line.strip().startswith("rag_mode:"):
                    # Split by colon, take value, split by comment, take first part, strip
                    value = line.split(":", 1)[1].split("#")[0].strip().strip('"').strip("'")
                    return value
    except FileNotFoundError:
        pass
    return "none"


def get_embeddings(mode: Optional[str] = None):
    """Return the appropriate embedding function based on RAG mode.

    Args:
        mode: Override the project config. If None, reads from project.yaml.

    Returns:
        A LangChain Embeddings instance.

    Raises:
        RuntimeError: If RAG mode is 'none' or unsupported.
    """
    if mode is None:
        mode = _read_rag_mode()

    if mode == "cloud":
        from langchain_google_genai import GoogleGenerativeAIEmbeddings

        return GoogleGenerativeAIEmbeddings(model="models/text-embedding-004")

    elif mode == "local":
        from langchain_community.embeddings import HuggingFaceEmbeddings

        return HuggingFaceEmbeddings(model_name="all-MiniLM-L6-v2")

    elif mode == "none":
        raise RuntimeError(
            "RAG is not enabled. Re-bootstrap with: "
            "bootstrap-project.ps1 -name <name> -rag cloud|local"
        )
    else:
        raise ValueError(f"Unknown rag_mode: '{mode}'. Use 'none', 'cloud', or 'local'.")
