# data/

**All datasets live here**, strictly separated into two categories:

## `data/rag/` — LLM Knowledge Base (Read-Only)

Immutable reference material used by the CRAG pipeline to provide context to the LLM.

| Subdirectory | Purpose |
|---|---|
| `sources/` | Original PDFs, textbooks, lecture slides |
| `parsed/` | Clean Markdown extracted by `.ai/ingestion/doc_parser.py` |
| `vector_store/` | ChromaDB vector database (auto-generated) |

> **Rule**: AI agents must NEVER write generated code, outputs, or operational data here.

## `data/process/` — Project Working Data (Read-Write)

Mutable data used, manipulated, or generated during your project execution.

| Subdirectory | Purpose |
|---|---|
| `raw/` | Project-specific raw inputs (measurements, images, datasets) |
| `intermediate/` | Data currently being cleaned or processed |
| `output/` | Final charts, reports, CSV/JSON results |
