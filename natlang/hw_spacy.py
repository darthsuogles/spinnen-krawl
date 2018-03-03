"""
Using spaCy for natural language processing
"""

from pathlib import Path
import spacy
from spacy import displacy
from spacy.matcher import PhraseMatcher
from sklearn.manifold import TSNE
from sklearn.decomposition import LatentDirichletAllocation as LDA
import numpy as np
import pandas as pd
import scipy.sparse as sprs
import functools
from itertools import chain
from collections import Counter
import joblib as jl
import matplotlib.pyplot as plt

text = """\
We concur with European Directors regarding the importance of
continued focus on fiscal consolidation. We note the medium term targets
discussed in the buff statement, but are conscious of risks to future budget
deficit targets, and view options for further tax cutting or spending cuts as
becoming limited. What probability does the staff attach to the risk that the
budget deficit targets may not be met?
"""

def init_spacy(lang_model='en_core_web_lg'):
    from spacy.lang.en.stop_words import STOP_WORDS
    nlp = spacy.load(lang_model)
    # Missing stop words in a few models
    # https://github.com/explosion/spaCy/issues/922
    nlp.vocab.add_flag(
        lambda s: s.lower() in STOP_WORDS, spacy.attrs.IS_STOP)
    return nlp

# REF: https://spacy.io/usage/#section-troubleshooting
try: print(nlp.pipe_names)
# https://spacy.io/models/en#section-en_core_web_lg
# This model also contains GloVe vectors (embeded in a 300 dimesional vector space).
except: nlp = init_spacy()

# The default model gives us the basic tokenization and dependency parsing.
# REF: https://spacy.io/api/#section-nn-model
doc = nlp(text)

# TODO: add custom phase matching
def get_phrase_matcher(nlp, terminologies):
    # With the rich linguistic annotations, spaCy allows us to
    # match phrases in a very flexible manner.
    # https://spacy.io/usage/linguistic-features#section-rule-based-matching
    matcher = PhraseMatcher(nlp.vocab)
    _patterns = [nlp(phrase) for phrase in terminologies]
    matcher.add('TerminologyList', None, *_patterns)
    return matcher

# Get a matcher for a set of special phrases in our problem domain
matcher = get_phrase_matcher(nlp, [
    'European Directors',
    'IMF', 'International Monetary Funds',
    'European Union',
])

for _, init, bnd in matcher(doc):
    print(doc[init:bnd])

for i, sent in enumerate(doc.sents):
    print('sentence {}\t: {} [{}]'.format(i, sent, sent.sentiment))

for tok in sent:
    if tok.is_stop or tok.is_punct or tok.is_space: continue
    print(tok)

# displacy.serve(doc, style='dep')

# To find a summary on the corpus, LDA is a good idea.
# https://radimrehurek.com/gensim/models/ldamulticore.html

# We can also summarize the article via TensorFlow's TextSum
# https://github.com/tensorflow/models/tree/master/research/textsum

# Collect the word vectors and plot them
def plot_tsne(X):
    X_embedded = TSNE(n_components=2).fit_transform(X)
    fig, ax = plt.subplots()
    ax.scatter(X_embedded[:, 0], X_embedded[:, 1])
    fig.show()

# More dataset
fp_data_root = Path.home() / 'local' / 'data'
# TODO: load these datasets and inspect
fp_news_corpus = fp_data_root / 'econ_poly_corpus'

# REF: http://blog.kaggle.com/2015/07/27/crowdflower-winners-interview-1st-place-chenglong-chen/
# REF: https://www.kaggle.com/kaggle/hillary-clinton-emails
# REF: http://www.casmacat.eu/corpus/news-commentary.html
# REF: http://www.statmt.org/europarl/
# Must specify the encoding correctly!
df_us_econ_news = pd.read_csv(
    fp_news_corpus / 'Full-Economic-News-DFE-839861.csv',
    encoding="latin")
    #encoding="iso-8859-1")

# Tokenize the text and get a great deal of info
docs = list(nlp.pipe(iter(df_us_econ_news.text), batch_size=50, n_threads=3))

def skip_tok(tok):
    """ Create a vocabulary by cutting top words """
    return tok.is_punct or tok.is_stop or tok.pos_ == 'DET'

words_filtered = chain.from_iterable(map(
    lambda doc: [tok.text.lower() for tok in doc
                 if not skip_tok(tok)], docs))
words_count = Counter(words_filtered)

def build_vocab(uniq_toks):
    idx2tok = dict(enumerate(uniq_toks))
    tok2idx = dict([(v, k) for k, v in idx2tok.items()])
    return tok2idx, idx2tok

words_tok2idx, words_idx2tok = build_vocab([w for w, cnt in words_count.items() if cnt > 1])

""" Create doc/word feature matrix
"""
# Build the COO sparse matrix
coo_rows = []
coo_cols = []
coo_data = []

for i, doc in enumerate(docs):
    toks = [w.text.lower() for w in doc if not skip_tok(w)]
    tok_cntr = Counter(toks)
    for tok, cnt in tok_cntr.items():
        try: j = words_tok2idx[tok]
        except: continue
        coo_rows.append(i)
        coo_cols.append(j)
        coo_data.append(cnt)

X = sprs.coo_matrix((coo_data, (coo_rows, coo_cols)),
                    shape=(len(docs), len(words_tok2idx)))

""" Load an existing LDA model or retrain one """
try:
    lda = jl.load('lda.model.jl')
except:
    # This takes a while to build
    lda = LDA(n_topics=30,
              learning_method='batch',
              max_iter=2000,
              verbose=2,
              n_jobs=-2)
    lda.fit(X)
    jl.dump(lda, 'lda.model.jl')

# Obtain a summary of each "topic"
n_top_words = 10
topic_top_words = []
print('Learned Topics')
for tpc_idx, tpc in enumerate(lda.components_):
    print("Topic #%d:" % tpc_idx)
    tok_inds = tpc.argsort()[:(-n_top_words - 1):-1]
    _top_words = [words_idx2tok[idx] for idx in tok_inds]
    topic_top_words.append(_top_words)
    print(' '.join(_top_words))

# Get the actual topics for each documents
V = lda.transform(X)
doc_top_topics = V.argsort(axis=1)[:,:-4:-1]
_ser = {'doc_top_topics': doc_top_topics,
        'topic_top_words': topic_top_words}
jl.dump(_ser, 'lda.decomp.jl')


if False:
    """ Other methods """
    # TODO: check why elpy is so slow
    X_orig_ = []
    corpus_inds = []
    corpus = {}
    for el in df_us_econ_news.itertuples():
        doc_idx = el.articleid
        doc = nlp(el.text)
        for sent_idx, sent in enumerate(doc.sents):
            idx = (doc_idx, sent_idx)
            corpus[idx] = sent
            corpus_inds.append(idx)
            X_orig_.append(sent.vector)

    # Build the t-SNE 2D vectors
    X_w2v = np.vstack(X_orig_); del X_orig_

    # This may take a little while
    X_embedded = TSNE(n_components=2).fit_transform(X_w2v)

    # _raw_export = []
    # for vec2, idx in zip(X_embedded, corpus_inds):
    #     _raw_export.append({'x': vec2[0],
    #                         'y': vec2[1],
    #                         'text': corpus[idx].text})

    # df_export = pd.DataFrame(_raw_export)
    # df_export.to_csv('docs_tsne2d.csv')
