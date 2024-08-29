import re
from ai.rag.loaders.utils.html import HtmlLoader


class KubeScoreLoader(HtmlLoader):
    def __init__(self, path: str):
        super().__init__(path)

    def preprocess(self, html: str) -> list[dict]:
        preprocessed_docs: list[dict] = []

        resources = html.split("path=")
        for i in range(len(resources)):
            if re.search(r'\[<span class="\w*">\w*</span>]', resources[i], re.DOTALL):
                resource = resources[i-1].split("\n")[-2][:-1].strip()
                resource_type = resource.split()[0].split('/')[-1]
                resource_name = resource.split()[1]
                namespace = resource.split()[-1]

                items = re.split(r'\[<span class="\w*">\w*</span>]', resources[i])

                for j in range(len(items)):
                    if 0 == j:
                        continue

                    name = items[j].split('\n')[0].strip()
                    description = items[j].split('\n')[1].strip()[2:]
                    description += f". {items[j].split('\n')[2].strip()}"

                    preprocessed_docs.append({
                        "name": name,
                        "severity": "low",
                        "description": description,
                        "affected_resource": {
                            "resource_type": resource_type,
                            "resource_name": resource_name,
                            "namespace": namespace
                        },
                        "reference_links": []
                    })

                    if 4 < len(items[j].split('\n')):  # more than one item per title
                        split_counter = 3
                        while len(items[j].split('\n')) - 1 > split_counter:
                            description = items[j].split('\n')[split_counter].strip()[2:]
                            description += items[j].split('\n')[split_counter+1].strip()
                            preprocessed_docs.append({
                                "name": name,
                                "severity": "low",
                                "description": description,
                                "affected_resource": {
                                    "resource_type": resource_type,
                                    "resource_name": resource_name,
                                    "namespace": namespace
                                },
                                "reference_links": []
                            })
                            split_counter += 2

                            if len(items) - 1 == j:  # last item contains the remaining next resource information
                                if len(items[j].split('\n')) - 2 == split_counter:
                                    break

        return preprocessed_docs
