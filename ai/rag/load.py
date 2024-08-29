import bs4
from ai.rag.loaders.tools.kor import KorLoader
from ai.rag.loaders.tools.trivy import TrivyLoader
from ai.rag.loaders.tools.polaris import PolarisLoader
from ai.rag.loaders.tools.kubesec import KubeSecLoader
from ai.rag.loaders.tools.kube_score import KubeScoreLoader
from ai.rag.loaders.tools.checkov import CheckovLoader


PROMETHEUS_URL = "http://prom-kube-prometheus-stack-prometheus.monitoring:9090/api/v1/query"
PROXY = "socks5://localhost:9999"

# get href links from dashboards/index.html
urls = {}
with open("dashboards/index.html", "r") as f:
    soup = bs4.BeautifulSoup(f.read(), 'html.parser')
    rows = soup.find('tbody').find_all('tr')
    for row in rows:
        cols = row.find_all('td')
        if len(cols[3].find_all('a')) == 3:
            urls[cols[1].text] = {
                cols[3].find('a').text.strip(): cols[3].find('a')['href'],
                cols[3].find('a').find_next('a').text.strip(): cols[3].find('a').find_next('a')['href'],
                cols[3].find('a').find_next('a').find_next('a').text.strip(): cols[3].find('a').find_next('a').find_next('a')['href']
            }


async def load_documents(directory: str, vendor: str) -> None:
    await KorLoader(PROMETHEUS_URL, PROXY, "kubernetes_orphaned_resources").export(f"{directory}/kor.json")
    await TrivyLoader(PROMETHEUS_URL, PROXY, "trivy_image_vulnerabilities").export(f"{directory}/trivy.json")
    await PolarisLoader(urls["polaris"][vendor], PROXY).export(f"{directory}/polaris.json")
    await KubeSecLoader("dashboards/kubesec.html").export(f"{directory}/kubesec.json")
    await KubeScoreLoader("dashboards/kube-score.html").export(f"{directory}/kube-score.json")
    await CheckovLoader(f"dashboards/{urls["checkov"][vendor]}").export(f"{directory}/checkov.json")

