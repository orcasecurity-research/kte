import aiohttp
from abc import ABC, abstractmethod
from aiohttp_socks import ProxyConnector
from ai.rag.loaders.utils.loader import Loader


class PrometheusLoader(Loader, ABC):
    def __init__(self, url: str, proxy: str, metric: str):
        self.url = url
        self.proxy = proxy
        self.metric = metric

    async def load(self) -> dict:
        query = {"query": self.metric}
        async with aiohttp.ClientSession(connector=ProxyConnector.from_url(self.proxy)) as session:
            async with session.get(self.url, params=query) as response:
                if response.status == 200:
                    return await response.json()
                else:
                    print(f"Failed to query Prometheus: {response.status}")
                    return {}

    @abstractmethod
    def preprocess(self, docs: dict) -> list[dict]:
        raise NotImplementedError()
