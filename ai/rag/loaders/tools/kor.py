from ai.rag.loaders.utils.prometheus import PrometheusLoader


class KorLoader(PrometheusLoader):
    def __init__(self, url: str, proxy: str, metric: str):
        super().__init__(url, proxy, metric)

    def preprocess(self, docs: dict) -> list[dict]:
        preprocessed_docs: list[dict] = []
        for doc in docs["data"]["result"]:
            preprocessed_docs.append({
                "name": "Unused orphaned resource",
                "severity": "low",
                "description": f"Unused orphaned resource {doc["metric"]["resourceName"]} from type {doc["metric"]["kind"]}",
                "affected_resource": {
                    "resource_type": doc["metric"]["kind"],
                    "resource_name": doc["metric"]["resourceName"],
                    "namespace": doc["metric"]["namespace"]
                },
                "reference_links": []
            })

        return preprocessed_docs
