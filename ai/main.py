import asyncio
import os.path
import sys
import pickle
import faiss
import warnings
from ai.rag.retrieve import search_similar
from ai.rag.store import pre_embedding, json_to_text, store_embeddings
from ai.rag.load import load_documents
from ai.llms.open_ai_utils import open_ai_completion

JSON_DOCUMENTS_PATH = 'ai/rag/loaders/jsons'
VECTOR_PATH = 'ai/rag/vectors'

warnings.simplefilter(action='ignore', category=FutureWarning)

SYSTEM_PROMPT = """
"""


async def main():
    # --- main.py setup <vector> --- #
    if 2 < len(sys.argv):
        os.makedirs(VECTOR_PATH, exist_ok=True)
        os.makedirs(JSON_DOCUMENTS_PATH, exist_ok=True)

        await load_documents(JSON_DOCUMENTS_PATH, sys.argv[2])

        findings = list(map(lambda finding: json_to_text(finding), await pre_embedding(JSON_DOCUMENTS_PATH)))
        with open(f'{VECTOR_PATH}/findings.pkl', 'wb') as f:
            pickle.dump(findings, f)

        index = await store_embeddings(findings)
        faiss.write_index(index, f'{VECTOR_PATH}/faiss_index.bin')

    # --- main.py prompt --- #
    else:
        if not os.path.exists(f'{VECTOR_PATH}/faiss_index.bin'):
            print("vector db wasn't setup. run ./kte.sh ai setup <vector>.")
            exit(1)

        index = faiss.read_index(f'{VECTOR_PATH}/faiss_index.bin')
        with open(f'{VECTOR_PATH}/findings.pkl', 'rb') as f:
            findings = pickle.load(f)

        query = input(">> ")
        system_context = "\n\n".join(await search_similar(index, findings, query))
        while True:
            payload = [
                {"role": "system", "content": f"Here are some relevant security findings:\n{system_context}"},
                {"role": "user", "content": f"{query}"}
            ]

            response = await open_ai_completion(payload)
            print(response)

            system_context += "\n\n" + query + "\n\n" + response + "\n\n"
            query = input(">> ")
            system_context += "\n\n".join(await search_similar(index, findings, query))


if __name__ == '__main__':
    asyncio.run(main())
