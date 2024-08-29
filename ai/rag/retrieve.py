import faiss
from numpy import ndarray
from ai.config import embedder


async def search_similar(index: faiss.IndexFlatL2, findings: list[str], query: str, top_k=10) -> list[str]:
    query_embedding: ndarray = embedder.encode([query])
    # noinspection PyArgumentList
    _, indices = index.search(query_embedding, top_k)

    results = [findings[i] for i in indices[0]]
    return results
