from abc import ABC, abstractmethod
from ai.rag.loaders.utils.loader import Loader


class HtmlLoader(Loader, ABC):
    def __init__(self, path: str):
        self.path = path

    async def load(self) -> str:
        with open(self.path, 'r') as f:
            return f.read()

    @abstractmethod
    def preprocess(self, html: str) -> list[dict]:
        raise NotImplementedError()
