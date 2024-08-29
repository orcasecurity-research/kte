import re
from ai.rag.loaders.utils.html import HtmlLoader


class CheckovLoader(HtmlLoader):
    def __init__(self, path: str):
        super().__init__(path)

    def preprocess(self, html: str) -> list[dict]:
        preprocessed_docs: list[dict] = []
        failed_checks = re.findall(r'Check:.*?<span class="failed">FAILED</span>.*?</a>', html, re.DOTALL)
        for check in failed_checks:
            name = re.search(r'&quot;(.*)&quot', check).group(1)
            resource = re.search(r'for resource: (.*?)\n\t', check).group(1)
            resource_type = resource.split('.')[0]
            resource_name = resource.split('.')[2]
            namespace = resource.split('.')[1]

            preprocessed_docs.append({
                "name": name,
                "severity": "medium",
                "description": name,
                "affected_resource": {
                    "resource_type": resource_type,
                    "resource_name": resource_name,
                    "namespace": namespace
                },
                "reference_links": [
                    re.search(r'Guide: <a href="(.*?)"', check).group(1)
                ]
            })

        return preprocessed_docs
