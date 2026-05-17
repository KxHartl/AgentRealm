# Agent Task: Priority Improvements

## Goal
Implement the core infrastructure upgrades for AgentRealm, specifically focusing on Multi-modal RAG, Local LLM Orchestration, Semantic Caching, and Tracing.

## Requirements

1. **Multi-modal RAG (`data/rag/vision_parser.py`)**
   - Implement document parsing that extracts images and charts from PDFs.
   - Use `Unstructured` or `Docling` libraries.
   - Ensure the parsed visual context can be ingested into the RAG vector store.

2. **Semantic Caching (`data/rag/cache.py`)**
   - Implement a semantic cache using Redis or a local embedding-based cache (like GPTCache or a local FAISS index).
   - The RAG system should check the cache before calling external LLMs to save tokens.

3. **Local LLM Orchestration (Modify `bootstrap-project.ps1`)**
   - Add scaffolding to `bootstrap-project.ps1` to detect and optionally install/run Ollama or LocalAI if `rag_mode` is set to `local`.

4. **Tracing**
   - Add LangSmith or Langfuse scaffolding to RAG chains for observability.

## Instructions
Review the scaffolding files provided and complete their implementation. Ensure you commit your changes to this worktree (`task/priority-improvements`) and run tests before considering the task complete.
