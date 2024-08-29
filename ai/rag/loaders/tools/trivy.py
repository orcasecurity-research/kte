from ai.rag.loaders.utils.prometheus import PrometheusLoader


class TrivyLoader(PrometheusLoader):
    def __init__(self, url: str, proxy: str, metric: str):
        super().__init__(url, proxy, metric)

    def preprocess(self, docs: dict) -> list[dict]:
        preprocessed_docs: list[dict] = []
        for doc in docs["data"]["result"]:
            preprocessed_docs.append({
                "name": "Image vulnerability",
                "severity": doc["metric"]["severity"],
                "description": f"A vulnerability found for {doc["metric"]["image_repository"]}@{doc["metric"]["image_tag"]} used in a {doc["metric"]["resource_kind"]}",
                "affected_resource": {
                    "resource_type": doc["metric"]["resource_kind"],
                    "resource_name": doc["metric"]["resource_name"],
                    "namespace": doc["metric"]["namespace"]
                },
                "reference_links": []
            })

        return preprocessed_docs
