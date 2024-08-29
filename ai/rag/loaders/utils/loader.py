import json
from abc import ABC, abstractmethod


class Loader(ABC):
    @abstractmethod
    async def load(self) -> dict:
        raise NotImplementedError()

    @abstractmethod
    def preprocess(self, docs: [dict | str]) -> list[dict]:
        raise NotImplementedError()

    @staticmethod
    def export_json(preprocessed_docs: list[dict], path: str) -> None:
        with open(path, 'w') as f:
            json.dump(preprocessed_docs, f, indent=4)

    async def export(self, path: str) -> None:
        docs = await self.load()
        self.export_json(self.preprocess(docs), path)
