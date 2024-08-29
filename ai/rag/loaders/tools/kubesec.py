import re
import bs4
import json
from ai.rag.loaders.utils.html import HtmlLoader


class KubeSecLoader(HtmlLoader):
    def __init__(self, path: str):
        super().__init__(path)

    def preprocess(self, html: str) -> list[dict]:
        preprocessed_docs: list[dict] = []

        soup = bs4.BeautifulSoup(html, 'html.parser')
        json_data_match = re.search(
            r"const jsonData = (\[\{.*\}\])",
            soup.find("script", string=re.compile(r"const jsonData")).string,
            re.DOTALL
        )

        json_data = []
        if json_data_match:
            json_data_content = json_data_match.group(1)
            json_data = json.loads(json_data_content)

        for item in json_data:
            resource_type = item["object"].split('/')[0]
            resource_name = item["object"].split('/')[1].split('.')[0]
            namespace = item["object"].split('.')[1]
            if item["score"] > 0:
                for advise in item["scoring"]["advise"]:
                    preprocessed_docs.append({
                        "name": f"{advise["id"]} Misconfiguration",
                        "severity": "low" if advise["points"] == 1 else ("medium" if advise["points"] == 2 else "high"),
                        "description": advise["reason"],
                        "affected_resource": {
                            "resource_type": resource_type,
                            "resource_name": resource_name,
                            "namespace": namespace if not resource_name.startswith("Cluster") else ""
                        },
                        "reference_links": []
                    })

        return preprocessed_docs
