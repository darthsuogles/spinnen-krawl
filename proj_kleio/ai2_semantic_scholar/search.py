import requests
import json
import pandas as pd
import matplotlib.pyplot as plt

title = "Generalization in Deep Learning"

# Default setting
def get_article_info(title):
    request_data = {
        "queryString": title,
        "page": 1,
        "pageSize": 10,
        "sort": "relevance",
        "authors": [],
        "coAuthors": [],
        "venues": [],
        "facets": {},
        "yearFilter": None,
        "enableEntities": True,
        "enableRefinements": True,
        "requireViewablePdf": False,
        "publicationTypes": [],
        "disableFacetAggregations": True,
        "entities": [],
    }

    resp = requests.post("https://www.semanticscholar.org/api/1/search",
                         data=json.dumps(request_data),
                         headers={'Content-type': 'application/json'})
    return resp.json()


fetched_data = get_article_info(title)
print(fetched_data)
df_yearly_counts = pd.DataFrame(fetched_data['stats']['years']).set_index('key')
df_yearly_counts.plot(); plt.show()

# Get the first paginated results
df_results = pd.DataFrame(fetched_data['results'])

df_results['title'].apply(lambda rec: rec['text'])
