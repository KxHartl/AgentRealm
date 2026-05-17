"""Document ingestion pipeline for the RAG knowledge base (V2.4).

Reads from:
  1. Local project data: data/rag/sources/
  2. Global AgentBrain:  Path defined in GLOBAL_BRAIN_PATH (.env)

Writes to:   data/rag/parsed/   (local project context only)
Builds:      data/rag/vector_store/  (local project ChromaDB)
"""

import os
import sys
import re
import urllib.request
from typing import List
from dotenv import load_dotenv

from langchain_community.document_loaders import TextLoader, PyPDFLoader
from langchain_community.vectorstores import Chroma
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_core.documents import Document

# Import the shared embedding provider
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
from rag_core.embeddings import get_embeddings

# Load environment variables
load_dotenv()

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
_WORKSPACE_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
_SOURCES_DIR = os.path.join(_WORKSPACE_ROOT, "data", "rag", "sources")
_PROJECT_KNOWLEDGE_DIR = os.path.join(_WORKSPACE_ROOT, "ai", "knowledge")
_PARSED_DIR = os.path.join(_WORKSPACE_ROOT, "data", "rag", "parsed")
_VECTOR_STORE_DIR = os.path.join(_WORKSPACE_ROOT, "data", "rag", "vector_store")

# Global Brain Path (resolving ~ if present)
_RAW_BRAIN_PATH = os.getenv("GLOBAL_BRAIN_PATH", "~/.agentbrain")
_GLOBAL_BRAIN_DIR = os.path.expanduser(_RAW_BRAIN_PATH)

# Core governance files
_GOVERNANCE_FILES = ["AGENTS.md", "STATE.md", "README.md", "GEMINI.md", "CLAUDE.md"]

# ---------------------------------------------------------------------------
# Supported extensions
# ---------------------------------------------------------------------------
_TEXT_EXTENSIONS = {".md", ".tex", ".txt", ".py", ".yaml", ".yml"}
_PDF_EXTENSIONS = {".pdf"}


