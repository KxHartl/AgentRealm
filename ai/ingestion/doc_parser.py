"""Document ingestion pipeline for the RAG knowledge base.

Reads from:  data/rag/sources/  (raw PDFs, markdown, text)
Writes to:   data/rag/parsed/   (clean markdown per document)
Builds:      data/rag/vector_store/  (ChromaDB)

Embedding provider is determined by `rag_mode` in ai/config/project.yaml.
"""

import os
import sys
from typing import List

from langchain_community.document_loaders import TextLoader, PyPDFLoader
from langchain_community.vectorstores import Chroma
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_core.documents import Document

# Import the shared embedding provider
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
from rag_core.embeddings import get_embeddings

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
_WORKSPACE_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
_SOURCES_DIR = os.path.join(_WORKSPACE_ROOT, "data", "rag", "sources")
_PARSED_DIR = os.path.join(_WORKSPACE_ROOT, "data", "rag", "parsed")
_VECTOR_STORE_DIR = os.path.join(_WORKSPACE_ROOT, "data", "rag", "vector_store")

# Also index core governance files from the root
_GOVERNANCE_FILES = ["AGENTS.md", "STATE.md", "README.md"]

# ---------------------------------------------------------------------------
# Supported extensions
# ---------------------------------------------------------------------------
_TEXT_EXTENSIONS = {".md", ".tex", ".txt", ".py", ".yaml", ".yml"}
_PDF_EXTENSIONS = {".pdf"}


def _load_file(filepath: str) -> List[Document]:
    """Load a single file and return a list of Documents."""
    ext = os.path.splitext(filepath)[1].lower()
    try:
        if ext in _PDF_EXTENSIONS:
            return PyPDFLoader(filepath).load()
        elif ext in _TEXT_EXTENSIONS:
            return TextLoader(filepath, encoding="utf-8").load()
    except Exception as e:
        print(f"  Warning: Failed to load {filepath}: {e}")
    return []


def load_sources() -> List[Document]:
    """Load all documents from data/rag/sources/ and root governance files."""
    documents = []

    # 1. Load from data/rag/sources/
    if os.path.isdir(_SOURCES_DIR):
        for root, _, files in os.walk(_SOURCES_DIR):
            for f in files:
                ext = os.path.splitext(f)[1].lower()
                if ext in _TEXT_EXTENSIONS | _PDF_EXTENSIONS:
                    filepath = os.path.join(root, f)
                    docs = _load_file(filepath)
                    # Add metadata
                    for doc in docs:
                        doc.metadata["file_type"] = ext
                        doc.metadata["origin"] = "rag_sources"
                    documents.extend(docs)
                    print(f"  Loaded: {os.path.relpath(filepath, _WORKSPACE_ROOT)}")
    else:
        print(f"  Warning: {_SOURCES_DIR} does not exist.")

    # 2. Load governance files from root
    for gf in _GOVERNANCE_FILES:
        gf_path = os.path.join(_WORKSPACE_ROOT, gf)
        if os.path.isfile(gf_path):
            docs = _load_file(gf_path)
            for doc in docs:
                doc.metadata["file_type"] = ".md"
                doc.metadata["origin"] = "governance"
            documents.extend(docs)
            print(f"  Loaded: {gf}")

    return documents


def save_parsed_markdown(documents: List[Document]) -> None:
    """Save loaded documents as clean markdown files in data/rag/parsed/."""
    os.makedirs(_PARSED_DIR, exist_ok=True)
    for i, doc in enumerate(documents):
        source = doc.metadata.get("source", f"doc_{i}")
        safe_name = os.path.basename(source).replace(" ", "_")
        safe_name = os.path.splitext(safe_name)[0] + ".md"
        out_path = os.path.join(_PARSED_DIR, safe_name)

        with open(out_path, "w", encoding="utf-8") as f:
            f.write(f"<!-- Source: {source} -->\n\n")
            f.write(doc.page_content)


def build_vector_store(documents: List[Document]) -> None:
    """Chunk documents and build ChromaDB vector store."""
    splitter = RecursiveCharacterTextSplitter(
        chunk_size=1000,
        chunk_overlap=150,
        separators=["\n## ", "\n### ", "\n\n", "\n", " ", ""],
    )
    chunks = splitter.split_documents(documents)
    print(f"  Split into {len(chunks)} chunks.")

    embeddings = get_embeddings()
    Chroma.from_documents(
        documents=chunks,
        embedding=embeddings,
        persist_directory=_VECTOR_STORE_DIR,
    )
    print(f"  Vector store built at: {_VECTOR_STORE_DIR}")


def ingest() -> None:
    """Full ingestion pipeline: load -> parse -> vectorize."""
    print("=== RAG Ingestion Pipeline ===")
    print(f"  Sources:      {_SOURCES_DIR}")
    print(f"  Parsed:       {_PARSED_DIR}")
    print(f"  Vector Store: {_VECTOR_STORE_DIR}")
    print()

    documents = load_sources()
    if not documents:
        print("  No documents found. Add files to data/rag/sources/ and retry.")
        return

    print(f"\n  Total documents loaded: {len(documents)}")
    save_parsed_markdown(documents)
    print("  Parsed markdown saved.")

    build_vector_store(documents)
    print("\n=== Ingestion Complete ===")


if __name__ == "__main__":
    ingest()
