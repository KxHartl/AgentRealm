"""
Semantic Caching module for RAG Pipeline.
This module intercepts RAG queries and returns cached responses
if a semantically similar query was already processed.
"""

import os
import json
import math
import sys
from typing import Optional

# Ensure workspace root is in path to import embedding provider
_WORKSPACE_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
if _WORKSPACE_ROOT not in sys.path:
    sys.path.append(_WORKSPACE_ROOT)

from ai.rag_core.embeddings import get_embeddings

_CACHE_FILE = os.path.join(_WORKSPACE_ROOT, "data", "rag", "semantic_cache.json")

def _cosine_similarity(v1, v2) -> float:
    dot_product = sum(x * y for x, y in zip(v1, v2))
    magnitude1 = math.sqrt(sum(x * x for x in v1))
    magnitude2 = math.sqrt(sum(y * y for y in v2))
    if magnitude1 * magnitude2 == 0:
        return 0.0
    return dot_product / (magnitude1 * magnitude2)

def _load_cache() -> list:
    if not os.path.exists(_CACHE_FILE):
        return []
    try:
        with open(_CACHE_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return []

def _save_cache(data: list):
    os.makedirs(os.path.dirname(_CACHE_FILE), exist_ok=True)
    with open(_CACHE_FILE, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

def get_cached_response(query: str, threshold: float = 0.85) -> Optional[str]:
    """
    Check if a semantically similar query exists in the cache.
    """
    cache = _load_cache()
    if not cache:
        return None

    try:
        embeddings = get_embeddings()
        query_vector = embeddings.embed_query(query)
    except Exception as e:
        print(f"[Cache] Embedding generation failed: {e}")
        return None

    best_score = -1.0
    best_response = None

    for entry in cache:
        cached_vector = entry.get("vector")
        if cached_vector and len(cached_vector) == len(query_vector):
            score = _cosine_similarity(query_vector, cached_vector)
            if score > best_score:
                best_score = score
                best_response = entry.get("response")

    print(f"[Cache] Best semantic match score: {best_score:.4f} (threshold: {threshold})")
    if best_score >= threshold:
        print(f"[Cache] Semantic cache hit!")
        return best_response

    return None

def cache_response(query: str, response: str):
    """
    Store a new query and response in the semantic cache.
    """
    try:
        embeddings = get_embeddings()
        query_vector = embeddings.embed_query(query)
    except Exception as e:
        print(f"[Cache] Failed to embed query for caching: {e}")
        return

    cache = _load_cache()
    # Check if exact query is already cached to avoid duplicates
    for entry in cache:
        if entry.get("query") == query:
            entry["response"] = response
            entry["vector"] = query_vector
            _save_cache(cache)
            return

    cache.append({
        "query": query,
        "response": response,
        "vector": query_vector
    })
    _save_cache(cache)
    print(f"[Cache] Successfully cached query response.")