def _load_url(url: str) -> List[Document]:
    """Fetch webpage or YouTube transcript and return as a List of Documents."""
    url = url.strip()
    if not url:
        return []

    print(f"    Fetching: {url}...")
    
    # 1. Check if it is a YouTube URL
    if "youtube.com" in url or "youtu.be" in url:
        try:
            from youtube_transcript_api import YouTubeTranscriptApi
            # Extract video ID
            video_id = None
            if "youtube.com/watch" in url:
                video_id = url.split("v=")[1].split("&")[0]
            elif "youtu.be/" in url:
                video_id = url.split("youtu.be/")[1].split("?")[0]
                
            if video_id:
                transcript_list = YouTubeTranscriptApi.get_transcript(video_id, languages=['hr', 'en', 'de'])
                text = " ".join([t['text'] for t in transcript_list])
                return [Document(
                    page_content=text,
                    metadata={"source": url, "title": f"YouTube Video: {video_id}", "source_type": "youtube_video"}
                )]
        except Exception as e:
            print(f"      Warning: YouTube transcription failed: {e}")
            pass

    # 2. Treat as generic webpage
    try:
        req = urllib.request.Request(
            url, 
            headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'}
        )
        with urllib.request.urlopen(req, timeout=10) as response:
            html = response.read()
            
        try:
            from bs4 import BeautifulSoup
            soup = BeautifulSoup(html, 'html.parser')
            # Extract title
            title = soup.title.string if soup.title else url
            # Remove scripts and style elements
            for script in soup(["script", "style", "header", "footer", "nav"]):
                script.decompose()
            # Extract clean text
            text = soup.get_text(separator="\n")
            # Clear multiple empty lines
            text = re.sub(r'\n+', '\n', text).strip()
            return [Document(
                page_content=text,
                metadata={"source": url, "title": title, "source_type": "web_page"}
            )]
        except Exception:
            # Native raw html regex-based text extractor fallback
            text_raw = html.decode('utf-8', errors='ignore')
            text_clean = re.sub('<[^<]+?>', '', text_raw)
            return [Document(
                page_content=text_clean.strip(),
                metadata={"source": url, "title": url, "source_type": "web_page"}
            )]
    except Exception as e:
        print(f"      Warning: Failed to fetch webpage {url}: {e}")
        
    return []


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
    """Load documents from Local Sources, Global Brain, and Governance."""
    documents = []

    # 1. Load Local Project Data
    print(f"  Scanning Local Sources: {_SOURCES_DIR}...")
    if os.path.isdir(_SOURCES_DIR):
        for root, _, files in os.walk(_SOURCES_DIR):
            for f in files:
                ext = os.path.splitext(f)[1].lower()
                if ext in _TEXT_EXTENSIONS | _PDF_EXTENSIONS:
                    filepath = os.path.join(root, f)
                    docs = _load_file(filepath)
                    for doc in docs:
                        doc.metadata["file_type"] = ext
                        doc.metadata["source_type"] = "project_data"
                        doc.metadata["origin"] = "local_rag"
                    documents.extend(docs)
                    print(f"    + {os.path.relpath(filepath, _WORKSPACE_ROOT)}")

        # 1.5 Load Online Web & Video Links
        links_file = os.path.join(_SOURCES_DIR, "links.txt")
        if os.path.isfile(links_file):
            print(f"  Reading Online Links: {links_file}...")
            try:
                with open(links_file, "r", encoding="utf-8") as f:
                    for line in f:
                        line = line.strip()
                        if line.startswith(("http://", "https://")):
                            docs = _load_url(line)
                            for doc in docs:
                                doc.metadata["file_type"] = ".html"
                                doc.metadata["source_type"] = "scraped_online"
                                doc.metadata["origin"] = "web_scraping"
                            documents.extend(docs)
            except Exception as e:
                print(f"  Warning: Failed to read links file: {e}")
    else:
        print(f"  Warning: {_SOURCES_DIR} does not exist.")

    # 2. Load Local Project Knowledge (Lessons Learned)
    print(f"  Scanning Local Knowledge: {_PROJECT_KNOWLEDGE_DIR}...")
    if os.path.isdir(_PROJECT_KNOWLEDGE_DIR):
        for root, _, files in os.walk(_PROJECT_KNOWLEDGE_DIR):
            for f in files:
                ext = os.path.splitext(f)[1].lower()
                if ext in _TEXT_EXTENSIONS:
                    filepath = os.path.join(root, f)
                    docs = _load_file(filepath)
                    for doc in docs:
                        doc.metadata["file_type"] = ext
                        doc.metadata["source_type"] = "project_knowledge"
                        doc.metadata["origin"] = "local_ai"
                    documents.extend(docs)
                    print(f"    + {os.path.relpath(filepath, _WORKSPACE_ROOT)}")

    # 3. Load Global AgentBrain Knowledge
    print(f"  Scanning Global Brain: {_GLOBAL_BRAIN_DIR}...")
    if os.path.isdir(_GLOBAL_BRAIN_DIR):
        for root, _, files in os.walk(_GLOBAL_BRAIN_DIR):
            # Skip .git folder
            if ".git" in root:
                continue
            for f in files:
                ext = os.path.splitext(f)[1].lower()
                if ext in _TEXT_EXTENSIONS:
                    filepath = os.path.join(root, f)
                    docs = _load_file(filepath)
                    for doc in docs:
                        doc.metadata["file_type"] = ext
                        doc.metadata["source_type"] = "global_skill"
                        doc.metadata["origin"] = "agentbrain"
                    documents.extend(docs)
                    print(f"    + [Global] {f}")
    else:
        print(f"  Warning: Global Brain not found at {_GLOBAL_BRAIN_DIR}.")

    # 4. Load governance files from root
    print("  Scanning Governance files...")
    for gf in _GOVERNANCE_FILES:
        gf_path = os.path.join(_WORKSPACE_ROOT, gf)
        # Check in root first, then .ai/config/ as fallback
        if not os.path.isfile(gf_path):
            gf_path = os.path.join(_WORKSPACE_ROOT, "ai", "config", gf)
            
        if os.path.isfile(gf_path):
            docs = _load_file(gf_path)
            for doc in docs:
                doc.metadata["file_type"] = ".md"
                doc.metadata["source_type"] = "governance"
                doc.metadata["origin"] = "root"
            documents.extend(docs)
            print(f"    + {os.path.basename(gf_path)}")

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
            f.write(f"<!-- Source: {source} -->\n")
            f.write(f"<!-- Type: {doc.metadata.get('source_type', 'unknown')} -->\n\n")
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
    print("=== AgentRealm RAG Ingestion (V2.4) ===")
    print(f"  Local Data:   {_SOURCES_DIR}")
    print(f"  Global Brain: {_GLOBAL_BRAIN_DIR}")
    print(f"  Vector DB:    {_VECTOR_STORE_DIR}")
    print()

    documents = load_sources()
    if not documents:
        print("  No documents found. Check sources and retry.")
        return

    print(f"\n  Total documents loaded: {len(documents)}")
    save_parsed_markdown(documents)
    print("  Parsed markdown saved locally.")

    build_vector_store(documents)
    print("\n=== Ingestion Complete ===")


if __name__ == "__main__":
    ingest()
