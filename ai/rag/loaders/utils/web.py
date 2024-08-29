import aiohttp
from abc import ABC, abstractmethod
from aiohttp_socks import ProxyConnector
from ai.rag.loaders.utils.loader import Loader


class WebLoader(Loader, ABC):
    def __init__(self, url: str, proxy: str):
        self.url = url
        self.proxy = proxy

    async def load(self) -> str:
        async with aiohttp.ClientSession(connector=ProxyConnector.from_url(self.proxy)) as session:
            async with session.get(self.url) as response:
                if response.status == 200:
                    return await response.text()
                else:
                    print(f"Failed to query Prometheus: {response.status}")
                    return ""

    @abstractmethod
    def preprocess(self, html: str) -> list[dict]:
        raise NotImplementedError()
