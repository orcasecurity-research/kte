import bs4
from ai.rag.loaders.utils.web import WebLoader


class PolarisLoader(WebLoader):
    def __init__(self, url: str, proxy: str):
        super().__init__(url, proxy)

    def preprocess(self, html: str) -> list[dict]:
        preprocessed_docs: list[dict] = []

        soup = bs4.BeautifulSoup(html, 'html.parser')
        for card in soup.find_all(class_="card namespace"):
            namespace = "" if card.find("h3").text == "Cluster Resources" else card.find("strong").text
            for resource in card.find_all(class_="resource-info"):
                if resource.find(class_="warning failure") or resource.find(class_="danger failure"):
                    resource_type = resource.find(class_="controller-type").text[:-1]
                    resource_name = resource.find("strong").text
                    for result in resource.find_all(class_="result-messages"):
                        for message in result.find_all(class_="message-list"):
                            if resource.find(class_="warning failure") or resource.find(class_="danger failure"):
                                preprocessed_docs.append({
                                    "name": f"{resource_type} {result.find('h4').text.strip()[:-1]} Misconfiguration",
                                    "severity": "medium" if message.find("warning failure") else "high",
                                    "description": f"{message.find(class_="message").text}",
                                    "affected_resource": {
                                        "resource_type": resource_type,
                                        "resource_name": resource_name,
                                        "namespace": namespace
                                    },
                                    "reference_links": [
                                        message.find("a")["href"]
                                    ]
                                })

        return preprocessed_docs
