import os
import json
import faiss
import numpy as np
from ai.config import embedder


async def pre_embedding(directory: str) -> list[dict]:
    findings: list[dict] = []
    for json_file in os.listdir(directory):
        with open(os.path.join(directory, json_file), 'r') as f:
            json_data = json.load(f)
            for item in json_data:
                item["reference_tool"] = os.path.basename(json_file).split('.')[0]
                findings.append(item)

    return findings


def json_to_text(finding: dict) -> str:
    text = f"Name: {finding['name']}, Severity: {finding['severity']}, Description: {finding['description']}, "
    text += f"Resource Type: {finding['affected_resource']['resource_type']}, "
    text += f"Resource Name: {finding['affected_resource']['resource_name']}, "
    text += f"Namespace: {finding['affected_resource']['namespace']}, "
    text += f"Reference Links: {', '.join(finding['reference_links'])}, "
    text += f"Reference Tool: {finding['reference_tool']}"

    return text


async def store_embeddings(findings: list[str]) -> faiss.IndexFlatL2:
    embeddings: np.ndarray = embedder.encode(findings)
    dimension = embeddings.shape[1]

    index = faiss.IndexFlatL2(dimension)
    # noinspection PyArgumentList
    index.add(embeddings)

    return index
